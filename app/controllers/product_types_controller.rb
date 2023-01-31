class ProductTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_type, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /product_types
  # GET /product_types.json
  def index
    product_types = ProductType.all
    @product_sub_categories = @product_sub_categories.where(:product_category_id=> params[:product_category_id]).order("name asc") if params[:product_category_id].present?
    
     # filter select - begin
      @option_filters = [['Customer','customer_id'], ['Type','name'], ['Sub Category','product_sub_category_id']] 
      @option_filter_records = product_types
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'product_sub_category_id'
          @option_filter_records = ProductSubCategory.where(:status=> 'active').order("name asc")
        end

        product_types = product_types.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @product_types = pagy(product_types.order("code asc"), page: params[:page], items: pagy_items) 
  end

  # GET /product_types/1
  # GET /product_types/1.json
  def show
  end

  # GET /product_types/new
  def new
    @product_type = ProductType.new
  end

  # GET /product_types/1/edit
  def edit
  end

  # POST /product_types
  # POST /product_types.json
  def create
    params[:product_type]["created_by"] = current_user.id
    params[:product_type]["created_at"] = DateTime.now()
    @product_type = ProductType.new(product_type_params)

    respond_to do |format|
      if @product_type.save
        format.html { redirect_to @product_type, notice: 'ProductType was successfully created.' }
        format.json { render :show, status: :created, location: @product_type }
      else
        format.html { render :new }
        format.json { render json: @product_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_types/1
  # PATCH/PUT /product_types/1.json
  def update
    respond_to do |format|
      params[:product_type]["updated_by"] = current_user.id
      params[:product_type]["updated_at"] = DateTime.now()
      if @product_type.update(product_type_params)
        format.html { redirect_to @product_type, notice: 'ProductType was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_type }
      else
        format.html { render :edit }
        format.json { render json: @product_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_types/1
  # DELETE /product_types/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to product_types_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_type
      @product_type = ProductType.find(params[:id])
    end

    def set_instance_variable
      @product_categories = ProductCategory.all.order("code asc")
      @product_sub_categories = ProductSubCategory.all.order("code asc")
      @customers = Customer.all.order("name asc")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_type_params
      params.require(:product_type).permit(:name, :customer_id, :brand, :product_sub_category_id, :code, :description, :created_at, :created_by, :updated_at, :updated_by)
    end
end
