class Admin::CompaniesController < Admin::BaseController
  before_action :set_company, only: [:show, :edit, :update, :destroy, :suspend, :resume, :archive]

  def index
    @companies = Company.ordered.page(params[:page]).per(20)
    @companies = @companies.where('name LIKE ?', "%#{params[:q]}%") if params[:q].present?
  end

  def show
    @memberships = @company.company_memberships.includes(:company_user).ordered
  end

  def new
    @company = Company.new(status: 'active')
    @lawyer_options = LawyerAccount.order(:name).pluck(:name, :id)
  end

  def create
    @company = Company.new(company_params_with_lawyers)
    if @company.save
      redirect_to admin_company_path(@company), notice: '企业创建成功'
    else
      @lawyer_options = LawyerAccount.order(:name).pluck(:name, :id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @lawyer_options = LawyerAccount.order(:name).pluck(:name, :id)
  end

  def update
    if @company.update(company_params_with_lawyers)
      redirect_to admin_company_path(@company), notice: '企业信息已更新'
    else
      @lawyer_options = LawyerAccount.order(:name).pluck(:name, :id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @company.safe_to_delete?
      @company.destroy
      redirect_to admin_companies_path, notice: '企业已删除'
    else
      redirect_to admin_company_path(@company), alert: '该企业还有关联数据，无法删除'
    end
  end

  def suspend
    @company.update!(status: 'suspended', suspended_at: Time.current,
                     suspended_reason: params[:reason].presence || '管理员操作')
    redirect_to admin_company_path(@company), notice: '企业服务已暂停'
  end

  def resume
    @company.update!(status: 'active', suspended_at: nil, suspended_reason: nil)
    redirect_to admin_company_path(@company), notice: '企业服务已恢复'
  end

  def archive
    @company.update!(status: 'archived')
    redirect_to admin_company_path(@company), notice: '企业已归档'
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :status, :service_expires_at, assigned_lawyer_ids: [])
  end

  def company_params_with_lawyers
    p = company_params
    # 未勾选时 assigned_lawyer_ids 不出现在表单，手动补空数组
    p[:assigned_lawyer_ids] ||= []
    p
  end
end
