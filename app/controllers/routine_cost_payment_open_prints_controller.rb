class RoutineCostPaymentOpenPrintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_routine_cost_payment_open_print, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]

  # GET /routine_cost_payment_open_prints
  # GET /routine_cost_payment_open_prints.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    routine_cost_payment_open_prints = RoutineCostPaymentOpenPrint.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number']] 
      @option_filter_records = routine_cost_payment_open_prints

      if params[:filter_column].present?
       routine_cost_payment_open_prints = routine_cost_payment_open_prints.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    logger.info "==========================="
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @routine_cost_payment_open_prints = pagy(routine_cost_payment_open_prints, page: params[:page], items: pagy_items)
  end

  # GET /routine_cost_payment_open_prints/1
  # GET /routine_cost_payment_open_prints/1.json
  def show
  end

  # GET /routine_cost_payment_open_prints/new
  def new
    @routine_cost_payment_open_print = RoutineCostPaymentOpenPrint.new
  end

  # GET /routine_cost_payment_open_prints/1/edit
  def edit
  end


  # POST /routine_cost_payment_open_prints
  # POST /routine_cost_payment_open_prints.json
  def create
    params[:routine_cost_payment_open_print]["company_profile_id"] = current_user.company_profile_id
    params[:routine_cost_payment_open_print]["created_by"] = current_user.id
    params[:routine_cost_payment_open_print]["created_at"] = DateTime.now()
    params[:routine_cost_payment_open_print]["date"] = DateTime.now()
    @routine_cost_payment_open_print = RoutineCostPaymentOpenPrint.new(routine_cost_payment_open_print_params)

    respond_to do |format|
      if @routine_cost_payment_open_print.save
        format.html { redirect_to @routine_cost_payment_open_print, notice: 'Routine Cost Payment was successfully created.' }
        format.json { render :show, status: :created, location: @routine_cost_payment_open_print }
      else
        format.html { render :new }
        format.json { render json: @routine_cost_payment_open_print.errors, status: :unprocessable_entity }
      end
      logger.info @routine_cost_payment_open_print.errors
    end
  end

  def update
    params[:routine_cost_payment_open_print]["company_profile_id"] = current_user.company_profile_id
    params[:routine_cost_payment_open_print]["created_by"] = current_user.id
    params[:routine_cost_payment_open_print]["created_at"] = DateTime.now()
    params[:routine_cost_payment_open_print]["date"] = DateTime.now()

    respond_to do |format|
      if @routine_cost_payment_open_print.update(routine_cost_payment_open_print_params)  
        format.html { redirect_to routine_cost_payment_open_print_path(:id=> @routine_cost_payment_open_print.id), notice: "successfully Updated" }
        format.json { render :show, status: :created, location: @routine_cost_payment_open_print }     
      else
        format.html { render :edit }
        format.json { render json: @routine_cost_payment_open_print.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve    
    case params[:status]
    when 'approve1'
      logger.info "==================================================================="
      @routine_cost_payment_open_print.update_columns({:status=> 'approved3', :approved_by=> current_user.id, :approved_at=> DateTime.now()}) 
      @routine_cost_payment_open_print.routine_cost_payment.update_columns({:printed_by=> nil, :printed_at=> nil})

      logger.info "==================================================================="
    end


      logger.info "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    respond_to do |format|
      format.html { redirect_to routine_cost_payment_open_print_path(:id=> @routine_cost_payment_open_print.id), notice: "Routine Cost was successfully #{@routine_cost_payment_open_print.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /routine_cost_payment_open_prints/1
  # DELETE /routine_cost_payment_open_prints/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to routine_cost_payment_open_prints_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status
    # if @routine_cost_payment_open_print.status == 'approved3'
    #   respond_to do |format|
    #     format.html { redirect_to @routine_cost_payment_open_print, notice: 'Cannot be edited because it has been approved' }
    #     format.json { render :show, status: :created, location: @routine_cost_payment_open_print }
    #   end
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_routine_cost_payment_open_print
      @routine_cost_payment_open_print = RoutineCostPaymentOpenPrint.find_by(:id=> params[:id])
      if @routine_cost_payment_open_print.present?
      else
        respond_to do |format|
          format.html { redirect_to routine_cost_payment_open_prints_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @routine_cost_payment_open_prints = RoutineCostPaymentOpenPrint.where(:company_profile_id=> current_user.company_profile_id)
      @routine_cost_payment = RoutineCostPayment.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def routine_cost_payment_open_print_params
      params.require(:routine_cost_payment_open_print).permit(
        :company_profile_id, 
        :routine_cost_payment_id, 
        :description, 
        :status, 
        :date,
        :created_by, 
        :created_at, 
        :updated_by, 
        :updated_at)
    end
end
