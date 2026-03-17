# frozen_string_literal: true

# Current - ActiveSupport::CurrentAttributes
# 用于在当前请求生命周期内存储线程安全的上下文数据
#
# 使用场景：
#   - 在控制器中设置: Current.lawyer_account = current_lawyer
#   - 在模型中访问: Current.lawyer_account
#   - 用于 TeamAccessible concern 的 after_create 回调
class Current < ActiveSupport::CurrentAttributes
  attribute :lawyer_account
end
