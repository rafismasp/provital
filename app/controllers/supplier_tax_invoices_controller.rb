class SupplierTaxInvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_supplier_tax_invoice, only: [:show, :edit, :update, :destroy, :approve, :print]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /supplier_tax_invoices
  # GET /supplier_tax_invoices.json
  def index

    select_year = (params[:periode].present? ? params[:periode].first(4) : DateTime.now().strftime("%Y"))
    select_month = (params[:periode].present? ? params[:periode].last(2) : DateTime.now().strftime("%m"))
    session[:periode] = "#{select_year}#{select_month}"

    supplier_tax_invoices = SupplierTaxInvoice.where(:company_profile_id=> current_user.company_profile_id, :periode=> session[:periode])

    # filter select - begin
      @option_filters = [['FP Number','number'],['Supplier Name', 'supplier_id']] 
      @option_filter_records = supplier_tax_invoices
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        end

        supplier_tax_invoices = supplier_tax_invoices.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @supplier_tax_invoices = supplier_tax_invoices

    @currency  = Currency.find_by(:id=> params[:select_currency_id]) if params[:select_currency_id].present?
    case params[:partial]
    when 'change_fp_number'
      @invoice_suppliers = InvoiceSupplier.where(:fp_number=> params[:fp_number])
    end
  end

  # GET /supplier_tax_invoices/1
  # GET /supplier_tax_invoices/1.json
  def show
  end

  # GET /supplier_tax_invoices/new
  def new
    @supplier_tax_invoice = SupplierTaxInvoice.new
  end

  # GET /supplier_tax_invoices/1/edit
  def edit
  end

  # POST /supplier_tax_invoices
  # POST /supplier_tax_invoices.json
  def create
    params[:supplier_tax_invoice]["company_profile_id"] = current_user.company_profile_id
    params[:supplier_tax_invoice]["created_by"] = current_user.id
    params[:supplier_tax_invoice]["created_at"] = DateTime.now()
    params[:supplier_tax_invoice]["periode"] = params[:supplier_tax_invoice]["date"].to_date.strftime("%Y%m")
    if params[:supplier_tax_invoice]["checked"].to_i == 1
      params[:supplier_tax_invoice]["checked_by"] = current_user.id
      params[:supplier_tax_invoice]["checked_at"] = DateTime.now()
    end
    @supplier_tax_invoice = SupplierTaxInvoice.new(supplier_tax_invoice_params)

    respond_to do |format|
      if @supplier_tax_invoice.save
        set_tax_invoice(params[:supplier_tax_invoice]["number"], @supplier_tax_invoice.id)

        format.html { redirect_to @supplier_tax_invoice, notice: "#{@supplier_tax_invoice.number} was successfully created." }
        format.json { render :show, status: :created, location: @supplier_tax_invoice }
      else
        format.html { render :new }
        format.json { render json: @supplier_tax_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /supplier_tax_invoices/1
  # PATCH/PUT /supplier_tax_invoices/1.json
  def update
    respond_to do |format|
      params[:supplier_tax_invoice]["updated_by"] = current_user.id
      params[:supplier_tax_invoice]["updated_at"] = DateTime.now()
      params[:supplier_tax_invoice]["periode"] = params[:supplier_tax_invoice]["date"].to_date.strftime("%Y%m")
      if @supplier_tax_invoice.update(supplier_tax_invoice_params)     

        clear_tax_invoice(params[:supplier_tax_invoice]["number"], @supplier_tax_invoice.id)
        set_tax_invoice(params[:supplier_tax_invoice]["number"], @supplier_tax_invoice.id)

        format.html { redirect_to @supplier_tax_invoice, notice: 'SupplierTaxInvoice was successfully updated.' }
        format.json { render :show, status: :ok, location: @supplier_tax_invoice }
      else
        format.html { render :edit }
        format.json { render json: @supplier_tax_invoice.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def export
    template_report(controller_name, current_user.id, nil)
  end
  
  def approve
    case params[:status]
    when 'approve1'
      @supplier_tax_invoice.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @supplier_tax_invoice.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @supplier_tax_invoice.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @supplier_tax_invoice.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @supplier_tax_invoice.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @supplier_tax_invoice.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to supplier_tax_invoice_path(:id=> @supplier_tax_invoice.id), notice: "Supplier Tax Invoice was successfully #{@supplier_tax_invoice.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /supplier_tax_invoices/1
  # DELETE /supplier_tax_invoices/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to supplier_tax_invoices_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_supplier_tax_invoice
      @supplier_tax_invoice = SupplierTaxInvoice.find_by(:id=> params[:id])
      @invoice_suppliers = InvoiceSupplier.where(:supplier_tax_invoice_id=> params[:id])
    end

    def set_instance_variable
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
    end

    # set_tax_invoice(params[:supplier_tax_invoice]["number"], @supplier_tax_invoice.id)
    def set_tax_invoice(fp_number, supplier_tax_invoice_id)
      dpptotal = 0
      ppntotal = 0

      InvoiceSupplier.where(:fp_number=> fp_number).each do |invoice|
        invoice.update_columns(:supplier_tax_invoice_id=> supplier_tax_invoice_id) if supplier_tax_invoice_id.present?
        dpptotal += invoice.subtotal.to_f
        ppntotal += invoice.ppntotal.to_f
      end
      supplier_tax_invoice = SupplierTaxInvoice.find_by(:id=> supplier_tax_invoice_id)
      supplier_tax_invoice.update_columns({:dpptotal=> dpptotal, :ppntotal=> ppntotal})
    end
    def clear_tax_invoice(fp_number, supplier_tax_invoice_id)
      dpptotal = 0
      ppntotal = 0

      InvoiceSupplier.where(:fp_number=> fp_number).each do |invoice|
        invoice.update_columns(:supplier_tax_invoice_id=> nil)
      end

      supplier_tax_invoice = SupplierTaxInvoice.find_by(:id=> supplier_tax_invoice_id)
      supplier_tax_invoice.update_columns({:dpptotal=> dpptotal, :ppntotal=> ppntotal})
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def supplier_tax_invoice_params
      params.require(:supplier_tax_invoice).permit(:company_profile_id, :supplier_id, :number, :date, :periode, :remarks, :checked, :checked_by, :checked_at, :created_at, :created_by, :updated_at, :updated_by)
    end
end
