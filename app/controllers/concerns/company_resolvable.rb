# frozen_string_literal: true

# CompanyResolvable Concern
# 为控制器提供统一的 set_company 方法
# 核心作用：企业用户数据隔离 + 律师切换企业视角
#
# 使用方式:
#   class CasesController < ApplicationController
#     include CompanyResolvable
#     before_action :set_company
#   end

module CompanyResolvable
  extend ActiveSupport::Concern

  private

  # 通用 set_company：
  # - 企业用户：只能访问自己公司数据（强制隔离）
  # - 律师用户：可通过 session 切换企业视角
  def set_company
    @company = if current_company_user
                 # 🔒 企业用户强制绑定自己的公司，防止数据泄露
                 viewing_company
               elsif current_lawyer
                 resolve_company_for_lawyer
               end

    if current_company_user && @company.nil?
      redirect_to root_path, alert: '未找到公司'
    end
  end

  private

  # 解析律师视角下的当前企业（维护 session）
  def resolve_company_for_lawyer
    if params[:company_id].present?
      if params[:company_id] == 'all'
        session[:viewing_company_id] = nil
        @viewing_company = nil
      else
        company = Company.accessible_by_lawyer(current_lawyer).find_by(id: params[:company_id])
        if company
          session[:viewing_company_id] = company.id
          @viewing_company = nil
        end
      end
    end

    if session[:viewing_company_id]
      company = Company.accessible_by_lawyer(current_lawyer).find_by(id: session[:viewing_company_id])
      if company.nil?
        session[:viewing_company_id] = nil
      end
      company
    end
  end
end
