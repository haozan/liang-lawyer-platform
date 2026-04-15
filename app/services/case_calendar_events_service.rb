# frozen_string_literal: true

# CaseCalendarEventsService
# 将案件列表转换为日历事件集合
#
# 使用方式:
#   events = CaseCalendarEventsService.new(cases: @cases, event_types: @event_types).call
#
# 返回按日期排序的事件数组，每个元素包含：
#   - date: 事件日期
#   - type: 事件类型（中文）
#   - case: Case 对象
#   - label: 显示标签
#   - color: 颜色标识（info/success/warning/danger/neutral）
#   - icon: 图标名称

class CaseCalendarEventsService < ApplicationService
  attr_reader :cases, :event_types

  def initialize(cases:, event_types:)
    @cases = cases
    @event_types = Array(event_types)
  end

  def call
    events = []

    cases.each do |kase|
      events.concat(filing_event(kase))
      events.concat(hearing_event(kase))
      events.concat(judgement_event(kase))
      events.concat(archived_event(kase))
      events.concat(property_preservation_event(kase))
      events.concat(execution_event(kase))
    end

    events.sort_by { |e| e[:date] }
  end

  private

  def filing_event(kase)
    return [] unless event_types.include?('立案日期') && kase.filing_at.present?

    [{
      date: kase.filing_at,
      type: '立案日期',
      case: kase,
      label: "立案：#{kase.name}",
      color: 'info',
      icon: 'file-text'
    }]
  end

  def hearing_event(kase)
    return [] unless event_types.include?('开庭时间') && kase.hearing_at.present?

    color = if kase.hearing_at < Time.current
              'success'  # 已开庭
            elsif kase.hearing_at < 7.days.from_now
              'danger'   # 7天内开庭
            elsif kase.hearing_at < 15.days.from_now
              'warning'  # 15天内开庭
            else
              'info'
            end

    [{
      date: kase.hearing_at,
      type: '开庭时间',
      case: kase,
      label: "开庭：#{kase.name}",
      color: color,
      icon: 'gavel'
    }]
  end

  def judgement_event(kase)
    return [] unless event_types.include?('判决领取') && kase.judgement_received_at.present?

    [{
      date: kase.judgement_received_at,
      type: '判决领取',
      case: kase,
      label: "判决：#{kase.name}",
      color: 'success',
      icon: 'file-check'
    }]
  end

  def archived_event(kase)
    return [] unless event_types.include?('归档日期') && kase.archived_at.present?

    [{
      date: kase.archived_at,
      type: '归档日期',
      case: kase,
      label: "归档：#{kase.name}",
      color: 'neutral',
      icon: 'archive'
    }]
  end

  def property_preservation_event(kase)
    return [] unless event_types.include?('保全到期') && kase.property_preservation_deadline.present?

    color = if kase.property_preservation_deadline < Date.today
              'danger'   # 已过期
            elsif kase.property_preservation_deadline < 7.days.from_now.to_date
              'warning'  # 即将到期
            else
              'info'
            end

    [{
      date: kase.property_preservation_deadline,
      type: '保全到期',
      case: kase,
      label: "保全到期：#{kase.name}",
      color: color,
      icon: 'shield-alert'
    }]
  end

  def execution_event(kase)
    return [] unless event_types.include?('执行到期') && kase.estimated_end_date.present?

    color = if kase.estimated_end_date < Date.today
              'danger'
            elsif kase.estimated_end_date < 30.days.from_now.to_date
              'warning'
            else
              'info'
            end

    [{
      date: kase.estimated_end_date,
      type: '执行到期',
      case: kase,
      label: "执行期限：#{kase.name}",
      color: color,
      icon: 'clock'
    }]
  end
end
