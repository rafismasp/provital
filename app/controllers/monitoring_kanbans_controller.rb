class MonitoringKanbansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_monitoring_kanban, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /inventories
  # GET /inventories.json
  def index
    @product_batch_number = ProductBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes([product: [:unit, :product_type] ])
    records = @product_batch_number.order("outstanding desc, outstanding_sterilization desc, outstanding_sterilization_out desc")
    records = records.where(:id=> params[:product_batch_number_id]) if params[:product_batch_number_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @records = pagy(records, page: params[:page], items: pagy_items)
    
  end

  # GET /inventories/1
  # GET /inventories/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_monitoring_kanban
      @record = ProductBatchNumber.find_by(:id=> params[:id])
      @product = @record.product
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def monitoring_kanban_params
      params.require(:monitoring_kanban).permit(:periode, :begin_stock, :trans_in, :trans_out, :end_stock)
    end
end
