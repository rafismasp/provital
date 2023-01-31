class ProductionOrderMaterialCostsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_instance_variable
  before_action :set_production_order_material_cost, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /production_order_material_costs
  # GET /production_order_material_costs.json
  def index
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @records = pagy(@production_order_used_prves, page: params[:page], items: pagy_items)
  end

  # GET /production_order_material_costs/1
  # GET /production_order_material_costs/1.json
  def show
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_production_order_material_cost
    end

    def set_instance_variable      
      @option_filters = [['Periode','periode'],['Product','product_id'],['Material','material_id'],['General','general_id']] 

      @production_order_used_prves = ProductionOrderUsedPrf.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      .includes(
        production_order_item: [
          :product, :sales_order_item, production_order: [:sales_order]
        ], 
        purchase_request_item: [
          :material, :product, 
          :purchase_request
        ])
      .where(purchase_request_items: { status: 'active' } )
      .where("purchase_request_items.quantity > ?", 0)
      .order("sales_orders.number asc, products.part_id asc")
    end
end
