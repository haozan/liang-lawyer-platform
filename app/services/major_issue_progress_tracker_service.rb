class MajorIssueProgressTrackerService < ApplicationService
  def initialize
  end

  def call
    # 更新所有未解决的重大事项的处理天数
    MajorIssue.where(status: ['pending', 'discussing']).find_each do |issue|
      issue.update_processing_days!
    end
    
    # 查找逾期的重大事项并发送提醒
    overdue_issues = MajorIssue.where(status: ['pending', 'discussing'])
                                .where('processing_days > ?', 7)
    
    overdue_issues.find_each do |issue|
      send_overdue_reminder(issue)
    end
    
    # 查找待律师答复的重大事项（超过3天）
    pending_review_issues = MajorIssue.pending_lawyer_review
                                      .where('created_at < ?', 3.days.ago)
    
    pending_review_issues.find_each do |issue|
      send_review_reminder(issue)
    end
  end
  
  private
  
  def send_overdue_reminder(issue)
    # 通知关注此事项的所有用户
    issue.followers.notify_on_status.each do |follower|
      # TODO: 发送邮件或站内消息
      Rails.logger.info "Overdue reminder for MajorIssue ##{issue.id} to #{follower.user_type} ##{follower.user_id}"
    end
  end
  
  def send_review_reminder(issue)
    # 通知律师团队
    if issue.mentioned_lawyer
      # TODO: 发送提醒给指定律师
      Rails.logger.info "Review reminder for MajorIssue ##{issue.id} to Lawyer ##{issue.mentioned_lawyer.id}"
    else
      # TODO: 发送提醒给所有律师
      Rails.logger.info "Review reminder for MajorIssue ##{issue.id} to all lawyers"
    end
  end
end
