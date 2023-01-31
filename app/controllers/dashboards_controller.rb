class DashboardsController < ApplicationController
  def index
    if current_user
      flash[:info] = "Welcome"
	    pagy_items = 10
	    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

	    @pagy, @job_list_reports = pagy(JobListReport.where(:user_id=> current_user.id, :status=> 'active').order("checked asc, created_at desc"), page: params[:page], items: pagy_items)
    else
      redirect_to '/login'
    end
  end
end
