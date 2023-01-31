class ProofCashExpenditureOpenPrintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_proof_cash_expenditure_open_print, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]

  # GET /proof_cash_expenditure_open_prints
  # GET /proof_cash_expenditure_open_prints.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    proof_cash_expenditure_open_prints = ProofCashExpenditureOpenPrint.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number']] 
      @option_filter_records = proof_cash_expenditure_open_prints

      if params[:filter_column].present?
       proof_cash_expenditure_open_prints = proof_cash_expenditure_open_prints.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    logger.info "==========================="
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @proof_cash_expenditure_open_prints = pagy(proof_cash_expenditure_open_prints, page: params[:page], items: pagy_items)
  end

  # GET /proof_cash_expenditure_open_prints/1
  # GET /proof_cash_expenditure_open_prints/1.json
  def show
  end

  # GET /proof_cash_expenditure_open_prints/new
  def new
    @proof_cash_expenditure_open_print = ProofCashExpenditureOpenPrint.new
  end

  # GET /proof_cash_expenditure_open_prints/1/edit
  def edit
  end


  # POST /proof_cash_expenditure_open_prints
  # POST /proof_cash_expenditure_open_prints.json
  def create
    params[:proof_cash_expenditure_open_print]["company_profile_id"] = current_user.company_profile_id
    params[:proof_cash_expenditure_open_print]["created_by"] = current_user.id
    params[:proof_cash_expenditure_open_print]["created_at"] = DateTime.now()
    params[:proof_cash_expenditure_open_print]["date"] = DateTime.now()
    @proof_cash_expenditure_open_print = ProofCashExpenditureOpenPrint.new(proof_cash_expenditure_open_print_params)

    respond_to do |format|
      if @proof_cash_expenditure_open_print.save
        format.html { redirect_to @proof_cash_expenditure_open_print, notice: 'Routine Cost Payment was successfully created.' }
        format.json { render :show, status: :created, location: @proof_cash_expenditure_open_print }
      else
        format.html { render :new }
        format.json { render json: @proof_cash_expenditure_open_print.errors, status: :unprocessable_entity }
      end
      logger.info @proof_cash_expenditure_open_print.errors
    end
  end

  def update
    params[:proof_cash_expenditure_open_print]["company_profile_id"] = current_user.company_profile_id
    params[:proof_cash_expenditure_open_print]["created_by"] = current_user.id
    params[:proof_cash_expenditure_open_print]["created_at"] = DateTime.now()
    params[:proof_cash_expenditure_open_print]["date"] = DateTime.now()

    respond_to do |format|
      if @proof_cash_expenditure_open_print.update(proof_cash_expenditure_open_print_params)  
        format.html { redirect_to proof_cash_expenditure_open_print_path(:id=> @proof_cash_expenditure_open_print.id), notice: "successfully Updated" }
        format.json { render :show, status: :created, location: @proof_cash_expenditure_open_print }     
      else
        format.html { render :edit }
        format.json { render json: @proof_cash_expenditure_open_print.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve    
    case params[:status]
    when 'approve1'
      logger.info "==================================================================="
      @proof_cash_expenditure_open_print.update_columns({:status=> 'approved3', :approved_by=> current_user.id, :approved_at=> DateTime.now()}) 
      @proof_cash_expenditure_open_print.proof_cash_expenditure.update_columns({:printed_by=> nil, :printed_at=> nil})

      logger.info "==================================================================="
    end


      logger.info "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    respond_to do |format|
      format.html { redirect_to proof_cash_expenditure_open_print_path(:id=> @proof_cash_expenditure_open_print.id), notice: "Routine Cost was successfully #{@proof_cash_expenditure_open_print.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /proof_cash_expenditure_open_prints/1
  # DELETE /proof_cash_expenditure_open_prints/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to proof_cash_expenditure_open_prints_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status
    # if @proof_cash_expenditure_open_print.status == 'approved3'
    #   respond_to do |format|
    #     format.html { redirect_to @proof_cash_expenditure_open_print, notice: 'Cannot be edited because it has been approved' }
    #     format.json { render :show, status: :created, location: @proof_cash_expenditure_open_print }
    #   end
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_proof_cash_expenditure_open_print
      @proof_cash_expenditure_open_print = ProofCashExpenditureOpenPrint.find_by(:id=> params[:id])
      if @proof_cash_expenditure_open_print.present?
      else
        respond_to do |format|
          format.html { redirect_to proof_cash_expenditure_open_prints_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @proof_cash_expenditure_open_prints = ProofCashExpenditureOpenPrint.where(:company_profile_id=> current_user.company_profile_id)
      @proof_cash_expenditure = ProofCashExpenditure.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def proof_cash_expenditure_open_print_params
      params.require(:proof_cash_expenditure_open_print).permit(
        :company_profile_id, 
        :proof_cash_expenditure_id, 
        :description, 
        :status, 
        :date,
        :created_by, 
        :created_at, 
        :updated_by, 
        :updated_at)
    end
end
