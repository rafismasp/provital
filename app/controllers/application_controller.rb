class ApplicationController < ActionController::Base
	before_action :configure_permitted_parameters, if: :devise_controller?
	before_action :authenticate_user!
      
  include ApplicationHelper
  include SpreadsheetReportsHelper
  include ActionView::Helpers::NumberHelper
  include Pagy::Backend
  
  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :first_name, :last_name, :email, :department_id])
    update_attrs = [:username, :email, :first_name, :last_name, :password, :password_confirmation, :current_password, :avatar, :avatar_cache, :remove_avatar, :department_id]
    devise_parameter_sanitizer.permit(:account_update, keys: update_attrs)
    
  end

  def after_sign_in_path_for(resource)
    root_path(resource)
  end
  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
  
  rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_422
  
  def rescue_422
    # redirect_to '/422'
    redirect_to root_path
  end


end
