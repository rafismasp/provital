class DirectLaborPricesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_direct_labor_price, only: [:show, :edit, :update, :destroy, :approve]
  before_action :check_status, only: [:edit]
  
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /direct_labor_prices
  # GET /direct_labor_prices.json
  def index
    
    direct_labor_prices = DirectLaborPrice.all
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Supplier Name', 'supplier_id'], ['Currency', 'currency_id']] 
      @option_filter_records = direct_labor_prices
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        end

        direct_labor_prices = direct_labor_prices.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @direct_labor_prices = pagy(direct_labor_prices, page: params[:page], items: pagy_items) 
  end

  # GET /direct_labor_prices/1
  # GET /direct_labor_prices/1.json
  def show
  end

  # GET /direct_labor_prices/new
  def new
    @direct_labor_price = DirectLaborPrice.new
  end
  # GET /direct_labor_prices/1/edit
  def edit
  end

  # POST /direct_labor_prices
  # POST /direct_labor_prices.json
  def create
    params[:direct_labor_price]["created_by"] = current_user.id
    params[:direct_labor_price]["created_at"] = DateTime.now()
    @direct_labor_price = DirectLaborPrice.new(direct_labor_price_params)

    respond_to do |format|
      if @direct_labor_price.save       
        sum_unit_price = 0
        params[:new_record_item].each do |item|
          DirectLaborPriceDetail.create({
            :direct_labor_price_id=> @direct_labor_price.id,
            :target_quantity_perday=> item["target_quantity_perday"],
            :ratio=> item["ratio"].to_i,
            :pay_perday=> item["pay_perday"],
            :unit_price=> (item["pay_perday"].to_f/ item["target_quantity_perday"].to_f),
            :activity_name=> item["activity_name"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          }) 
          sum_unit_price += item["unit_price"].to_f
        end if params[:new_record_item].present?

        @direct_labor_price.update_columns(:unit_price=> sum_unit_price)
        format.html { redirect_to direct_labor_price_path(:id=> @direct_labor_price.id), notice: "#{@direct_labor_price.product.name} was successfully created." }
        format.json { render :show, status: :created, location: @direct_labor_price }
      else
        format.html { render :new }
        format.json { render json: @direct_labor_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /direct_labor_prices/1
  # PATCH/PUT /direct_labor_prices/1.json
  def update
    respond_to do |format|
      params[:direct_labor_price]["updated_by"] = current_user.id
      params[:direct_labor_price]["updated_at"] = DateTime.now()
      if @direct_labor_price.update(direct_labor_price_params)  
        sum_unit_price = 0             
        params[:new_record_item].each do |item|
          DirectLaborPriceDetail.create({
            :direct_labor_price_id=> @direct_labor_price.id,
            :target_quantity_perday=> item["target_quantity_perday"],
            :ratio=> item["ratio"].to_i,
            :pay_perday=> item["pay_perday"],
            :unit_price=> (item["pay_perday"].to_f/ item["target_quantity_perday"].to_f),
            :activity_name=> item["activity_name"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          }) 
          sum_unit_price += item["unit_price"].to_f
        end if params[:new_record_item].present?
        
        params[:record_item].each do |item|
          record_item = DirectLaborPriceDetail.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            record_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            record_item.update_columns({
              :target_quantity_perday=> item["target_quantity_perday"],
              :ratio=> item["ratio"].to_i,
              :pay_perday=> item["pay_perday"],
              :unit_price=> (item["pay_perday"].to_f/ item["target_quantity_perday"].to_f),
              :activity_name=> item["activity_name"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
            sum_unit_price += item["unit_price"].to_f
          end if record_item.present?
        end if params[:record_item].present?

        @direct_labor_price.update_columns(:unit_price=> sum_unit_price)
        format.html { redirect_to @direct_labor_price, notice: "#{@direct_labor_price.product.name} was successfully updated." }
        format.json { render :show, status: :ok, location: @direct_labor_price }
      else
        format.html { render :edit }
        format.json { render json: @direct_labor_price.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @direct_labor_price.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @direct_labor_price.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @direct_labor_price.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @direct_labor_price.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @direct_labor_price.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @direct_labor_price.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to direct_labor_price_path(:id=> @direct_labor_price.id), notice: "Price was successfully #{@direct_labor_price.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /direct_labor_prices/1
  # DELETE /direct_labor_prices/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to direct_labor_prices_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_direct_labor_price
      @direct_labor_price = DirectLaborPrice.find_by(:id=> params[:id])
      if @direct_labor_price.present?
        # @direct_labor_price_details = DirectLaborPriceDetail.where(:direct_labor_price_id=> @direct_labor_price.id, :status=> 'active')
      else
        respond_to do |format|
          format.html { redirect_to direct_labor_prices_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @currencies  = Currency.all
    end

    def check_status      
      noitce_msg = nil 

      if @direct_labor_price.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          noitce_msg = 'Cannot be edited because it has been approved'
        end
      end

      if noitce_msg.present?
        puts "-------------------------------"
        puts  @direct_labor_price.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @direct_labor_price, alert: noitce_msg }
          format.json { render :show, status: :created, location: @direct_labor_price }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def direct_labor_price_params
      params.require(:direct_labor_price).permit(:product_id, :unit_price, :currency_id, :created_by, :created_at, :updated_at, :updated_by)
    end
end
