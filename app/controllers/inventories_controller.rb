class InventoriesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_instance_variable
  before_action :set_inventory, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /inventories
  # GET /inventories.json
  def index
    select_year = (params[:periode].present? ? params[:periode].first(4) : DateTime.now().strftime("%Y"))
    select_month = (params[:periode].present? ? params[:periode].last(2) : DateTime.now().strftime("%m"))
    session[:periode] = "#{select_year}#{select_month}"

    inventories = Inventory.where(:company_profile_id=> current_user.company_profile_id, :periode=> session[:periode]).where("trans_in > 0 or trans_out > 0 or end_stock >= 0")
    case params[:select_inventory_kind]
    when 'material_id'
      inventories = inventories.stock_materials
    when 'product_id'
      inventories = inventories.stock_products
    when 'general_id'
      inventories = inventories.stock_generals
    when 'consumable_id'
      inventories = inventories.stock_consumables
    when 'equipment_id'
      inventories = inventories.stock_equipments
    end
    # filter select - begin
      @option_filter_records = inventories
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'product_id'
          @option_filter_records = @products
        when 'material_id'
          @option_filter_records = @materials
        when 'general_id'
          @option_filter_records = @generals
        when 'consumable_id'
          @option_filter_records = @consumables
        when 'equipment_id'
          @option_filter_records = @equipments
        end

        inventories = inventories.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @inventories = inventories.includes(product: [:unit], material: [:unit], general: [:unit], consumable: [:unit], equipment: [:unit])  
    case params[:partial]
    when 'stock_card'      
      @inventory = Inventory.find_by(:periode=> params[:periode], "#{params[:select_inventory_kind]}".to_sym=> params[:part])
      if @inventory.present?
        @inventory_logs = InventoryLog.where(:inventory_id=> @inventory.id, :status=> 'active')
      end
    end

  end

  # GET /inventories/1
  # GET /inventories/1.json
  def show
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory
      @inventory = Inventory.find(params[:id])
      @inventory_logs = InventoryLog.where(:inventory_id=> params[:id], :status=> 'active')
    end

    def set_instance_variable      
      @option_filters = [['Periode','periode'],['Product','product_id'],['Material','material_id'],['General','general_id'],['Consumable','consumable_id'],['Equipment','equipment_id']] 
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
      @materials   = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
      @generals    = General.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
      @consumables = Consumable.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
      @equipments  = Equipment.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def inventory_params
      params.require(:inventory).permit(:periode, :begin_stock, :trans_in, :trans_out, :end_stock)
    end
end
