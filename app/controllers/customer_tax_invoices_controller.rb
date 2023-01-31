class CustomerTaxInvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_customer_tax_invoice, only: [:show, :edit, :update, :destroy, :approve, :print]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /customer_tax_invoices
  # GET /customer_tax_invoices.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    
    customer_tax_invoices = CustomerTaxInvoice.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")

    # filter select - begin
      @option_filters = [['FP Number','number'],['Customer Name', 'customer_id']] 
      @option_filter_records = customer_tax_invoices
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        end

        customer_tax_invoices = customer_tax_invoices.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @customer_tax_invoices = customer_tax_invoices

    @currency  = Currency.find_by(:id=> params[:select_currency_id]) if params[:select_currency_id].present?
    case params[:partial]
    when 'load_invoice_customer'
      @invoice_customers = @invoice_customer_unused.where(:id=> params[:invoice_customer_id])
      @invoice_customer_items = InvoiceCustomerItem.where(:status=> 'active').includes(:invoice_customer).where(:invoice_customers => {:status=> 'approved3', :company_profile_id => current_user.company_profile_id, :id=> @invoice_customers }).order("invoice_customers.number desc")
      @delivery_order_items = DeliveryOrderItem.where(:status=> 'active').includes(:delivery_order).where(:delivery_orders => {:status=> 'approved3', :company_profile_id => current_user.company_profile_id, :invoice_customer_id=> @invoice_customers }).order("delivery_orders.number desc")
      
    when 'change_customer'
      @invoice_customer_unused = @invoice_customer_unused.where(:customer_id=> params[:customer_id])
    end
  end

  # GET /customer_tax_invoices/1
  # GET /customer_tax_invoices/1.json
  def show
  end

  # GET /customer_tax_invoices/new
  def new
    @customer_tax_invoice = CustomerTaxInvoice.new
  end

  # GET /customer_tax_invoices/1/edit
  def edit
  end

  # POST /customer_tax_invoices
  # POST /customer_tax_invoices.json
  def create
    params[:customer_tax_invoice]["company_profile_id"] = current_user.company_profile_id
    params[:customer_tax_invoice]["created_by"] = current_user.id
    params[:customer_tax_invoice]["created_at"] = DateTime.now()
    params[:customer_tax_invoice]["periode"] = params[:customer_tax_invoice]["date"].to_date.strftime("%Y%m")
    if params[:customer_tax_invoice]["checked"].to_i == 1
      params[:customer_tax_invoice]["checked_by"] = current_user.id
      params[:customer_tax_invoice]["checked_at"] = DateTime.now()
    end
    @customer_tax_invoice = CustomerTaxInvoice.new(customer_tax_invoice_params)

    respond_to do |format|
      if @customer_tax_invoice.save
        set_tax_invoice(params[:invoice_customer], @customer_tax_invoice.id)

        format.html { redirect_to @customer_tax_invoice, notice: "#{@customer_tax_invoice.number} was successfully created." }
        format.json { render :show, status: :created, location: @customer_tax_invoice }
      else
        format.html { render :new }
        format.json { render json: @customer_tax_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customer_tax_invoices/1
  # PATCH/PUT /customer_tax_invoices/1.json
  def update
    respond_to do |format|
      params[:customer_tax_invoice]["updated_by"] = current_user.id
      params[:customer_tax_invoice]["updated_at"] = DateTime.now()
      params[:customer_tax_invoice]["periode"] = params[:customer_tax_invoice]["date"].to_date.strftime("%Y%m")
      if @customer_tax_invoice.update(customer_tax_invoice_params)     

        clear_tax_invoice(@customer_tax_invoice.id)
        set_tax_invoice(params[:invoice_customer], @customer_tax_invoice.id)

        format.html { redirect_to @customer_tax_invoice, notice: 'CustomerTaxInvoice was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer_tax_invoice }
      else
        format.html { render :edit }
        format.json { render json: @customer_tax_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @customer_tax_invoice.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @customer_tax_invoice.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @customer_tax_invoice.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @customer_tax_invoice.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @customer_tax_invoice.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @customer_tax_invoice.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to customer_tax_invoice_path(:id=> @customer_tax_invoice.id), notice: "Customer Tax Invoice was successfully #{@customer_tax_invoice.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /customer_tax_invoices/1
  # DELETE /customer_tax_invoices/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to customer_tax_invoices_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer_tax_invoice
      @customer_tax_invoice = CustomerTaxInvoice.find_by(:id=> params[:id])
      @invoice_customers = InvoiceCustomer.where(:customer_tax_invoice_id=> params[:id])
      @invoice_customer_items = InvoiceCustomerItem.where(:status=> 'active').includes(:invoice_customer).where(:invoice_customers => {:status=> 'approved3', :company_profile_id => current_user.company_profile_id, :customer_tax_invoice_id=> params[:id] }).order("invoice_customers.number desc")
      @delivery_order_items = DeliveryOrderItem.where(:status=> 'active').includes(:delivery_order).where(:delivery_orders => {:status=> 'approved3', :company_profile_id => current_user.company_profile_id, :invoice_customer_id=> @invoice_customers }).order("delivery_orders.number desc")
      
    end

    def set_instance_variable
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @invoice_customer_unused = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id).tax_unused
    end

    # set_tax_invoice(params[:customer_tax_invoice]["number"], @customer_tax_invoice.id)
    def set_tax_invoice(customer_invoices, customer_tax_invoice_id)
      customer_tax_invoice = CustomerTaxInvoice.find_by(:id=> customer_tax_invoice_id)
      if customer_tax_invoice.present?
        customer_invoices.each do |key,value|
          InvoiceCustomer.find_by(:id=> key['invoice_customer_id']).update({:customer_tax_invoice_id=> customer_tax_invoice_id})
        end if customer_invoices.present?
        invoice_customers = InvoiceCustomer.where(:customer_tax_invoice_id=> customer_tax_invoice_id, :status=> 'approved3')
        if invoice_customers.present?
          sum_subtotal = invoice_customers.sum(:subtotal)
          sum_ppntotal = invoice_customers.sum(:ppntotal)
          sum_amount   = sum_subtotal.to_f+sum_ppntotal.to_f
          customer_tax_invoice.update_columns({
            :subtotal=> sum_subtotal,
            :ppntotal=> sum_ppntotal,
            :amount=> sum_amount
          })
        end
      end
    end
    def clear_tax_invoice(customer_tax_invoice_id)
      InvoiceCustomer.where(:customer_tax_invoice_id=> customer_tax_invoice_id).each do |invoice|
        invoice.update_columns({:customer_tax_invoice_id=> nil})
      end if customer_tax_invoice_id.present?
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_tax_invoice_params
      params.require(:customer_tax_invoice).permit(:company_profile_id, :customer_id, :number, :date, :city, :remarks, :checked, :checked_by, :checked_at, :created_at, :created_by, :updated_at, :updated_by)
    end
end
