class ListExternalBankAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_list_external_bank_account, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /list_external_bank_accounts
  # GET /list_external_bank_accounts.json
  def index    
    list_external_bank_accounts = ListExternalBankAccount.where(:company_profile_id=> current_user.company_profile_id)
    .includes(:dom_bank, :currency, :created, :updated, :approved1, :voided).order("created_at asc")

    # filter select - begin
      @option_filters = [['Nama Rekening','name_account'],['Currency','currency_id'],['Status','status']] 
      @option_filter_records = list_external_bank_accounts
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        end
        list_external_bank_accounts = list_external_bank_accounts.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @list_external_bank_accounts = pagy(list_external_bank_accounts, page: params[:page], items: pagy_items) 
  end

  # GET /list_external_bank_accounts/1
  # GET /list_external_bank_accounts/1.json
  def show
  end

  # GET /list_external_bank_bank_accounts/new
  def new
    @list_external_bank_account = ListExternalBankAccount.new
  end

  # GET /list_external_bank_aacounts/1/edit
  def edit
  end

  # POST /list_external_bank_accounts
  # POST /list_external_bank_accounts.json
  def create
    params[:list_external_bank_account]["company_profile_id"] = current_user.company_profile_id
    params[:list_external_bank_account]["created_by"] = current_user.id
    params[:list_external_bank_account]["created_at"] = DateTime.now()
    @list_external_bank_account = ListExternalBankAccount.new(list_external_bank_account_params.except(:updated_at, :updated_by))

    respond_to do |format|
      if @list_external_bank_account.save
        format.html { redirect_to list_external_bank_account_path(:id=> @list_external_bank_account.id), notice: "Bank external was successfully created." }
        format.json { render :show, status: :created, location: @list_external_bank_account }
      else
        format.html { render :new }
        format.json { render json: @list_external_bank_account.errors, status: :unprocessable_entity }
      end
      logger.info @list_external_bank_account.errors
    end
  end

  # PATCH/PUT /list_external_bank_accounts/1
  # PATCH/PUT /list_external_bank_accounts/1.json
  def update
    respond_to do |format|
      params[:list_external_bank_account]["updated_by"] = current_user.id
      params[:list_external_bank_account]["updated_at"] = DateTime.now()
      if @list_external_bank_account.update(list_external_bank_account_params.except(:created_at, :created_by))
        format.html { redirect_to @list_external_bank_account, notice: 'Bank external was successfully updated.' }
        format.json { render :show, status: :ok, location: @list_external_bank_account }
      else
        format.html { render :edit }
        format.json { render json: @list_external_bank_account.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    alert = nil
    case params[:status]
    when 'approve1'
      @list_external_bank_account.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @list_external_bank_account.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'void'
      @list_external_bank_account.update_columns({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()})
    end

    respond_to do |format|
      format.html { redirect_to list_external_bank_account_path(:id=> @list_external_bank_account.id), notice: "Bank external was successfully #{@list_external_bank_account.status}." }
      format.json { head :no_content }
    end
  end

  def print
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /list_external_bank_accounts/1
  # DELETE /list_external_bank_accounts/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to list_external_bank_accounts_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_list_external_bank_account
      @list_external_bank_account = ListExternalBankAccount.find_by(:id=> params[:id])
      # if @list_external_bank_account.present?
          
      # else                
      #   respond_to do |format|
      #     format.html { redirect_to list_external_bank_account_url, alert: 'record not found!' }
      #     format.json { head :no_content }
      #   end
      # end
    end

    def set_instance_variable
      @currencies = Currency.all
      @dom_bank   = DomBank.all
    end
    def check_status  
      if @list_external_bank_account.status == 'approved3'   
        if params[:status] == "cancel_approve3"
        else   
          puts "-------------------------------"
          puts  @list_external_bank_account.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @list_external_bank_account, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @list_external_bank_account }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def list_external_bank_account_params
      params.require(:list_external_bank_account).permit(:list_external_bank_account_id, :currency_id, :dom_bank_id, :company_profile_id, :name_account, :number_account, :branch_bank, :address_bank, :created_by, :created_at, :updated_by, :updated_at)
    end
end
