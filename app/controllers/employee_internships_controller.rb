class EmployeeInternshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_internship, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /employee_internships
  # GET /employee_internships.json
  def index
    @employee_internships = EmployeeInternship.all
  end

  # GET /employee_internships/1
  # GET /employee_internships/1.json
  def show
  end

  # GET /employee_internships/new
  def new
    @employee_internship = EmployeeInternship.new
    @position = Position.all
  end

  # GET /employee_internships/1/edit
  def edit
    @position = Position.all
  end

  # POST /employee_internships
  # POST /employee_internships.json
  def create
    @employee_internship = EmployeeInternship.new(employee_internship_params)

    respond_to do |format|
      if @employee_internship.save
        format.html { redirect_to @employee_internship, notice: 'Employee internship was successfully created.' }
        format.json { render :show, status: :created, location: @employee_internship }
      else
        format.html { render :new }
        format.json { render json: @employee_internship.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employee_internships/1
  # PATCH/PUT /employee_internships/1.json
  def update
    respond_to do |format|
      if @employee_internship.update(employee_internship_params)
        format.html { redirect_to @employee_internship, notice: 'Employee internship was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee_internship }
      else
        format.html { render :edit }
        format.json { render json: @employee_internship.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_internships/1
  # DELETE /employee_internships/1.json
  def destroy
    @employee_internship.destroy
    respond_to do |format|
      format.html { redirect_to employee_internships_url, notice: 'Employee internship was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee_internship
      @employee_internship = EmployeeInternship.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_internship_params
      params.require(:employee_internship).permit(:name, :position_id, :address, :gender, :born_place, :born_date, :last_education, :phone_number)
    end
end
