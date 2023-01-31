class ProductItemCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_item_category, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /product_item_categories
  # GET /product_item_categories.json
  def index
    @product_item_categories = ProductItemCategory.all
  end

  # GET /product_item_categories/1
  # GET /product_item_categories/1.json
  def show
  end

  # GET /product_item_categories/new
  def new
    @product_item_category = ProductItemCategory.new
  end

  # GET /product_item_categories/1/edit
  def edit
  end

  # POST /product_item_categories
  # POST /product_item_categories.json
  def create
    @product_item_category = ProductItemCategory.new(product_item_category_params)

    respond_to do |format|
      if @product_item_category.save
        format.html { redirect_to @product_item_category, notice: 'ProductItemCategory was successfully created.' }
        format.json { render :show, status: :created, location: @product_item_category }
      else
        format.html { render :new }
        format.json { render json: @product_item_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_item_categories/1
  # PATCH/PUT /product_item_categories/1.json
  def update
    respond_to do |format|
      if @product_item_category.update(product_item_category_params)
        format.html { redirect_to @product_item_category, notice: 'ProductItemCategory was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_item_category }
      else
        format.html { render :edit }
        format.json { render json: @product_item_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_item_categories/1
  # DELETE /product_item_categories/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to product_item_categories_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_item_category
      @product_item_category = ProductItemCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_item_category_params
      params.require(:product_item_category).permit(:name)
    end
end
