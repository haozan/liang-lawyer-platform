# frozen_string_literal: true

# DisplayLabels — 提供通用的标签查询辅助方法
#
# 使用方式：
#   1. 在模型中 `include DisplayLabels`
#   2. 定义映射常量（推荐命名：STATUS_LABELS、PRIORITY_LABELS）
#   3. 调用 `display_label(:field_name, MAPPING_CONSTANT)` 或用 Symbol 方式引用
#
# 示例：
#   class Case < ApplicationRecord
#     include DisplayLabels
#
#     STATUS_LABELS = {
#       'preparing' => '准备立案',
#       'filed'     => '已立案待审',
#     }.freeze
#
#     def status_display = display_label(:status, STATUS_LABELS)
#   end
#
module DisplayLabels
  extend ActiveSupport::Concern

  # 通用标签查找：从给定 mapping 中取 field 的中文名，取不到则原值返回
  #
  # @param field [Symbol, String] 模型属性名
  # @param mapping [Hash] 值→中文名的映射表
  # @return [String, nil]
  def display_label(field, mapping)
    value = public_send(field)
    return nil if value.blank?

    mapping[value] || value
  end
end
