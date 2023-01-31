class JobListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_job_list, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /job_lists
  # GET /job_lists.json
  def index
    @job_lists = JobList.where(:company_profile_id=> current_user.company_profile_id, :user_id=> current_user.id, :status=> 'active')
      
  end

  # GET /job_lists/1
  # GET /job_lists/1.json
  def show
  end

  # GET /job_lists/new
  def new
    @job_list = JobList.new
    @job_category = JobCategory.all
    if current_user.department_id.present?
      @department = Department.where(:id=> current_user.department_id)
    else
      @department = Department.all
    end
    @users = User.all
  end

  # GET /job_lists/1/edit
  def edit
    @department = Department.all
    @job_category = JobCategory.all
    @users = User.all
  end

  # POST /job_lists
  # POST /job_lists.json
  def create
    params[:job_list]['company_profile_id'] = current_user.company_profile_id
    @job_list = JobList.new(job_list_params)

    respond_to do |format|
      if @job_list.save
        format.html { redirect_to @job_list, notice: 'Job list was successfully created.' }
        format.json { render :show, status: :created, location: @job_list }
      else
        format.html { render :new }
        format.json { render json: @job_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /job_lists/1
  # PATCH/PUT /job_lists/1.json
  def update
    respond_to do |format|
      if @job_list.update(job_list_params)
        format.html { redirect_to @job_list, notice: 'Job list was successfully updated.' }
        format.json { render :show, status: :ok, location: @job_list }
      else
        format.html { render :edit }
        format.json { render json: @job_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /job_lists/1
  # DELETE /job_lists/1.json
  def destroy
    @job_list.destroy
    respond_to do |format|
      format.html { redirect_to job_lists_url, notice: 'Job list was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job_list
      @job_list = JobList.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_list_params
      params[:job_list]["created_by"] = current_user.id
      params.require(:job_list).permit(:company_profile_id, :name,:interval, :weekly_day, :department_id, :user_id, :description, :time_required, :status, :created_by, :job_category_id)
    end
end
