Rails.application.configure do
  config.good_job.tap do |good_job|
    # Enable cron functionality
    good_job.enable_cron = true
    
    # Configure cron schedule
    good_job.cron = {
      # 每天凌晨2点更新重大事项进度并发送提醒
      major_issue_progress_tracker: {
        cron: '0 2 * * *',
        class: 'MajorIssueProgressTrackerJob',
        description: 'Update major issue processing days and send overdue reminders'
      },
      
      # 每天凌晨3点清理过期的团队授权和个人授权
      expired_permission_cleanup: {
        cron: '0 3 * * *',
        class: 'ExpiredPermissionCleanupJob',
        description: 'Clean up expired team ownerships and lawyer business accesses'
      }
    }
  end
end
