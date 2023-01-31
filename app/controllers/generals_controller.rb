class GeneralsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_general, only: [:show, :edit, :update, :destroy]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /generals
  # GET /generals.json
  def index
    @generals = General.all
  end

  # GET /generals/1
  # GET /generals/1.json
  def show
  end

  # GET /generals/new
  def new
    @general = General.new
    @units = Unit.all
    @colors = Color.all
  end

  # GET /generals/1/edit
  def edit
    @units = Unit.all
    @colors = Color.all
  end

  # POST /generals
  # POST /generals.json
  def create
    params[:general]["company_profile_id"] = current_user.company_profile_id
    @general = General.new(general_params)

    respond_to do |format|
      if @general.save
        format.html { redirect_to @general, notice: 'General was successfully created.' }
        format.json { render :show, status: :created, location: @general }
      else
        format.html { render :new }
        format.json { render json: @general.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /generals/1
  # PATCH/PUT /generals/1.json
  def update
    respond_to do |format|
      if @general.update(general_params)
        format.html { redirect_to @general, notice: 'General was successfully updated.' }
        format.json { render :show, status: :ok, location: @general }
      else
        format.html { render :edit }
        format.json { render json: @general.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /generals/1
  # DELETE /generals/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to generals_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_general
      @general = General.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def general_params
      params.require(:general).permit(:name, :company_profile_id, :unit_id, :color_id, :part_id, :part_model)
    end
end
