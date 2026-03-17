class MigrateExistingCompaniesToTeamSystem < ActiveRecord::Migration[7.2]
  def up
    # 统计现有企业数量
    total_companies = Company.where(lawyer_team_id: nil).count
    puts "发现 #{total_companies} 个企业尚未分配团队"
    
    if total_companies == 0
      puts "所有企业已分配团队，无需迁移"
      return
    end
    
    # 优先使用当前活跃的律师团队
    active_team = LawyerTeam.where(status: 'active')
                           .where.not(code: 'DEFAULT_TEAM')
                           .order(created_at: :asc)
                           .first
    
    # 如果没有其他活跃团队，则使用 DEFAULT_TEAM
    if active_team.nil?
      puts "警告：系统中不存在其他活跃团队，使用 DEFAULT_TEAM..."
      active_team = LawyerTeam.find_by(code: 'DEFAULT_TEAM')
      
      if active_team.nil?
        puts "创建 DEFAULT_TEAM..."
        active_team = LawyerTeam.create!(
          code: 'DEFAULT_TEAM',
          name: '默认律师团队',
          status: 'active',
          data_isolation_level: 'flexible'
        )
        puts "DEFAULT_TEAM 创建成功（ID: #{active_team.id}）"
      end
    end
    
    puts "将企业分配到团队：#{active_team.name}（ID: #{active_team.id}）"
    
    # 为所有未分配团队的企业分配团队
    updated_count = Company.where(lawyer_team_id: nil).update_all(lawyer_team_id: active_team.id)
    
    puts "成功为 #{updated_count} 个企业分配团队（#{active_team.name}）"
    
    # 验证迁移结果
    remaining = Company.where(lawyer_team_id: nil).count
    if remaining > 0
      puts "警告：仍有 #{remaining} 个企业未分配团队"
    else
      puts "✅ 所有企业已成功分配团队"
    end
  end
  
  def down
    # 回滚操作：将所有企业的团队归属清空
    Company.update_all(lawyer_team_id: nil)
    puts "已清空所有企业的团队归属"
  end
end
