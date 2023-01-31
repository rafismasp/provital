class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  include ProductsHelper

  # GET /products
  # GET /products.json
  def index
    products = Product.where(:company_profile_id=> current_user.company_profile_id)
    @product_sub_categories = @product_sub_categories.where(:product_category_id=> params[:product_category_id]) if params[:product_category_id].present?
    @product_types = @product_types.where(:product_sub_category_id=> params[:product_sub_category_id]) if params[:product_sub_category_id].present?
    
    # filter select - begin
      @option_filters = [['Product Code','part_id'],['Product Name','name'], ['Customer Name', 'customer_id']] 
      @option_filter_records = products
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        end

        products = products.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @products = pagy(products.order("part_id asc"), page: params[:page], items: pagy_items) 
  end

  # GET /products/1
  # GET /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new

  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    params[:product]["company_profile_id"] = current_user.company_profile_id
    params[:product]["created_by"] = current_user.id
    params[:product]["created_at"] = DateTime.now()
    params[:product]["status"] = "active"
    new_product_code = product_code(params[:product]["product_category_id"], params[:product]["product_sub_category_id"], params[:product]["product_type_id"])
    params[:product]["part_id"] = new_product_code

    @product = Product.new(product_params)
    respond_to do |format|
        if @product.save
          format.html { redirect_to @product, notice: 'Product was successfully created.' }
          format.json { render :show, status: :created, location: @product }
        else
          puts @product.errors.full_messages
          format.html { render :new }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      params[:product]["company_profile_id"] = @product.company_profile_id
      params[:product]["part_id"] = @product.part_id
      params[:product]["updated_by"] = current_user.id
      params[:product]["updated_at"] = DateTime.now()
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to products_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end
    def set_instance_variable
      @product_item_categories = ProductItemCategory.all
      @customers = Customer.where(:status=> 'active').order("name asc")
      @units = Unit.all
      @colors = Color.all
      @product_categories = ProductCategory.all.order("code asc")
      @product_sub_categories = ProductSubCategory.all.order("code asc")
      @product_types = ProductType.all.order("code asc")


    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:company_profile_id, :kind, :product_category_id, :product_sub_category_id, :product_type_id, :name, :unit_id, :color_id, :part_id, :part_model, :customer_id, :nie_number, :nie_expired_date, :product_item_category_id, :max_batch, :status, :created_at, :created_by, :updated_at, :updated_by)
    end
end
