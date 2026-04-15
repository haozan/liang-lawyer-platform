class HomeController < ApplicationController
  skip_before_action :require_authentication, only: [:index]
  before_action :set_full_render, only: [:index]

  def index
    # 如果已登录，根据用户类型重定向到对应的主页
    if current_user
      if lawyer?
        redirect_to lawyer_companies_path
      elsif company_user?
        redirect_to workbench_index_path
      else
        redirect_to login_path, alert: '未知用户类型'
      end
    end
    
    # 未登录用户继续渲染首页 (index.html.erb)
  end

  private

  def set_full_render
    @full_render = true
  end
end
