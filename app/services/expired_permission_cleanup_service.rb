# 过期权限清理服务
# 用于清理已过期的团队授权和个人授权记录
class ExpiredPermissionCleanupService < ApplicationService

  # 清理过期的团队授权
  def cleanup_team_ownerships
    expired_ownerships = BusinessTeamOwnership
      .where('expires_at IS NOT NULL AND expires_at < ?', Time.current)
      .where.not(is_primary: true) # 不清理主团队授权
    
    count = expired_ownerships.count
    
    if count > 0
      Rails.logger.info "[ExpiredPermissionCleanup] 发现 #{count} 条过期的团队授权记录"
      
      expired_ownerships.find_each do |ownership|
        Rails.logger.info "[ExpiredPermissionCleanup] 删除过期授权: 业务类型=#{ownership.business_type}, " \
                          "业务ID=#{ownership.business_id}, 团队=#{ownership.lawyer_team&.name}, " \
                          "过期时间=#{ownership.expires_at}"
        ownership.destroy
      end
      
      Rails.logger.info "[ExpiredPermissionCleanup] 已清理 #{count} 条过期的团队授权"
    else
      Rails.logger.info "[ExpiredPermissionCleanup] 没有发现过期的团队授权"
    end
    
    count
  end
  
  # 清理过期的个人授权
  def cleanup_lawyer_accesses
    expired_accesses = LawyerBusinessAccess
      .where('expires_at IS NOT NULL AND expires_at < ?', Time.current)
    
    count = expired_accesses.count
    
    if count > 0
      Rails.logger.info "[ExpiredPermissionCleanup] 发现 #{count} 条过期的个人授权记录"
      
      expired_accesses.find_each do |access|
        Rails.logger.info "[ExpiredPermissionCleanup] 删除过期授权: 业务类型=#{access.business_type}, " \
                          "业务ID=#{access.business_id}, 律师=#{access.lawyer&.name}, " \
                          "过期时间=#{access.expires_at}"
        access.destroy
      end
      
      Rails.logger.info "[ExpiredPermissionCleanup] 已清理 #{count} 条过期的个人授权"
    else
      Rails.logger.info "[ExpiredPermissionCleanup] 没有发现过期的个人授权"
    end
    
    count
  end
  
  # 执行完整清理
  def call
    Rails.logger.info "[ExpiredPermissionCleanup] 开始清理过期权限..."
    
    team_count = cleanup_team_ownerships
    lawyer_count = cleanup_lawyer_accesses
    
    total_count = team_count + lawyer_count
    
    Rails.logger.info "[ExpiredPermissionCleanup] 清理完成: 共清理 #{total_count} 条过期权限 " \
                      "(团队授权: #{team_count}, 个人授权: #{lawyer_count})"
    
    success(
      message: "成功清理 #{total_count} 条过期权限",
      data: {
        team_ownerships_cleaned: team_count,
        lawyer_accesses_cleaned: lawyer_count,
        total_cleaned: total_count
      }
    )
  rescue => e
    Rails.logger.error "[ExpiredPermissionCleanup] 清理失败: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    failure(message: "清理失败: #{e.message}")
  end
end
