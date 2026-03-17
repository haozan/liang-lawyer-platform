class MajorIssueProgressTrackerJob < ApplicationJob
  queue_as :default
  
  # 每天凌晨2点执行（使用GoodJob的cron功能）
  # 在config/initializers/good_job.rb中配置：
  # config.cron = { major_issue_progress_tracker: { cron: '0 2 * * *', class: 'MajorIssueProgressTrackerJob' } }
  
  def perform
    MajorIssueProgressTrackerService.call
  end
end
