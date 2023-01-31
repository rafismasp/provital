class MaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  include MaterialsHelper

  # GET /materials
  # GET /materials.json
  def index
    materials = Material.where(:company_profile_id=> current_user.company_profile_id)
    @product_sub_categories = @product_sub_categories.where(:product_category_id=> params[:product_category_id]) if params[:product_category_id].present?
    @product_types = @product_types.where(:product_sub_category_id=> params[:product_sub_category_id]) if params[:product_sub_category_id].present?
    
    # filter select - begin
      @option_filters = [['Material Code','part_id'],['Material Name','name'], ['Vendor Name', 'vendor_name']] 
      @option_filter_records = materials
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'color_id'
          @option_filter_records = Color.all
        end

        materials = materials.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @materials = pagy(materials.order("part_id asc"), page: params[:page], items: pagy_items) 
  end

  # GET /materials/1
  # GET /materials/1.json
  def show
  end

  # GET /materials/new
  def new
    @material = Material.new
  end

  # GET /materials/1/edit
  def edit
  end

  # POST /materials
  # POST /materials.json
  def create    
    params[:material]["company_profile_id"] = current_user.company_profile_id
    params[:material]["created_by"] = current_user.id
    params[:material]["created_at"] = DateTime.now()
    params[:material]["part_id"] = material_code(params[:material]["material_category_id"])
    @material = Material.new(material_params)

    respond_to do |format|
      if @material.save
        format.html { redirect_to @material, notice: 'Material was successfully created.' }
        format.json { render :show, status: :created, location: @material }
      else
        format.html { render :new }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /materials/1
  # PATCH/PUT /materials/1.json
  def update
    respond_to do |format|
      params[:material]["updated_by"] = current_user.id
      params[:material]["updated_at"] = DateTime.now()
      params[:material]["part_id"] = @material.part_id
      if @material.update(material_params)
        format.html { redirect_to @material, notice: 'Material was successfully updated.' }
        format.json { render :show, status: :ok, location: @material }
      else
        format.html { render :edit }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /materials/1
  # DELETE /materials/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to materials_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material
      @material = Material.find(params[:id])
    end

    def set_instance_variable
      @vendor_lists = Material.where(:company_profile_id=> current_user.company_profile_id).group(:vendor_name)
      @material_categories = MaterialCategory.all
      @units = Unit.all
      @colors = Color.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def material_params
      params.require(:material).permit(:company_profile_id, :name, :unit_id, :color_id, :vendor_name, :material_category_id, :part_id, :part_model, :minimum_order_quantity, :status, :created_at, :created_by, :updated_at, :updated_by)
    end
end
