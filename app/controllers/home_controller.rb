class HomeController < ApplicationController
  skip_before_action :require_authentication, only: [:index]
  
  def index
    # Landing page - will be rendered from shared/demo.html.erb if home/index.html.erb doesn't exist
  end
end
