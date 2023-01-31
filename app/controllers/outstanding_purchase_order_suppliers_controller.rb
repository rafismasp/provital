class OutstandingPurchaseOrderSuppliersController < ApplicationController
  before_action :authenticate_user!

  before_action :set_instance_variable
  before_action :set_outstanding_purchase_order_supplier, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /outstanding_purchase_order_suppliers
  # GET /outstanding_purchase_order_suppliers.json
  def index
    purchase_order_supplier_items = @purchase_order_supplier_items

    case params[:view_kind]
    when 'Over Due'
      purchase_order_supplier_items = @purchase_order_supplier_items.where("purchase_order_supplier_items.due_date < ?", DateTime.now().strftime("%Y-%m-%d"))
    when 'number of days'
      purchase_order_supplier_items = @purchase_order_supplier_items.where("purchase_order_supplier_items.due_date <= ?", (DateTime.now()+params[:number_of_days].to_i).to_date.strftime("%Y-%m-%d"))
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @records = pagy(purchase_order_supplier_items, page: params[:page], items: pagy_items)
  end

  # GET /outstanding_purchase_order_suppliers/1
  # GET /outstanding_purchase_order_suppliers/1.json
  def show
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  def print
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_outstanding_purchase_order_supplier
    end

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:status=> 'active').where("purchase_order_supplier_items.outstanding > 0")
      .includes(purchase_request_item: [material: [:unit], product: [:unit], consumable:[:unit], equipment: [:unit], general: [:unit]])
      .includes(pdm_item: [material: [:unit]])
      .includes(purchase_order_supplier: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, supplier:[:currency]])
      .where(:purchase_order_suppliers => {:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin].. session[:date_end]})
      .order("purchase_order_suppliers.date desc")      
    end
end
