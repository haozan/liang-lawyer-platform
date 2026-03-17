# 过期权限清理任务
# 定时清理过期的团队授权和个人授权记录
class ExpiredPermissionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    service = ExpiredPermissionCleanupService.new
    result = service.call
    
    if result.success?
      Rails.logger.info "[ExpiredPermissionCleanupJob] #{result.message}"
      Rails.logger.info "[ExpiredPermissionCleanupJob] 详情: #{result.data}"
    else
      Rails.logger.error "[ExpiredPermissionCleanupJob] 执行失败: #{result.message}"
    end
  end
end
