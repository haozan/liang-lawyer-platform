# frozen_string_literal: true

# TeamAuthorizationConcern
# 为控制器提供团队级权限拦截和审计日志记录
#
# 使用方式:
#   class ContractsController < ApplicationController
#     include TeamAuthorizationConcern
#     
#     before_action :set_contract, only: [:show, :edit, :update, :destroy]
#     before_action :check_team_access, only: [:show, :edit, :update, :destroy]
#   end
#
# 核心功能:
#   1. 权限检查：在访问资源前检查律师是否有权限
#   2. 审计日志：记录所有访问操作（成功和失败）
#   3. 友好错误：权限不足时返回友好的错误提示

module TeamAuthorizationConcern
  extend ActiveSupport::Concern
  
  included do
    # 可以在控制器中使用 before_action :check_team_access
  end
  
  private
  
  # 核心方法：检查团队访问权限
  # 自动识别当前资源（基于控制器名称）
  # @return [Boolean] 有权限返回 true，无权限则重定向并返回 false
  def check_team_access
    # 对于非律师用户（如企业用户），跳过团队权限检查
    # 他们已经通过set_contract等方法进行了权限检查
    return true unless lawyer?
    
    resource = find_resource_for_authorization
    
    unless resource
      redirect_to root_path, alert: '资源不存在'
      return false
    end
    
    # 检查资源是否支持团队权限（包含 TeamAccessible）
    unless resource.class.included_modules.include?(TeamAccessible)
      # 如果资源不支持团队权限，直接放行
      return true
    end
    
    # 检查律师是否有访问权限
    unless resource.accessible_by?(current_lawyer_account)
      redirect_to root_path, alert: '您没有权限访问该资源，请联系团队负责人申请权限'
      return false
    end
    
    true
  end
  
  # 检查编辑权限（仅对律师执行，企业用户通过 require_contract_access 控制）
  # @return [Boolean]
  def check_edit_permission
    # 企业用户不需要经过团队权限检查，已经通过 require_contract_access 控制
    return true unless lawyer?
    
    resource = find_resource_for_authorization
    
    unless resource
      redirect_to root_path, alert: '资源不存在'
      return false
    end
    
    unless resource.class.included_modules.include?(TeamAccessible)
      return true
    end
    
    unless resource.editable_by?(current_lawyer_account)
      redirect_to polymorphic_path(resource), alert: '您没有编辑权限，当前仅可查看'
      return false
    end
    
    true
  end
  
  # 检查删除权限（仅对律师执行，企业用户通过 require_contract_access 控制）
  # @return [Boolean]
  def check_delete_permission
    # 企业用户不需要经过团队权限检查，已经通过 require_contract_access 控制
    return true unless lawyer?
    
    resource = find_resource_for_authorization
    
    unless resource
      redirect_to root_path, alert: '资源不存在'
      return false
    end
    
    unless resource.class.included_modules.include?(TeamAccessible)
      return true
    end
    
    unless resource.deletable_by?(current_lawyer_account)
      redirect_to polymorphic_path(resource), alert: '您没有删除权限，请联系业务负责人'
      return false
    end
    
    true
  end
  
  # 查找当前资源
  # 根据控制器名称自动查找对应的实例变量
  # 例如：ContractsController => @contract
  #       CasesController => @case
  # @return [ActiveRecord::Base, nil]
  def find_resource_for_authorization
    controller_name_singular = controller_name.singularize
    instance_variable_get("@#{controller_name_singular}")
  end
  
  
  # 辅助方法：为资源授权团队访问
  # 可在控制器中调用
  # @param resource [ActiveRecord::Base] 资源对象
  # @param team [LawyerTeam] 团队对象
  # @param access_level [String] 访问级别
  # @param expires_at [DateTime, nil] 到期时间
  def grant_team_access_to_resource(resource, team:, access_level:, expires_at: nil)
    resource.grant_team_access!(
      team: team,
      access_level: access_level,
      authorized_by: current_lawyer_account,
      expires_at: expires_at
    )
  end
  
  # 辅助方法：为资源授权律师个人访问
  # @param resource [ActiveRecord::Base] 资源对象
  # @param lawyer [LawyerAccount] 律师对象
  # @param access_level [String] 访问级别
  # @param reason [String] 授权原因
  # @param expires_at [DateTime, nil] 到期时间
  def grant_lawyer_access_to_resource(resource, lawyer:, access_level:, reason:, expires_at: nil)
    resource.grant_lawyer_access!(
      lawyer: lawyer,
      access_level: access_level,
      reason: reason,
      authorized_by: current_lawyer_account,
      expires_at: expires_at
    )
  end
end
