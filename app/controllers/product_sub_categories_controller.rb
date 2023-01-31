class ProductSubCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_sub_category, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /product_sub_categories
  # GET /product_sub_categories.json
  def index
    product_sub_categories = ProductSubCategory.all
     # filter select - begin
      @option_filters = [['Category','product_category_id'], ['Sub Category','name']] 
      @option_filter_records = product_sub_categories
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'product_category_id'
          @option_filter_records = ProductCategory.where(:status=> 'active').order("code asc")
        end

        product_sub_categories = product_sub_categories.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @product_sub_categories = pagy(product_sub_categories.order("code asc"), page: params[:page], items: pagy_items) 
  end

  # GET /product_sub_categories/1
  # GET /product_sub_categories/1.json
  def show
  end

  # GET /product_sub_categories/new
  def new
    @product_sub_category = ProductSubCategory.new
  end

  # GET /product_sub_categories/1/edit
  def edit
  end

  # POST /product_sub_categories
  # POST /product_sub_categories.json
  def create
    params[:product_sub_category]["created_by"] = current_user.id
    params[:product_sub_category]["created_at"] = DateTime.now()
    @product_sub_category = ProductSubCategory.new(product_sub_category_params)

    respond_to do |format|
      if @product_sub_category.save
        format.html { redirect_to @product_sub_category, notice: 'ProductSubCategory was successfully created.' }
        format.json { render :show, status: :created, location: @product_sub_category }
      else
        format.html { render :new }
        format.json { render json: @product_sub_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_sub_categories/1
  # PATCH/PUT /product_sub_categories/1.json
  def update
    respond_to do |format|
      params[:product_sub_category]["updated_by"] = current_user.id
      params[:product_sub_category]["updated_at"] = DateTime.now()
      if @product_sub_category.update(product_sub_category_params)
        format.html { redirect_to @product_sub_category, notice: 'ProductSubCategory was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_sub_category }
      else
        format.html { render :edit }
        format.json { render json: @product_sub_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_sub_categories/1
  # DELETE /product_sub_categories/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to product_sub_categories_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_sub_category
      @product_sub_category = ProductSubCategory.find(params[:id])
    end
    def set_instance_variable
      @product_categories = ProductCategory.all.order("code asc")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_sub_category_params
      params.require(:product_sub_category).permit(:name, :product_category_id, :code, :description, :created_at, :created_by, :updated_at, :updated_by)
    end
end
