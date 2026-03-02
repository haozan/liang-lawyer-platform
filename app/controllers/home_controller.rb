class HomeController < ApplicationController
  skip_before_action :require_authentication, only: [:index]
  
  def index
    # 已登录用户自动跳转到对应页面
    if current_lawyer
      redirect_to lawyer_companies_path
    elsif current_company_user
      redirect_to workbench_index_path
    end
    # 未登录用户显示落地页 - will be rendered from shared/demo.html.erb if home/index.html.erb doesn't exist
  end
end
