class ProductCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_category, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /product_categories
  # GET /product_categories.json
  def index
    product_categories = ProductCategory.all
     # filter select - begin
      @option_filters = [['Category','kind'], ['Description','name']] 
      @option_filter_records = product_categories
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'kind'
          @option_filter_records = ['Medical Devices','Non Medical Devices','Sterilization','Household (PKRT)','Laboratory Testing', 'General']
        end

        product_categories = product_categories.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @product_categories = pagy(product_categories.order("code asc"), page: params[:page], items: pagy_items) 
  end

  # GET /product_categories/1
  # GET /product_categories/1.json
  def show
  end

  # GET /product_categories/new
  def new
    @product_category = ProductCategory.new
  end

  # GET /product_categories/1/edit
  def edit
  end

  # POST /product_categories
  # POST /product_categories.json
  def create
    params[:product_category]["created_by"] = current_user.id
    params[:product_category]["created_at"] = DateTime.now()
    @product_category = ProductCategory.new(product_category_params)

    respond_to do |format|
      if @product_category.save
        format.html { redirect_to @product_category, notice: 'ProductCategory was successfully created.' }
        format.json { render :show, status: :created, location: @product_category }
      else
        format.html { render :new }
        format.json { render json: @product_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_categories/1
  # PATCH/PUT /product_categories/1.json
  def update
    respond_to do |format|
      params[:product_category]["updated_by"] = current_user.id
      params[:product_category]["updated_at"] = DateTime.now()
      if @product_category.update(product_category_params)
        format.html { redirect_to @product_category, notice: 'ProductCategory was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_category }
      else
        format.html { render :edit }
        format.json { render json: @product_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_categories/1
  # DELETE /product_categories/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to product_categories_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_category
      @product_category = ProductCategory.find(params[:id])
    end

    def set_instance_variable
      @kind_categories  = ['Medical Devices','Non Medical Devices','Sterilization','Household (PKRT)','Laboratory Testing', 'General']
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_category_params
      params.require(:product_category).permit(:kind, :name, :code, :description, :created_at, :created_by, :updated_at, :updated_by)
    end
end
