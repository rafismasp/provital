class EmployeeSectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_section, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /employee_sections
  # GET /employee_sections.json
  def index
    @employee_sections = EmployeeSection.all
  end

  # GET /employee_sections/1
  # GET /employee_sections/1.json
  def show
  end

  # GET /employee_sections/new
  def new
    @employee_section = EmployeeSection.new
  end

  # GET /employee_sections/1/edit
  def edit
  end

  # POST /employee_sections
  # POST /employee_sections.json
  def create
    params[:employee_section]["created_by"] = current_user.id
    params[:employee_section]["created_at"] = DateTime.now()
    @employee_section = EmployeeSection.new(employee_section_params)

    respond_to do |format|
      if @employee_section.save
        format.html { redirect_to @employee_section, notice: 'EmployeeSection was successfully created.' }
        format.json { render :show, status: :created, location: @employee_section }
      else
        format.html { render :new }
        format.json { render json: @employee_section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_sections/1
  # PATCH/PUT /employee_sections/1.json
  def update
    respond_to do |format|
      params[:employee_section]["updated_by"] = current_user.id
      params[:employee_section]["updated_at"] = DateTime.now()
      if @employee_section.update(employee_section_params)
        format.html { redirect_to @employee_section, notice: 'EmployeeSection was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee_section }
      else
        format.html { render :edit }
        format.json { render json: @employee_section.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_sections/1
  # DELETE /employee_sections/1.json
  def destroy
    @employee_section.destroy
    respond_to do |format|
      format.html { redirect_to employee_sections_url, notice: 'EmployeeSection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_section
      @employee_section = EmployeeSection.find(params[:id])
    end

    def set_instance_variable
      @departments = Department.all.order("code asc")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_section_params
      params.require(:employee_section).permit(:name, :department_id, :code, :status, :created_at, :created_by, :updated_at, :updated_by)
    end
end
