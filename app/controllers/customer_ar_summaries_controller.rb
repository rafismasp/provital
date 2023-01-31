class CustomerArSummariesController < ApplicationController
  before_action :authenticate_user!

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_remove, only: [:destroy]

  # GET /inventories
  # GET /inventories.json
  def index
    # 20220317 - Danny
    params[:periode_yyyy] = (params[:periode_yyyy].present? ? params[:periode_yyyy] : DateTime.now().strftime("%Y"))
    records = InvoiceCustomer.where(:status=> 'approved3', :company_profile_id=> current_user.company_profile_id).where("date between ? and ?", "#{params[:periode_yyyy]}-01-01", "#{params[:periode_yyyy]}-12-31").includes(customer: [:currency]).order("date asc")
    
    record_grouped = records.group(:customer_id)
    @all_records   = records

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @records = pagy(record_grouped, page: params[:page], items: pagy_items) 
  end
  
  def new
  end

  # GET /inventories/1
  # GET /inventories/1.json
  def show
  end

  def create
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

end
