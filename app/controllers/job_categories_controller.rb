class JobCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_job_category, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /job_categories
  # GET /job_categories.json
  def index
    @job_categories = JobCategory.all
  end

  # GET /job_categories/1
  # GET /job_categories/1.json
  def show
  end

  # GET /job_categories/new
  def new
    @job_category = JobCategory.new
  end

  # GET /job_categories/1/edit
  def edit
  end

  # POST /job_categories
  # POST /job_categories.json
  def create
    @job_category = JobCategory.new(job_category_params)

    respond_to do |format|
      if @job_category.save
        format.html { redirect_to @job_category, notice: 'Job category was successfully created.' }
        format.json { render :show, status: :created, location: @job_category }
      else
        format.html { render :new }
        format.json { render json: @job_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /job_categories/1
  # PATCH/PUT /job_categories/1.json
  def update
    respond_to do |format|
      if @job_category.update(job_category_params)
        format.html { redirect_to @job_category, notice: 'Job category was successfully updated.' }
        format.json { render :show, status: :ok, location: @job_category }
      else
        format.html { render :edit }
        format.json { render json: @job_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /job_categories/1
  # DELETE /job_categories/1.json
  def destroy
    @job_category.destroy
    respond_to do |format|
      format.html { redirect_to job_categories_url, notice: 'Job category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job_category
      @job_category = JobCategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_category_params
      params.require(:job_category).permit(:name)
    end
end
