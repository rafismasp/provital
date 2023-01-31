class DirectLaborWorkersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_direct_labor_worker, only: [:show, :edit, :update, :destroy, :print]
  
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /direct_labor_workers
  # GET /direct_labor_workers.json
  def index
    
    direct_labor_workers = DirectLaborWorker.all
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Supplier Name', 'supplier_id'], ['Currency', 'currency_id']] 
      @option_filter_records = direct_labor_workers
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        end

        direct_labor_workers = direct_labor_workers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @direct_labor_workers = pagy(direct_labor_workers, page: params[:page], items: pagy_items) 
  end

  # GET /direct_labor_workers/1
  # GET /direct_labor_workers/1.json
  def show
  end

  # GET /direct_labor_workers/new
  def new
    @direct_labor_worker = DirectLaborWorker.new
  end
  # GET /direct_labor_workers/1/edit
  def edit
  end

  # POST /direct_labor_workers
  # POST /direct_labor_workers.json
  def create
    params[:direct_labor_worker]["created_by"] = current_user.id
    params[:direct_labor_worker]["created_at"] = DateTime.now()
    @direct_labor_worker = DirectLaborWorker.new(direct_labor_worker_params)

    respond_to do |format|
      if @direct_labor_worker.save
        format.html { redirect_to direct_labor_worker_path(:id=> @direct_labor_worker.id), notice: "#{@direct_labor_worker.name} was successfully created." }
        format.json { render :show, status: :created, location: @direct_labor_worker }
      else
        format.html { render :new }
        format.json { render json: @direct_labor_worker.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /direct_labor_workers/1
  # PATCH/PUT /direct_labor_workers/1.json
  def update
    respond_to do |format|
      params[:direct_labor_worker]["updated_by"] = current_user.id
      params[:direct_labor_worker]["updated_at"] = DateTime.now()
      if @direct_labor_worker.update(direct_labor_worker_params)
        format.html { redirect_to @direct_labor_worker, notice: "#{@direct_labor_worker.name} was successfully updated." }
        format.json { render :show, status: :ok, location: @direct_labor_worker }
      else
        format.html { render :edit }
        format.json { render json: @direct_labor_worker.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /direct_labor_workers/1
  # DELETE /direct_labor_workers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to direct_labor_workers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_direct_labor_worker
      @direct_labor_worker = DirectLaborWorker.find_by(:id=> params[:id])
      if @direct_labor_worker.blank?
        respond_to do |format|
          format.html { redirect_to direct_labor_workers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def direct_labor_worker_params
      params.require(:direct_labor_worker).permit(:name, :created_by, :created_at, :updated_at, :updated_by)
    end
end
