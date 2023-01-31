class OutstandingPurchaseRequestsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_instance_variable
  before_action :set_outstanding_purchase_request, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /outstanding_purchase_requests
  # GET /outstanding_purchase_requests.json
  def index
    purchase_request_items = @purchase_request_items

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @records = pagy(purchase_request_items, page: params[:page], items: pagy_items)
  end

  # GET /outstanding_purchase_requests/1
  # GET /outstanding_purchase_requests/1.json
  def show
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  def print
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_outstanding_purchase_request
    end

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @purchase_request_items = PurchaseRequestItem.where(:status=> 'active').where("purchase_request_items.outstanding > 0")
      .includes(material: [:unit], product: [:unit], consumable:[:unit], equipment: [:unit], general: [:unit])
      .includes(purchase_request: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3 ])
      .includes(purchase_order_supplier_items: [:purchase_order_supplier])
      .where(:purchase_requests => {:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin].. session[:date_end]})
      .order("purchase_requests.date desc")      
    end
end
