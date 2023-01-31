class EmployeeTimeOffRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_time_off_request, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /employee_time_off_requests
  # GET /employee_time_off_requests.json
  def index
    @employee_time_off_requests = EmployeeTimeOffRequest.all
  end

  # GET /employee_time_off_requests/1
  # GET /employee_time_off_requests/1.json
  def show
  end

  # GET /employee_time_off_requests/new
  def new
    @employee_time_off_request = EmployeeTimeOffRequest.new
  end

  # GET /employee_time_off_requests/1/edit
  def edit
  end

  # POST /employee_time_off_requests
  # POST /employee_time_off_requests.json
  def create
    params[:employee_time_off_request]["company_profile_id"] = current_user.company_profile_id
    params[:employee_time_off_request]["created_by"] = current_user.id
    params[:employee_time_off_request]["created_at"] = DateTime.now()
    @employee_time_off_request = EmployeeTimeOffRequest.new(employee_time_off_request_params)

    respond_to do |format|
      if @employee_time_off_request.save
        format.html { redirect_to @employee_time_off_request, notice: 'EmployeeTimeOffRequest was successfully created.' }
        format.json { render :show, status: :created, location: @employee_time_off_request }
      else
        format.html { render :new }
        format.json { render json: @employee_time_off_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_time_off_requests/1
  # PATCH/PUT /employee_time_off_requests/1.json
  def update
    respond_to do |format|
      params[:employee_time_off_request]["updated_by"] = current_user.id
      params[:employee_time_off_request]["updated_at"] = DateTime.now()
      if @employee_time_off_request.update(employee_time_off_request_params)
        format.html { redirect_to @employee_time_off_request, notice: 'EmployeeTimeOffRequest was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee_time_off_request }
      else
        format.html { render :edit }
        format.json { render json: @employee_time_off_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_time_off_requests/1
  # DELETE /employee_time_off_requests/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to employee_time_off_requests_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_time_off_request
      @employee_time_off_request = EmployeeTimeOffRequest.find_by(:id=> params[:id])
    end

    def set_instance_variable
      @employees = Employee.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
      @departments = Department.where(:status=> 'active')
      @leave_types = LeaveType.where(:status=> 'active')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_time_off_request_params
      params.require(:employee_time_off_request).permit(:company_profile_id, :leave_type_id, :beginning_at, :ending_at, :department_id, :employee_id, :remarks, :created_at, :created_by, :updated_at, :updated_by)
    end
end
