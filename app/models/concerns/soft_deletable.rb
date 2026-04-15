# frozen_string_literal: true

# SoftDeletable Concern
# 为业务模型（Case, MajorIssue 等）提供双重确认软删除功能
#
# 使用方式:
#   class Case < ApplicationRecord
#     include SoftDeletable
#   end
#
# 核心功能:
#   1. 员工申请删除（需要老板确认）
#   2. 老板直接删除
#   3. 删除状态查询
#
# 依赖字段（需在数据库中存在）:
#   - deleted_at: datetime（已删除时间戳）
#   - deleted_by_employee_id: integer（申请删除的员工ID）
#   - confirmed_by_boss_id: integer（确认删除的老板ID）
#   - deletion_requested_at: datetime（申请删除时间）

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # 通用 scope
    scope :not_deleted, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
    scope :pending_deletion, -> { where.not(deleted_by_employee_id: nil).where(deleted_at: nil) }
  end

  # 员工申请删除（需要老板确认）
  def request_deletion_by_employee(employee_user)
    update(deleted_by_employee_id: employee_user.id, deletion_requested_at: Time.current)
  end

  # 老板确认员工的删除申请
  def confirm_deletion_by_boss(boss_user)
    update(confirmed_by_boss_id: boss_user.id, deleted_at: Time.current)
  end

  # 老板直接删除（无需申请）
  def delete_by_boss(boss_user)
    update(
      deleted_by_employee_id: boss_user.id,
      confirmed_by_boss_id: boss_user.id,
      deleted_at: Time.current
    )
  end

  # 是否已删除
  def deleted?
    deleted_at.present?
  end

  # 是否待删除（员工已申请，等待老板确认）
  def pending_deletion?
    deleted_by_employee_id.present? && deleted_at.nil?
  end
end
