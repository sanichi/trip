class ApplicationController < ActionController::Base
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { redirect_to sign_in_path, alert: exception.message }
      format.json { head :forbidden, content_type: "text/html" }
      format.js   { head :forbidden, content_type: "text/html" }
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) || Guest.new
  end

  helper_method :current_user

  def full_reload() = @full_reload
  def force_full_reload
    @full_reload = true
  end

  helper_method :full_reload, :force_full_reload

  def failure(object)
    flash.now[:alert] = object.errors.full_messages.join(", ")
  end
end
