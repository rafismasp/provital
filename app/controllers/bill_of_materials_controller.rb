class BillOfMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bill_of_material, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]

  # GET /bill_of_materials
  # GET /bill_of_materials.json
  def index
    bill_of_materials = BillOfMaterial.where(:company_profile_id=> current_user.company_profile_id)
    
    # filter select - begin
      @option_filters = [['Product Code','part_id'],['Product Name','name'], ['Product type', 'product_type_id']] 
      @option_filter_records = bill_of_materials
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'color_id'
          @option_filter_records = Color.all
        when 'part_id','name'
          @option_filter_records = @products
        when 'product_type_id'
          @option_filter_records = ProductType.where(:status=> 'active')
        end

        case params[:filter_column] 
        when 'part_id','name','product_type_id'
          bill_of_materials = bill_of_materials.includes(:product).where(:products => {"#{params[:filter_column]}".to_sym=> params[:filter_value] })
        else
          bill_of_materials = bill_of_materials.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
        end
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @bill_of_materials = pagy(bill_of_materials.order("product_id asc"), page: params[:page], items: pagy_items) 
  end

  # GET /bill_of_materials/1
  # GET /bill_of_materials/1.json
  def show
  end

  # GET /bill_of_materials/new
  def new
    @bill_of_material = BillOfMaterial.new
  end

  # GET /bill_of_materials/1/edit
  def edit
  end

  # POST /bill_of_materials
  # POST /bill_of_materials.json
  def create    
    params[:bill_of_material]["company_profile_id"] = current_user.company_profile_id
    params[:bill_of_material]["created_by"] = current_user.id
    params[:bill_of_material]["created_at"] = DateTime.now()
    @bill_of_material = BillOfMaterial.new(bill_of_material_params)

    respond_to do |format|
      params[:new_record_item].each do |item|
        @bill_of_material.bill_of_material_items.build({
          :material_id=> item["material_id"],
          :standard_quantity=> item["standard_quantity"], :allowance=> item["allowance"], :quantity=> item["quantity"],
          :remarks=> item["remarks"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })
      end if params[:new_record_item].present?

      if @bill_of_material.save
        format.html { redirect_to @bill_of_material, notice: 'BillOfMaterial was successfully created.' }
        format.json { render :show, status: :created, location: @bill_of_material }
      else
        format.html { render :new }
        format.json { render json: @bill_of_material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bill_of_materials/1
  # PATCH/PUT /bill_of_materials/1.json
  def update
    respond_to do |format|
      params[:bill_of_material]["updated_by"] = current_user.id
      params[:bill_of_material]["updated_at"] = DateTime.now()
      params[:bill_of_material]["product_id"] = @bill_of_material.product_id
      params[:new_record_item].each do |item|
        @bill_of_material.bill_of_material_items.build({
          :material_id=> item["material_id"],
          :standard_quantity=> item["standard_quantity"], :allowance=> item["allowance"], :quantity=> item["quantity"],
          :remarks=> item["remarks"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })
      end if params[:new_record_item].present?

      if @bill_of_material.update(bill_of_material_params)

        params[:bill_of_material_item].each do |item|
          record_item = BillOfMaterialItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            record_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            record_item.update_columns({ 
              :material_id=> item["material_id"],
              :standard_quantity=> item["standard_quantity"], :allowance=> item["allowance"], :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if record_item.present?
        end if params[:bill_of_material_item].present?
        format.html { redirect_to @bill_of_material, notice: 'BillOfMaterial was successfully updated.' }
        format.json { render :show, status: :ok, location: @bill_of_material }
      else
        format.html { render :edit }
        format.json { render json: @bill_of_material.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /bill_of_materials/1
  # DELETE /bill_of_materials/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to bill_of_materials_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bill_of_material
      @bill_of_material = BillOfMaterial.find_by(:id=> params[:id])
      if @bill_of_material.present?
        @bill_of_material_items  = BillOfMaterialItem.where(:status=> 'active').includes(:bill_of_material).where(:bill_of_materials => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("bill_of_materials.product_id desc")
        @wip_bom_items           = BillOfMaterialItem.where(:status=> 'active').includes(:bill_of_material).where(:bill_of_materials => {:product_id=> @bill_of_material.product_wip1_id, :company_profile_id => current_user.company_profile_id }).order("bill_of_materials.product_id desc")
        @wip2_bom_items           = BillOfMaterialItem.where(:status=> 'active').includes(:bill_of_material).where(:bill_of_materials => {:product_id=> @bill_of_material.product_wip2_id, :company_profile_id => current_user.company_profile_id }).order("bill_of_materials.product_id desc")
      else
        respond_to do |format|
          format.html { redirect_to bill_of_materials_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @wip_products = @products.where(:kind=> 'WIP')
      @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bill_of_material_params
      params.require(:bill_of_material).permit(:product_wip1_id, :wip1_standard_quantity, :wip1_allowance, :product_wip1_quantity, :product_wip1_prf, :product_wip2_id, :wip2_standard_quantity, :wip2_allowance, :product_wip2_quantity, :product_wip2_prf, :company_profile_id, :product_id, :status, :created_at, :created_by, :updated_at, :updated_by)
    end
end
