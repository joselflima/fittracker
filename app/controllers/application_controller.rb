class ApplicationController < ActionController::Base
  before_action :require_login
  helper_method :current_user
  after_action :prevent_private_caching
  stale_when_importmap_changes

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    redirect_to new_session_path unless current_user
  end

  def prevent_private_caching
    no_store
  end
end
