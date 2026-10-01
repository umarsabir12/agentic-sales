class Admin::BaseController < ApplicationController
  before_action :require_admin

  private
    def require_admin
      redirect_to root_path, alert: "Only admins can do that." unless current_user.admin?
    end
end
