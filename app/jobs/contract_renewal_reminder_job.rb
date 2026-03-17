class ContractRenewalReminderJob < ApplicationJob
  queue_as :default

  def perform
    # 查找所有需要续签提醒的合同
    contracts_needing_renewal = Contract
      .active
      .where(auto_renewal: true)
      .where.not(renewal_notice_period: nil)
      .where.not(end_at: nil)
      .select(&:needs_renewal_notice?)
    
    # 为每个合同生成或更新续签提醒公告
    contracts_needing_renewal.each do |contract|
      existing_announcement = Announcement
        .active
        .where(
          announcement_type: 'contract_renewal_reminder',
          company_id: contract.company_id,
          related: contract
        )
        .first
      
      if existing_announcement
        # 更新现有公告
        existing_announcement.update(
          expires_at: contract.end_at + 7.days,
          content: generate_renewal_content(contract)
        )
      else
        # 创建新公告
        Announcement.create!(
          company_id: contract.company_id,
          announcement_type: 'contract_renewal_reminder',
          priority: 'important',
          title: "合同即将到期：#{contract.name}",
          content: generate_renewal_content(contract),
          related: contract,
          created_by: nil,
          published_at: Time.current,
          expires_at: contract.end_at + 7.days
        )
      end
    end
    
    # 清理已过期或不再需要提醒的公告
    cleanup_outdated_renewal_announcements
  end
  
  private
  
  def generate_renewal_content(contract)
    days_until_expiry = (contract.end_at - Date.today).to_i
    renewal_intention_text = case contract.renewal_intention
                             when '续约' then '✅ 已确认续约'
                             when '不续约' then '❌ 已确认不续约'
                             when '待定' then '⏳ 续约意向待定'
                             else '❓ 续约意向未填写'
                             end
    
    <<~CONTENT
      合同「#{contract.name}」将在 #{days_until_expiry} 天后到期（#{contract.end_at.strftime('%Y年%m月%d日')}）。
      
      📋 合同信息：
      - 对方名称：#{contract.counterparty_name}
      - 合同金额：#{contract.contract_amount ? "#{contract.contract_amount} #{contract.currency || '元'}" : '未填写'}
      - 签订日期：#{contract.signed_at.strftime('%Y年%m月%d日')}
      - 到期日期：#{contract.end_at.strftime('%Y年%m月%d日')}
      - 续约意向：#{renewal_intention_text}
      
      #{contract.renewal_intention == '续约' ? '💡 可使用「一键续签」功能快速创建新合同。' : ''}
      
      请及时确认续约意向，避免影响业务连续性。
    CONTENT
  end
  
  def cleanup_outdated_renewal_announcements
    # 清理合同已到期或不再需要提醒的公告
    Announcement
      .active
      .where(announcement_type: 'contract_renewal_reminder')
      .where.not(related_id: nil)
      .find_each do |announcement|
        contract = announcement.related
        next unless contract.is_a?(Contract)
        
        # 如果合同不再需要续签提醒（已到期、已完成、已取消自动续签等），使公告过期
        unless contract.status == 'active' && contract.auto_renewal && contract.needs_renewal_notice?
          announcement.update(expires_at: Time.current - 1.minute)
        end
      end
  end
end
