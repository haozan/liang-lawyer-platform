class Admin::ContractTagsController < Admin::BaseController
  before_action :set_contract_tag, only: [:show, :edit, :update, :destroy]

  def index
    @contract_tags = ContractTag.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @contract_tag = ContractTag.new
  end

  def create
    @contract_tag = ContractTag.new(contract_tag_params)

    if @contract_tag.save
      redirect_to admin_contract_tag_path(@contract_tag), notice: 'Contract tag was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contract_tag.update(contract_tag_params)
      redirect_to admin_contract_tag_path(@contract_tag), notice: 'Contract tag was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contract_tag.destroy
    redirect_to admin_contract_tags_path, notice: 'Contract tag was successfully deleted.'
  end

  private

  def set_contract_tag
    @contract_tag = ContractTag.find(params[:id])
  end

  def contract_tag_params
    params.require(:contract_tag).permit(:name, :color, :company_id)
  end
end
