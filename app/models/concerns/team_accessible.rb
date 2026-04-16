# frozen_string_literal: true

# TeamAccessible Concern（简化版）
# 原来有三层团队权限体系，现在只有一个团队，所有律师可访问全部数据。
# accessible_by(lawyer) 直接返回 all，保留接口兼容旧代码调用。

module TeamAccessible
  extend ActiveSupport::Concern

  included do
    # 保留空关联防止旧 includes 报错（实际表已删除）
  end

  class_methods do
    # 所有律师可访问全部业务数据，直接返回 all
    def accessible_by(_lawyer)
      all
    end

    # 兼容旧调用，返回全部
    def owned_by_team(_team_id)
      all
    end

    def collaborated_by_team(_team_id)
      none
    end

    def unassigned
      none
    end
  end

  # 实例方法：所有律师都可访问
  def accessible_by?(lawyer)
    lawyer.present?
  end

  # 所有律师都可编辑
  def editable_by?(lawyer)
    lawyer.present?
  end

  # 所有律师都可删除
  def deletable_by?(lawyer)
    lawyer.present?
  end

  def access_level_for(_lawyer)
    'owner'
  end

  def primary_team
    nil
  end

  def create_team_ownership
    # no-op：团队系统已移除
  end
end
