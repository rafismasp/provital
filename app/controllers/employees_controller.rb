class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  
  # GET /employees
  # GET /employees.json
  def index
  end

  # GET /employees/1
  # GET /employees/1.json
  def show
  end

  # GET /employees/new
  def new
    @employee = Employee.new
  end

  # GET /employees/1/edit
  def edit
  end

  # POST /employees
  # POST /employees.json
  def create
    params[:employee]["created_by"] = current_user.id
    params[:employee]["created_at"] = DateTime.now()
    params[:employee]['company_profile_id'] = current_user.company_profile_id
    @employee = Employee.new(employee_params)

    respond_to do |format|
      if @employee.save
        format.html { redirect_to @employee, notice: 'Employee was successfully created.' }
        format.json { render :show, status: :created, location: @employee }
      else
        format.html { render :new }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/1
  # PATCH/PUT /employees/1.json
  def update
    respond_to do |format|
      params[:employee]["updated_by"] = current_user.id
      params[:employee]["updated_at"] = DateTime.now()
      if @employee.update(employee_params)
        format.html { redirect_to @employee, notice: 'Employee was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee }
      else
        format.html { render :edit }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to employees_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee
      @employee = Employee.find(params[:id])
    end

    def set_instance_variable
      @employees = Employee.where(:employee_legal_id=> params[:select_employee_legal_id].present? ? params[:select_employee_legal_id] : 1).where(:employee_status=> params[:select_employee_status].present? ? params[:select_employee_status] : 'Aktif')
      @department = Department.all
      @position = Position.all
      @work_status = WorkStatus.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_params
      params.require(:employee).permit(:name, :employee_legal_id, :company_profile_id, :ktp, :ktp_expired_date, :join_date, :resign_date, :employee_status, :nik, :born_place, :born_date, :gender, :phone_number, :email_address, :department_id, :position_id, :work_status_id, :work_schedule, :origin_address, :domicile_address, :blood, :married_status, :religion, :last_education, :vocational_education, :npwp, :npwp_address, :kpj_number, :bpjs, :bpjs_hospital, :family_card, :sim_a_number, :sim_a_date, :sim_a_place, :sim_b_number, :sim_b_date, :sim_b_place, :sim_c_number, :sim_c_date, :sim_c_place, :image, :image_cache, :remove_image, :created_by, :created_at, :updated_at, :updated_by)
    end
end
