class CaseNotificationService < ApplicationService
  def initialize(case_record, notification_type, recipients, options = {})
    @case = case_record
    @notification_type = notification_type
    @recipients = Array(recipients)
    @options = options
  end
  
  def call
    @recipients.each do |recipient|
      create_notification(recipient)
    end
  end
  
  private
  
  def create_notification(recipient)
    CaseNotification.create!(
      case: @case,
      recipient: recipient,
      notification_type: @notification_type,
      title: notification_title,
      content: notification_content,
      metadata: @options[:metadata] || {},
      sent_at: Time.current
    )
  end
  
  def notification_title
    case @notification_type
    when 'hearing_reminder'
      "开庭提醒：#{@case.name}"
    when 'appeal_deadline_reminder'
      "上诉期限提醒：#{@case.name}"
    when 'status_changed'
      "案件状态变更：#{@case.name}"
    when 'team_member_added'
      "您已加入案件团队：#{@case.name}"
    when 'new_work_log'
      "案件新增工作记录：#{@case.name}"
    when 'new_comment'
      "案件新增评论：#{@case.name}"
    when 'new_question'
      "案件新增问题：#{@case.name}"
    when 'question_answered'
      "您的问题已得到律师回复：#{@case.name}"
    else
      "案件通知：#{@case.name}"
    end
  end
  
  def notification_content
    @options[:content] || "案件《#{@case.name}》有新的动态"
  end
end
