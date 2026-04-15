# frozen_string_literal: true

# CasePendingTasksService
# 计算案件的律师待办事项列表
#
# 使用方式:
#   tasks = CasePendingTasksService.new(case_record: @case).call
#
# 返回任务数组，每个元素包含：
#   - type: 任务类型 Symbol
#   - text: 显示文字
#   - anchor: 页面锚点（用于跳转）

class CasePendingTasksService < ApplicationService
  HEARING_UPCOMING_DAYS = 7
  APPEAL_DEADLINE_WARNING_DAYS = 15
  PROPERTY_PRESERVATION_WARNING_DAYS = 7
  RECENT_WORK_LOG_DAYS = 3

  attr_reader :case_record

  def initialize(case_record:)
    @case_record = case_record
  end

  def call
    tasks = []
    tasks.concat(hearing_upcoming_tasks)
    tasks.concat(appeal_deadline_tasks)
    tasks.concat(property_preservation_tasks)
    tasks.concat(unreviewed_work_log_tasks)
    tasks
  end

  private

  # 即将开庭提醒
  def hearing_upcoming_tasks
    return [] unless case_record.hearing_at.present?
    return [] unless case_record.hearing_at > Time.current
    return [] unless case_record.hearing_at < HEARING_UPCOMING_DAYS.days.from_now

    days_until = ((case_record.hearing_at - Time.current) / 1.day).ceil
    [{
      type: :hearing_upcoming,
      text: "#{days_until}天后开庭（#{case_record.hearing_at.strftime('%m月%d日 %H:%M')}）",
      anchor: '#progress'
    }]
  end

  # 上诉/再审期限临近提醒
  def appeal_deadline_tasks
    return [] unless case_record.show_appeal_deadline_reminder?

    days_left = case_record.days_until_effective_appeal_deadline
    return [] if days_left > APPEAL_DEADLINE_WARNING_DAYS

    [{
      type: :appeal_deadline,
      text: "#{case_record.appeal_deadline_type}仅剩#{days_left}天",
      anchor: '#progress'
    }]
  end

  # 财产保全到期提醒
  def property_preservation_tasks
    return [] unless case_record.property_preservation_deadline.present?

    days_left = case_record.property_preservation_days_left
    return [] unless days_left >= 0 && days_left <= PROPERTY_PRESERVATION_WARNING_DAYS

    [{
      type: :property_preservation_expiring,
      text: "财产保全将于#{days_left}天后到期",
      anchor: '#preservation'
    }]
  end

  # 未审查的工作记录（最近 N 天新增）
  def unreviewed_work_log_tasks
    recent_count = case_record.work_logs.where('created_at > ?', RECENT_WORK_LOG_DAYS.days.ago).count
    return [] if recent_count.zero?

    [{
      type: :unreviewed_work_logs,
      text: "有#{recent_count}条新工作记录待查看",
      anchor: '#work-logs'
    }]
  end
end
