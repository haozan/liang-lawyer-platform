# frozen_string_literal: true

# CompanyResolvable Concern
# 为控制器提供统一的 set_company 方法，消除跨控制器的重复代码
#
# 使用方式:
#   class CasesController < ApplicationController
#     include CompanyResolvable
#     before_action :set_company
#   end
#
# 两种模式:
#   1. 标准模式（默认）：支持律师通过 session 切换企业 + 企业用户固定自己公司
#   2. 只读企业用户模式：仅用于企业用户视角（如 TodosController, WorkbenchController）

module CompanyResolvable
  extend ActiveSupport::Concern

  private

  # 通用 set_company：律师可通过 session/params 切换企业，企业用户固定自己公司
  # 适用于：CasesController, ContractsController, MajorIssuesController
  def set_company
    @company = if current_company_user
                 # 企业用户只能访问自己的公司数据，防止客户信息泄露
                 viewing_company
               elsif current_lawyer
                 resolve_company_for_lawyer
               end

    # 只有企业用户在未找到公司时才重定向
    if current_company_user && @company.nil?
      redirect_to root_path, alert: '未找到公司'
    end
  end

  # 仅适用于企业用户视角的控制器（set_company 简化版）
  # 适用于：TodosController, WorkbenchController, AnnouncementsController（纯企业用户）
  def set_company_for_company_user
    @company = viewing_company
  end

  # 分析类控制器的 set_company：支持律师筛选，但不维护 session
  # 适用于：CaseAnalyticsController, ContractAnalyticsController, MajorIssueAnalyticsController
  def set_company_for_analytics(redirect_path: nil)
    @company = if lawyer?
                 # 律师可以选择企业或查看全部
                 if params[:company_id].present? && params[:company_id] != 'all'
                   Company.find(params[:company_id])
                 end
               else
                 # 企业用户只能查看自己的企业
                 if params[:company_id].present? && params[:company_id].to_i != viewing_company&.id
                   target = redirect_path || root_path
                   redirect_to target, alert: '没有权限查看该企业数据'
                   return
                 end
                 viewing_company
               end

    @lawyer = params[:lawyer_id].present? ? LawyerAccount.find(params[:lawyer_id]) : nil
  end

  # 解析律师视角下的当前企业（维护 session）
  def resolve_company_for_lawyer
    if params[:company_id].present?
      if params[:company_id] == 'all'
        # 'all' 表示查看全部企业，清空 session
        session[:viewing_company_id] = nil
        @viewing_company = nil
      else
        # 只允许切换到该律师负责的企业
        company = Company.accessible_by_lawyer(current_lawyer).find_by(id: params[:company_id])
        if company
          session[:viewing_company_id] = company.id
          @viewing_company = nil # 清除缓存，确保 viewing_company 读取最新的 session 值
        end
      end
    end

    # 律师可以选择企业或查看全部企业
    # 必须验证该企业属于当前律师，防止越权访问
    if session[:viewing_company_id]
      company = Company.accessible_by_lawyer(current_lawyer).find_by(id: session[:viewing_company_id])
      if company.nil?
        # session 里的企业已不属于该律师，清除并回到全部模式
        session[:viewing_company_id] = nil
      end
      company
    else
      # 全部企业模式：返回 nil，允许查看所有记录
      nil
    end
  end
end
