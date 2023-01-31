class ConsumablesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_consumable, only: [:show, :edit, :update, :destroy]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /consumables
  # GET /consumables.json
  def index
    @consumables = Consumable.all
  end

  # GET /consumables/1
  # GET /consumables/1.json
  def show
  end

  # GET /consumables/new
  def new
    @consumable = Consumable.new
  end

  # GET /consumables/1/edit
  def edit
  end

  # POST /consumables
  # POST /consumables.json
  def create
    @consumable = Consumable.new(consumable_params)

    respond_to do |format|
      if @consumable.save
        format.html { redirect_to @consumable, notice: 'Consumable was successfully created.' }
        format.json { render :show, status: :created, location: @consumable }
      else
        format.html { render :new }
        format.json { render json: @consumable.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /consumables/1
  # PATCH/PUT /consumables/1.json
  def update
    respond_to do |format|
      if @consumable.update(consumable_params)
        format.html { redirect_to @consumable, notice: 'Consumable was successfully updated.' }
        format.json { render :show, status: :ok, location: @consumable }
      else
        format.html { render :edit }
        format.json { render json: @consumable.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /consumables/1
  # DELETE /consumables/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to consumables_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_consumable
      @consumable = Consumable.find(params[:id])
    end
    def set_instance_variable
      @units = Unit.all
      @colors = Color.all
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def consumable_params
      params.require(:consumable).permit(:name, :unit_id, :color_id, :part_id, :part_model)
    end
end
