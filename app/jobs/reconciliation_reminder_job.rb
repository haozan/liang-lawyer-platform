class ReconciliationReminderJob < ApplicationJob
  queue_as :default

  # 检测需要上传对账单的合同，并生成提醒公告
  # 规则：
  # 1. 跨月合同 (cross_month?)
  # 2. 状态为 active
  # 3. 本月尚未上传对账单
  # 4. 生成公告提醒企业用户上传
  def perform
    current_period = Time.current.strftime('%Y-%m')
    
    # 查找需要提醒的合同
    contracts_needing_reconciliation = Contract
      .active
      .where('signed_at < ?', Time.current.beginning_of_month) # 确保是跨月合同
      .where('signed_at != ?', Time.current.beginning_of_month.to_date) # 排除本月刚签订的
      .select { |c| c.cross_month? && !c.reconciliation_uploaded_this_month? }
    
    # 为每个合同生成或更新公告
    contracts_needing_reconciliation.each do |contract|
      # 检查是否已有未过期的对账单提醒公告
      existing_announcement = Announcement
        .active
        .where(
          announcement_type: 'reconciliation_overdue',
          company_id: contract.company_id,
          related: contract
        )
        .first
      
      # 如果已存在公告，更新过期时间
      if existing_announcement
        existing_announcement.update(
          expires_at: Time.current.end_of_month,
          content: generate_reminder_content(contract, current_period)
        )
      else
        # 创建新公告
        Announcement.create!(
          company_id: contract.company_id,
          announcement_type: 'reconciliation_overdue',
          priority: 'important',
          title: "待上传对账单：#{contract.name}",
          content: generate_reminder_content(contract, current_period),
          related: contract,
          created_by: nil, # 系统自动生成
          published_at: Time.current,
          expires_at: Time.current.end_of_month # 本月月底过期
        )
      end
    end
    
    # 清理已上传对账单的过期公告
    cleanup_outdated_announcements
  end
  
  private
  
  def generate_reminder_content(contract, period)
    year, month = period.split('-')
    <<~CONTENT
      合同「#{contract.name}」需要上传 #{year}年#{month}月 的对账单。
      
      - 对方名称：#{contract.counterparty_name}
      - 合同金额：#{contract.contract_amount ? "#{contract.contract_amount} #{contract.currency || '元'}" : '未填写'}
      - 签订日期：#{contract.signed_at&.strftime('%Y年%m月%d日')}
      - 到期日期：#{contract.end_at&.strftime('%Y年%m月%d日')}
      
      请及时上传对账单，以便律师审查和跟踪合同履行情况。
    CONTENT
  end
  
  def cleanup_outdated_announcements
    # 找出已上传对账单的合同对应的公告，标记为过期
    Announcement
      .active
      .where(announcement_type: 'reconciliation_overdue')
      .where.not(related_id: nil)
      .find_each do |announcement|
        contract = announcement.related
        next unless contract.is_a?(Contract)
        
        # 如果本月已上传对账单，标记公告为过期
        if contract.reconciliation_uploaded_this_month?
          announcement.update(expires_at: Time.current - 1.minute)
        end
      end
  end
end
