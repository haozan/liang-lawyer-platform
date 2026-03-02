# frozen_string_literal: true

class LawyerExpiryService < ApplicationService
  def initialize(company_id: nil)
    @company_id = company_id
  end

  def call
    {
      expiring_contracts: expiring_contracts,
      upcoming_hearings: upcoming_hearings,
      pending_judgement_collections: pending_judgement_collections,
      pending_archives: pending_archives,
      expiring_companies: expiring_companies,
      total_count: total_expiry_count
    }
  end

  private

  # 合同到期提醒（7/15/30天分级）
  def expiring_contracts
    items = []
    
    # 7天内到期 - 紧急
    contracts_scope.where(status: 'active')
                   .where('end_at BETWEEN ? AND ?', Date.today, 7.days.from_now.to_date)
                   .each do |contract|
      days_left = days_until(contract.end_at)
      items << {
        type: :contract,
        urgency: :critical, # 🔴
        record: contract,
        company: contract.company,
        message: "合同《#{contract.name}》",
        days_left: days_left,
        due_date: contract.end_at,
        link: contract_path_with_company(contract)
      }
    end
    
    # 8-15天内到期 - 警告
    contracts_scope.where(status: 'active')
                   .where('end_at BETWEEN ? AND ?', 8.days.from_now.to_date, 15.days.from_now.to_date)
                   .each do |contract|
      days_left = days_until(contract.end_at)
      items << {
        type: :contract,
        urgency: :warning, # 🟠
        record: contract,
        company: contract.company,
        message: "合同《#{contract.name}》",
        days_left: days_left,
        due_date: contract.end_at,
        link: contract_path_with_company(contract)
      }
    end
    
    # 16-30天内到期 - 注意
    contracts_scope.where(status: 'active')
                   .where('end_at BETWEEN ? AND ?', 16.days.from_now.to_date, 30.days.from_now.to_date)
                   .each do |contract|
      days_left = days_until(contract.end_at)
      items << {
        type: :contract,
        urgency: :notice, # 🟡
        record: contract,
        company: contract.company,
        message: "合同《#{contract.name}》",
        days_left: days_left,
        due_date: contract.end_at,
        link: contract_path_with_company(contract)
      }
    end
    
    items.sort_by { |item| item[:due_date] }
  end

  # 庭审提醒（3/7天分级）
  def upcoming_hearings
    items = []
    
    # 3天内开庭 - 紧急
    cases_scope.where('hearing_at IS NOT NULL')
               .where('hearing_at BETWEEN ? AND ?', Time.current, 3.days.from_now)
               .each do |kase|
      days_left = days_until(kase.hearing_at.to_date)
      items << {
        type: :hearing,
        urgency: :critical, # 🔴
        record: kase,
        company: kase.company,
        message: "案件《#{kase.name}》即将开庭",
        days_left: days_left,
        due_date: kase.hearing_at.to_date,
        due_time: kase.hearing_at.strftime('%H:%M'),
        link: case_path_with_company(kase)
      }
    end
    
    # 4-7天内开庭 - 提前准备
    cases_scope.where('hearing_at IS NOT NULL')
               .where('hearing_at BETWEEN ? AND ?', 3.days.from_now, 7.days.from_now)
               .each do |kase|
      days_left = days_until(kase.hearing_at.to_date)
      items << {
        type: :hearing,
        urgency: :warning, # 🟠
        record: kase,
        company: kase.company,
        message: "案件《#{kase.name}》即将开庭",
        days_left: days_left,
        due_date: kase.hearing_at.to_date,
        due_time: kase.hearing_at.strftime('%H:%M'),
        link: case_path_with_company(kase)
      }
    end
    
    items.sort_by { |item| item[:due_date] }
  end

  # 判决书领取提醒
  # 注意：schema中只有judgement_received_at字段（判决书实际领取日期）
  # 状态为judgement且未填写judgement_received_at的案件视为待领取
  def pending_judgement_collections
    items = []
    
    cases_scope.where(status: 'judgement')
                .where(judgement_received_at: nil)
                .each do |kase|
      items << {
        type: :judgement,
        urgency: :notice, # 🟡
        record: kase,
        company: kase.company,
        message: "案件《#{kase.name}》判决书待领取",
        link: case_path_with_company(kase)
      }
    end
    
    items
  end

  # 归档提醒（已领取判决书超过30天未归档）
  # 注意：使用judgement_received_at（判决书领取日期）作为参考
  # 如果判决书已领取超过30天但未归档，则提醒归档
  def pending_archives
    items = []
    
    cases_scope.where(status: 'judgement')
                .where(archived_at: nil)
                .where('judgement_received_at IS NOT NULL')
                .where('judgement_received_at < ?', 30.days.ago)
                .each do |kase|
      pending_days = (Date.today - kase.judgement_received_at).to_i
      items << {
        type: :archive,
        urgency: :notice, # 🟡
        record: kase,
        company: kase.company,
        message: "案件《#{kase.name}》已领取判决书#{pending_days}天，待归档",
        pending_days: pending_days,
        received_date: kase.judgement_received_at,
        link: case_path_with_company(kase)
      }
    end
    
    items.sort_by { |item| item[:received_date] }
  end
  
  # 企业服务到期提醒（7/15/30天分级）
  def expiring_companies
    items = []
    
    # 7天内到期 - 紧急
    Company.active.expires_soon(7).each do |company|
      days_left = days_until(company.service_expires_at)
      items << {
        type: :company_service,
        urgency: :critical, # 🔴
        record: company,
        company: company,
        message: "企业《#{company.name}》服务即将到期",
        days_left: days_left,
        due_date: company.service_expires_at,
        link: Rails.application.routes.url_helpers.edit_lawyer_company_path(company)
      }
    end
    
    # 8-15天内到期 - 警告
    Company.active
           .where('service_expires_at BETWEEN ? AND ?', 8.days.from_now.to_date, 15.days.from_now.to_date)
           .each do |company|
      days_left = days_until(company.service_expires_at)
      items << {
        type: :company_service,
        urgency: :warning, # 🟠
        record: company,
        company: company,
        message: "企业《#{company.name}》服务即将到期",
        days_left: days_left,
        due_date: company.service_expires_at,
        link: Rails.application.routes.url_helpers.edit_lawyer_company_path(company)
      }
    end
    
    # 16-30天内到期 - 注意
    Company.active
           .where('service_expires_at BETWEEN ? AND ?', 16.days.from_now.to_date, 30.days.from_now.to_date)
           .each do |company|
      days_left = days_until(company.service_expires_at)
      items << {
        type: :company_service,
        urgency: :notice, # 🟡
        record: company,
        company: company,
        message: "企业《#{company.name}》服务即将到期",
        days_left: days_left,
        due_date: company.service_expires_at,
        link: Rails.application.routes.url_helpers.edit_lawyer_company_path(company)
      }
    end
    
    items.sort_by { |item| item[:due_date] }
  end

  def total_expiry_count
    expiring_contracts.count + 
    upcoming_hearings.count + 
    pending_judgement_collections.count + 
    pending_archives.count +
    expiring_companies.count
  end

  def contracts_scope
    @company_id ? Contract.where(company_id: @company_id) : Contract.all
  end

  def cases_scope
    scope = @company_id ? Case.where(company_id: @company_id) : Case.all
    scope.where(deleted_at: nil)
  end

  def days_until(date)
    (date - Date.today).to_i
  end

  # Helper methods for generating paths with company enter action
  def contract_path_with_company(contract)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      contract.company,
      redirect_to: Rails.application.routes.url_helpers.contract_path(contract)
    )
  end

  def case_path_with_company(kase)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      kase.company,
      redirect_to: Rails.application.routes.url_helpers.case_path(kase)
    )
  end
end
