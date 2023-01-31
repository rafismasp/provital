class EquipmentController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /equipments
  # GET /equipments.json
  def index
    @equipments = Equipment.all
  end

  # GET /equipments/1
  # GET /equipments/1.json
  def show
  end

  # GET /equipments/new
  def new
    @equipment = Equipment.new
  end

  # GET /equipments/1/edit
  def edit
  end

  # POST /equipments
  # POST /equipments.json
  def create
    params[:equipment]["company_profile_id"] = current_user.company_profile_id
    params[:equipment]["created_by"] = current_user.id
    params[:equipment]["created_at"] = DateTime.now()
    params[:equipment]["status"] = "active"
    @equipment = Equipment.new(equipment_params)

    respond_to do |format|
      if @equipment.save
        format.html { redirect_to @equipment, notice: 'Equipment was successfully created.' }
        format.json { render :show, status: :created, location: @equipment }
      else
        format.html { render :new }
        format.json { render json: @equipment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /equipments/1
  # PATCH/PUT /equipments/1.json
  def update
    respond_to do |format|
      params[:equipment]["updated_by"] = current_user.id
      params[:equipment]["updated_at"] = DateTime.now()
      params[:equipment]["part_id"] = @equipment.part_id
      if @equipment.update(equipment_params)
        format.html { redirect_to @equipment, notice: 'Equipment was successfully updated.' }
        format.json { render :show, status: :ok, location: @equipment }
      else
        format.html { render :edit }
        format.json { render json: @equipment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /equipments/1
  # DELETE /equipments/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to equipments_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_equipment
      @equipment = Equipment.find(params[:id])
    end
    def set_instance_variable
      @units = Unit.all
      @colors = Color.all
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def equipment_params
      params.require(:equipment).permit(:company_profile_id, :name, :unit_id, :color_id, :part_id, :part_model, :status, :created_at, :created_by, :updated_at, :updated_by)
    end
end
