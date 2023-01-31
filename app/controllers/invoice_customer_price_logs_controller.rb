class InvoiceCustomerPriceLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_invoice_customer_price_log, only: [:show, :edit, :update, :approve, :print]
  before_action :check_status, only: [:edit]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:update] do
    require_permission_approve('approve3')
  end

  # GET /invoice_customer_price_logs
  # GET /invoice_customer_price_logs.json
  def index    
    @invoice_customer_price_logs = InvoiceCustomerPriceLog.where(:company_profile_id=> current_user.company_profile_id, :created_at=> session[:date_begin].to_date.at_beginning_of_day..session[:date_end].to_date.at_end_of_day)
    .includes(:invoice_customer, invoice_customer_item: [:product_batch_number, product: [:product_type, :unit], delivery_order_item: [:delivery_order], sales_order_item: [:sales_order]])
    .order_as_specified(status: ['active','approved','deleted'])
    .order("invoice_customer_price_logs.status asc, invoice_customer_price_logs.created_at desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Customer Name', 'customer_id']] 
      @option_filter_records = @invoice_customer_price_logs
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        when 'sales_order_id'
          @option_filter_records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        when 'delivery_driver_id'
          @option_filter_records = DeliveryDriver.all
        when 'delivery_car_id'
          @option_filter_records = DeliveryCar.all
        end

        @invoice_customer_price_logs = @invoice_customer_price_logs.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
  end

  # GET /invoice_customer_price_logs/1
  # GET /invoice_customer_price_logs/1.json
  def show
  end

  # GET /invoice_customer_price_logs/new
  def new
    @invoice_customer_price_log = InvoiceCustomerPriceLog.new
  end

  # GET /invoice_customer_price_logs/1/edit
  def edit
  end

  # POST /invoice_customer_price_logs
  # POST /invoice_customer_price_logs.json
  def create
  end

  # PATCH/PUT /invoice_customer_price_logs/1
  # PATCH/PUT /invoice_customer_price_logs/1.json
  def update
    
    respond_to do |format|
      params[:data].each do |k, v|
        item_log = InvoiceCustomerPriceLog.find_by(:id=> v["log_id"])
        if item_log.present?
          invoice_item = InvoiceCustomerItem.find_by(:id=> v["invoice_item_id"])
          if invoice_item.present?
            logger.info "Price Change Approved! invoice_item_id: #{invoice_item.id}"
            invoice_item.update({
              :unit_price=> item_log.new_price,
              :total_price=> item_log.new_price.to_f*invoice_item.quantity.to_f,
            })
            invoice_item.invoice_customer.update({
              :updated_at=> DateTime.now(),
              :updated_by=> current_user.id
            }) if invoice_item.invoice_customer.present?
          end
          item_log.update({
            :status=> 'approved',
            :approved_at=> DateTime.now(),
            :approved_by=> current_user.id
          })
        end
      end

      format.html { redirect_to '/invoice_customer_price_logs', notice: 'Invoice customer was successfully updated.' }
      format.json { head :no_content }
      
    end
  end

  def approve
    respond_to do |format|
      format.html { redirect_to invoice_customer_price_logs_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def print
    respond_to do |format|
      format.html { redirect_to invoice_customer_price_logs_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /invoice_customer_price_logs/1
  # DELETE /invoice_customer_price_logs/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to invoice_customer_price_logs_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invoice_customer_price_log
      @invoice_customer_price_log = InvoiceCustomerPriceLog.find(params[:id])
    end

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    
    end


    def check_status      
      noitce_msg = nil 
      if @invoice_customer_price_log.status == 'approved3'
        noitce_msg = 'Cannot be edited because it has been approved'
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @invoice_customer_price_log.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @invoice_customer_price_log, alert: noitce_msg }
          format.json { render :show, status: :created, location: @invoice_customer_price_log }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invoice_customer_price_log_params
      params.require(:invoice_customer_price_log).permit(:customer_id, :company_payment_receiving_id, :company_profile_id, :number, :efaktur_number, :due_date, :date, :subtotal, :discount, :ppntotal, :grandtotal, :remarks, :received_at, :received_name, :created_at, :created_by, :updated_at, :updated_by)
    end
end
