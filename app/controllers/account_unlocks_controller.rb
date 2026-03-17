class AccountUnlocksController < ApplicationController
  skip_before_action :require_authentication
  
  def show
    token = params[:token]
    
    # Try to find account by unlock token
    account = LawyerAccount.find_by(unlock_token: token) || 
              CompanyUser.find_by(unlock_token: token)
    
    if account
      account.unlock_account!
      redirect_to login_path, notice: '账户已成功解锁，请重新登录'
    else
      redirect_to login_path, alert: '无效的解锁链接或链接已过期'
    end
  end
end
