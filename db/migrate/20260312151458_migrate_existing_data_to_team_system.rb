# frozen_string_literal: true

class MigrateExistingDataToTeamSystem < ActiveRecord::Migration[7.2]
  def up
    # 检查必要的模型是否存在（处理模型文件未提交至仓库的情况）
    # 对于全新数据库，这些表都为空，迁移本质上不需要执行任何操作
    unless defined?(LawyerTeam)
      puts "⏭️  跳过团队系统数据迁移：LawyerTeam 模型未定义"
      return
    end

    # 第一步：确保所有律师都有团队归属
    # 如果现有律师没有团队，为他们创建默认团队
    migrate_lawyers_to_teams
    
    # 第二步：为现有业务记录创建团队归属关系
    migrate_business_records_to_team_ownership
    
    puts "✅ 团队系统数据迁移完成"
    puts "  - 已为 #{LawyerAccount.count} 位律师分配团队"
    puts "  - 已为 #{Contract.count} 个合同创建团队归属"
    puts "  - 已为 #{Case.count} 个案件创建团队归属"
    puts "  - 已为 #{MajorIssue.count} 个重大事项创建团队归属"
  end
  
  def down
    # 回滚时清除所有团队归属记录（保留团队和律师团队关系）
    puts "⚠️  回滚团队归属记录..."
    BusinessTeamOwnership.destroy_all
    puts "✅ 回滚完成"
  end
  
  private
  
  # 为律师创建团队归属
  def migrate_lawyers_to_teams
    # 创建一个默认团队（如果不存在）
    default_team = LawyerTeam.find_or_create_by!(code: 'DEFAULT_TEAM') do |team|
      team.name = '默认律师团队'
      team.data_isolation_level = 'flexible'
      team.status = 'active'
    end
    
    puts "  创建默认团队: #{default_team.name}"
    
    # 将所有没有团队的律师分配到默认团队
    lawyers_without_team = LawyerAccount.where(lawyer_team_id: nil)
    
    if lawyers_without_team.any?
      lawyers_without_team.update_all(lawyer_team_id: default_team.id)
      puts "  ✅ 已将 #{lawyers_without_team.count} 位律师分配到默认团队"
    else
      puts "  ℹ️  所有律师都已有团队归属"
    end
    
    # 如果默认团队没有负责人，指定第一位律师为负责人
    if default_team.leader_id.nil? && default_team.lawyer_accounts.any?
      first_lawyer = default_team.lawyer_accounts.first
      default_team.update!(leader_id: first_lawyer.id)
      
      # 将该律师的角色升级为 team_leader（如果不是 super_admin）
      if first_lawyer.role != 'super_admin'
        first_lawyer.update!(role: 'team_leader')
      end
      
      puts "  ✅ 指定 #{first_lawyer.name} 为默认团队负责人"
    end
  end
  
  # 为现有业务记录创建团队归属关系
  def migrate_business_records_to_team_ownership
    # 获取默认团队
    default_team = LawyerTeam.find_by(code: 'DEFAULT_TEAM')
    
    return unless default_team
    
    # 迁移合同
    migrate_contracts_ownership(default_team)
    
    # 迁移案件
    migrate_cases_ownership(default_team)
    
    # 迁移重大事项
    migrate_major_issues_ownership(default_team)
  end
  
  # 迁移合同的团队归属
  def migrate_contracts_ownership(default_team)
    Contract.find_each do |contract|
      # 跳过已有团队归属的合同
      next if BusinessTeamOwnership.exists?(
        business_type: 'Contract',
        business_id: contract.id
      )
      
      # 创建团队归属记录
      BusinessTeamOwnership.create!(
        business_type: 'Contract',
        business_id: contract.id,
        lawyer_team_id: default_team.id,
        company_id: contract.company_id,
        is_primary: true,
        access_level: 'owner',
        authorized_by_id: default_team.leader_id,
        authorized_at: Time.current
      )
    end
    
    puts "  ✅ 已为 #{Contract.count} 个合同创建团队归属"
  end
  
  # 迁移案件的团队归属
  def migrate_cases_ownership(default_team)
    Case.find_each do |case_record|
      # 跳过已有团队归属的案件
      next if BusinessTeamOwnership.exists?(
        business_type: 'Case',
        business_id: case_record.id
      )
      
      # 创建团队归属记录
      BusinessTeamOwnership.create!(
        business_type: 'Case',
        business_id: case_record.id,
        lawyer_team_id: default_team.id,
        company_id: case_record.company_id,
        is_primary: true,
        access_level: 'owner',
        authorized_by_id: default_team.leader_id,
        authorized_at: Time.current
      )
    end
    
    puts "  ✅ 已为 #{Case.count} 个案件创建团队归属"
  end
  
  # 迁移重大事项的团队归属
  def migrate_major_issues_ownership(default_team)
    MajorIssue.find_each do |major_issue|
      # 跳过已有团队归属的重大事项
      next if BusinessTeamOwnership.exists?(
        business_type: 'MajorIssue',
        business_id: major_issue.id
      )
      
      # 创建团队归属记录
      BusinessTeamOwnership.create!(
        business_type: 'MajorIssue',
        business_id: major_issue.id,
        lawyer_team_id: default_team.id,
        company_id: major_issue.company_id,
        is_primary: true,
        access_level: 'owner',
        authorized_by_id: default_team.leader_id,
        authorized_at: Time.current
      )
    end
    
    puts "  ✅ 已为 #{MajorIssue.count} 个重大事项创建团队归属"
  end
end
