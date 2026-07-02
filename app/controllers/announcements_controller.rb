class AnnouncementsController < ApplicationController
  def index
    @announcements = if lawyer?
      Announcement.active.ordered
    elsif company_user? && viewing_company
      Announcement.active.for_company(viewing_company.id).ordered
    else
      Announcement.none
    end

    @announcements = @announcements.page(params[:page]).per(20)
  end
end
