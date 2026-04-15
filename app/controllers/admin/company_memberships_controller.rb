class Admin::CompanyMembershipsController < Admin::BaseController
  before_action :set_company

  def new
    @membership = @company.company_memberships.build
    # 已在此企业的用户 id 列表，供下拉排除
    @existing_user_ids = @company.company_memberships.pluck(:company_user_id)
    @available_users = CompanyUser.where.not(id: @existing_user_ids).ordered
  end

  def create
    # 支持创建新用户并同时加入企业，或从已有用户中选择
    if params[:create_new_user] == '1'
      create_new_user_and_add
    else
      add_existing_user
    end
  end

  def destroy
    @membership = @company.company_memberships.find(params[:id])
    user_name = @membership.company_user.name
    @membership.destroy
    redirect_to admin_company_path(@company), notice: "已移除成员「#{user_name}」"
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def create_new_user_and_add
    user_params = params.require(:company_user).permit(:name, :phone, :password, :password_confirmation)
    role = params[:role].presence || 'employee'

    ActiveRecord::Base.transaction do
      @user = CompanyUser.new(user_params)
      unless @user.save
        flash.now[:alert] = "创建用户失败：#{@user.errors.full_messages.join('，')}"
        @existing_user_ids = @company.company_memberships.pluck(:company_user_id)
        @available_users = CompanyUser.where.not(id: @existing_user_ids).ordered
        render :new, status: :unprocessable_entity and return
      end

      @membership = @company.company_memberships.create!(company_user: @user, role: role)
    end

    redirect_to admin_company_path(@company), notice: "成员「#{@user.name}」已创建并加入企业"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "操作失败：#{e.message}"
    @existing_user_ids = @company.company_memberships.pluck(:company_user_id)
    @available_users = CompanyUser.where.not(id: @existing_user_ids).ordered
    render :new, status: :unprocessable_entity
  end

  def add_existing_user
    company_user = CompanyUser.find_by(id: params[:company_user_id])
    role = params[:role].presence || 'employee'

    unless company_user
      redirect_to new_admin_company_company_membership_path(@company), alert: '请选择有效的企业用户'
      return
    end

    membership = @company.company_memberships.build(company_user: company_user, role: role)
    if membership.save
      redirect_to admin_company_path(@company), notice: "已将「#{company_user.name}」加入企业"
    else
      redirect_to new_admin_company_company_membership_path(@company),
                  alert: "操作失败：#{membership.errors.full_messages.join('，')}"
    end
  end
end
