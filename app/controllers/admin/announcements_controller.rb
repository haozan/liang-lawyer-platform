class Admin::AnnouncementsController < Admin::BaseController
  before_action :set_announcement, only: [:show, :edit, :update, :destroy]

  def index
    @announcements = Announcement.where(created_by_type: 'Administrator')
      .includes(:company, :related)
      .order(published_at: :desc)
      .page(params[:page]).per(15)
  end

  def show
  end

  def new
    @announcement = Announcement.new(
      announcement_type: 'custom',
      priority: 'normal',
      published_at: Time.current
    )
    @companies = Company.all
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.created_by_type = 'Administrator'
    @announcement.created_by_id = current_admin.id

    if @announcement.save
      redirect_to admin_announcements_path, notice: '公告创建成功'
    else
      @companies = Company.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @companies = Company.all
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to admin_announcements_path, notice: '公告更新成功'
    else
      @companies = Company.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    redirect_to admin_announcements_path, notice: '公告删除成功'
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :priority, :company_id, :expires_at, :published_at)
  end
end
