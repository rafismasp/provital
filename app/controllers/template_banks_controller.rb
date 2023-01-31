class TemplateBanksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template_bank, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    case params[:status]
    when 'paid','cancel_paid'
    else
      require_permission_approve(params[:status])
    end
  end

  # GET /template_banks
  # GET /template_banks.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    
    # contoh preload
    template_banks = TemplateBank.where(:company_profile_id=> current_user.company_profile_id).where("template_banks.date between ? and ?", session[:date_begin], session[:date_end])
    .includes([:list_internal_bank_account, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Customer Name', 'customer_id'], ['PO Customer', 'sales_order_id'], ['Driver Name', 'vehicle_driver_name'], ['Car', 'vehicle_number']] 
      @option_filter_records = template_banks
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'sales_order_id'
          @option_filter_records = SalesOrder.where(:id=> template_banks.select(:sales_order_id))
        when 'delivery_driver_id'
          @option_filter_records = DeliveryDriver.all
        when 'delivery_car_id'
          @option_filter_records = DeliveryCar.all
        end

        template_banks = template_banks.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      # contoh eager load
      template_banks = TemplateBankItem.where(:status=> 'active')
      .includes([:payment_supplier, :supplier_bank, :voucher_payment])
      .includes(template_bank: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3]).where(:template_banks => {:company_profile_id => current_user.company_profile_id }).where("template_banks.date between ? and ?", session[:date_begin], session[:date_end])
      .order("template_banks.number desc, payment_suppliers.number desc")
    else
      template_banks = template_banks.order("template_banks.number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @template_banks = pagy(template_banks, page: params[:page], items: pagy_items)
  end

  # GET /template_banks/1
  # GET /template_banks/1.json
  def show
  end

  # GET /template_banks/new
  def new
    @template_bank = TemplateBank.new
  end

  # GET /template_banks/1/edit
  def edit
  end

  # POST /template_banks
  # POST /template_banks.json
  def create
    params[:template_bank]["company_profile_id"] = current_user.company_profile_id
    params[:template_bank]["created_by"] = current_user.id
    params[:template_bank]["created_at"] = DateTime.now()
    @template_bank = TemplateBank.new(template_bank_params)

    respond_to do |format|
      if @template_bank.save
        params[:new_record_item].each do |item|
          new_item = TemplateBankItem.new({
            :template_bank_id=> @template_bank.id,
            :payment_supplier_id=> item["payment_supplier_id"], 
            :supplier_bank_id=> item["supplier_bank_id"], 
            :voucher_payment_id=> item["voucher_payment_id"], 
            :by_transfer=> item["by_transfer"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          new_item.save!
          # puts inv_cus_item.inspect
        end if params[:new_record_item].present?

        format.html { redirect_to @template_bank, notice: 'Template Bank was successfully created.' }
        format.json { render :show, status: :created, location: @template_bank }
      else
        format.html { render :new }
        format.json { render json: @template_bank.errors, status: :unprocessable_entity }
      end
      logger.info @template_bank.errors
    end
  end

  # PATCH/PUT /template_banks/1
  # PATCH/PUT /template_banks/1.json
  def update
    params[:template_bank]["updated_by"] = current_user.id
    params[:template_bank]["updated_at"] = DateTime.now()
    params[:template_bank]["date"] = @template_bank.date
    params[:template_bank]["number"] = @template_bank.number
    respond_to do |format|
      TemplateBankItem.where(:template_bank_id=> @template_bank.id, :status=> 'active').each do |item|
        item.update({:status=> 'deleted'})
      end
      params[:new_record_item].each do |item|
        new_item = TemplateBankItem.find_by({
          :template_bank_id=> @template_bank.id,
          :payment_supplier_id=> item["payment_supplier_id"],
          :voucher_payment_id=> item["voucher_payment_id"]
        })
        if new_item.present?
          new_item.update({
            :supplier_bank_id=> item["supplier_bank_id"], 
            :by_transfer=> item["by_transfer"],
            :status=> 'active',
            :updated_at=> DateTime.now(), :updated_by=> current_user.id
          })
        else
          new_item = TemplateBankItem.new({
            :template_bank_id=> @template_bank.id,
            :payment_supplier_id=> item["payment_supplier_id"], 
            :supplier_bank_id=> item["supplier_bank_id"], 
            :voucher_payment_id=> item["voucher_payment_id"], 
            :by_transfer=> item["by_transfer"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          new_item.save!
        end
      end if params[:new_record_item].present?

      params[:template_bank_item].each do |item|
        old_item = TemplateBankItem.find_by(:id=> item["id"])
        case item["status"]
        when 'deleted'
          old_item.update({
            :status=> item["status"],
            :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
          })
        else
          old_item.update({ 
            :supplier_bank_id=> item["supplier_bank_id"], 
            :by_transfer=> item["by_transfer"],
            :status=> "active",
            :updated_at=> DateTime.now(), :updated_by=> current_user.id
          })
        end if old_item.present?
      end if params[:template_bank_item].present?

      if @template_bank.update(template_bank_params)

        format.html { redirect_to @template_bank, notice: 'Template Bank was successfully updated.' }
        format.json { render :show, status: :ok, location: @template_bank }
      else
        format.html { render :edit }
        format.json { render json: @template_bank.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve
    notif_msg = nil
    notif_type = "notice"
    case params[:status]
    when 'approve1'
      @template_bank.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @template_bank.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @template_bank.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @template_bank.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @template_bank.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})
    when 'cancel_approve3'
      @template_bank.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    when 'paid'
      @template_bank.update({:status=> 'paid', :paid_by=> current_user.id, :paid_at=> DateTime.now()})
    when 'cancel_paid'
      @template_bank.update({:status=> 'unpaid', :unpaid_by=> current_user.id, :unpaid_at=> DateTime.now()})
    end

    notif_msg = "Template Bank was successfully #{@template_bank.status}."
    
    respond_to do |format|
      format.html { redirect_to template_bank_path(:id=> @template_bank.id), notif_type.to_sym=> notif_msg}
      format.json { head :no_content }
    end
  end

  def print
    case @template_bank.status
    when 'approved2', 'canceled3', 'approved3', 'unpaid', 'paid'
      sop_number      = "SOP-03C-006"
      form_number     = "F-03C-010-Rev 03"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @template_bank
      items  = @template_bank_items.order("payment_suppliers.grandtotal asc")
      order_number = ""

      document_name = "Template Bank"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :margin=> 10 ) 

          pdf.move_down 65
            tbl_header = [
              [{:content=> "No", width: 20, valign: :center, :font_style => :bold},
              {:content=> "No. Voucher Payment", width: 95, valign: :center, :font_style => :bold},
              {:content=> "Nama", width: 100, valign: :center, :font_style => :bold},
              {:content=> "Nama Bank", width: 100, valign: :center, :font_style => :bold}, #add
              {:content=> "No. Account", width: 65, valign: :center, :font_style => :bold}, #add
              {:content=> "Amount", width: 85, valign: :center, :font_style => :bold},
              {:content=> "Naratif", width: 110, valign: :center, :font_style => :bold}]
            ]
          pdf.table(tbl_header, cell_style: {align: :center, size: 8, padding: 5})
          c = 1
          sum_amount = 0
          items.each do |item|
            # supplier_bank = item.supplier_bank
            # invoice_selected = item.payment_supplier.payment_supplier_items.map { |e| e.invoice_supplier.number if e.invoice_supplier.present? }.uniq

            # pdf.table([[
            #   {:content=>c.to_s+".", :align=>:right}, 
            #   item.payment_supplier.number,
            #   item.payment_supplier.supplier.name,
            #   (supplier_bank.name if supplier_bank.present?),
            #   (supplier_bank.account_number if supplier_bank.present?),
            #   {:content=> number_with_precision( item.payment_supplier.grandtotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
            #   "#{invoice_selected[0..2].join(", ")} #{invoice_selected.count() > 3 ? ', Etc.' : ''}"

            #   ] ], :column_widths => [20, 95, 100, 100, 65, 85, 110], :cell_style => {:padding=> 5, :size=> 8})
            # sum_amount += item.payment_supplier.grandtotal.to_f
            
            # 20220323 - Danny
            if item.payment_supplier
              supplier_bank = item.supplier_bank
              invoice_selected = item.payment_supplier.payment_supplier_items.map { |e| e.invoice_supplier.number if e.invoice_supplier.present? }.uniq
              payment_number = item.payment_supplier.number
              payment_name = item.payment_supplier.supplier.name
              supplier_bank_name = (supplier_bank.name if supplier_bank.present?)
              supplier_bank_number = (supplier_bank.account_number if supplier_bank.present?)
              grandtotal = item.payment_supplier.grandtotal
              naratif = "#{invoice_selected[0..2].join(", ")} #{invoice_selected.count() > 3 ? ', Etc.' : ''}"
              sum_amount += item.payment_supplier.grandtotal.to_f
            else
              payment_number = (item.voucher_payment.number if item.present? and item.voucher_payment.present?)
              payment_name = (item.voucher_payment.list_external_bank_account.name_account if item.voucher_payment.present? and item.voucher_payment.list_external_bank_account.present?)
              supplier_bank_name = (item.voucher_payment.list_external_bank_account.dom_bank.bank_name if item.voucher_payment.list_external_bank_account.present? and item.voucher_payment.list_external_bank_account.dom_bank.present?)
              supplier_bank_number = (item.voucher_payment.list_external_bank_account.number_account if item.voucher_payment.present? and item.voucher_payment.list_external_bank_account.present?)
              grandtotal = (item.voucher_payment.grand_total if item.voucher_payment.present?)
              naratif = ''
              sum_amount += item.voucher_payment.grand_total.to_f
            end

            pdf.table([[
              {:content=>c.to_s+".", :align=>:right}, 
              # item.payment_supplier.number,
              payment_number,
              # item.payment_supplier.supplier.name,
              payment_name,
              # (supplier_bank.name if supplier_bank.present?),
              supplier_bank_name,
              # (supplier_bank.account_number if supplier_bank.present?),
              supplier_bank_number,
              # {:content=> number_with_precision( item.payment_supplier.grandtotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
              {:content=> number_with_precision(grandtotal, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right},
              # "#{invoice_selected[0..2].join(", ")} #{invoice_selected.count() > 3 ? ', Etc.' : ''}"
              naratif

              ] ], :column_widths => [20, 95, 100, 100, 65, 85, 110], :cell_style => {:padding=> 5, :size=> 8})
            # sum_amount += item.payment_supplier.grandtotal.to_f
            
            c +=1
          end
          pdf.font_size 10
          pdf.table([[
            {:content=> "TOTAL", :width=> 380, :align=>:center, :font_style => :bold}, 
            {:content=> number_with_precision( sum_amount, precision: 2, delimiter: ".", separator: ",").to_s, :align=>:right, :width=> 85, :font_style => :bold},
            {:content=> "", :width=> 110}
          ]])

          pdf.move_down 5
            footer_sign  = [
              [{:content=> "Maker", width: 100, :align=> :center}, {:content=> "Checked By", width: 100, :align=> :center}, {:content=> "Approved By", width: 100, :align=> :center}],
              [
                {:content=> "#{header.created.first_name if header.created.present?}", width: 100, :align=> :center}, 
                {:content=> "#{header.approved2.first_name if header.approved2.present?}", width: 100, :align=> :center}, 
                {:content=> "#{header.approved3.first_name if header.approved3.present?}", width: 100, :align=> :center}]
            ]
            pdf.table([["",footer_sign,""]], :column_widths => [271, 300, 0], :cell_style => {:border_width => 0, :border_color => "000000", :padding => 2})
            pdf.page_count.times do |i|
            # Header              
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              pdf.go_to_page i+1
              pdf.move_down 10     
              pdf.table([
                [ {:content=>company_name, :size=>11}],
                [ {:content=> "#{header.number}", :size=>11}],
                [ {:content=> "#{header.list_internal_bank_account.number_account if header.list_internal_bank_account.present?}", :size=>11}],
              ],
              :column_widths => [280, 200, 80], :cell_style => {:background_color => "ffffff", :border_color=> "ffffff", :padding=>1})    
            }   
          end   
          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
          header.update_columns({
            :printed_by=> current_user.id,
            :printed_at=> DateTime.now()
          })
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @template_bank, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @template_bank }
      end
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /template_banks/1
  # DELETE /template_banks/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to template_banks_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_template_bank
      @template_bank = TemplateBank.find_by(:id=> params[:id])
      if @template_bank.present?
        @template_bank_items = TemplateBankItem.where(:status=> 'active').includes(:template_bank, :payment_supplier, :voucher_payment).where(:template_banks => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("template_banks.number desc")
      else
        respond_to do |format|
          format.html { redirect_to finish_good_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def check_status      
      noitce_msg = nil 

      if @template_bank.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          noitce_msg = 'Cannot be edited because it has been approved'
        end
      end

      if noitce_msg.present?
        puts "-------------------------------"
        puts  @template_bank.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @template_bank, alert: noitce_msg }
          format.json { render :show, status: :created, location: @template_bank }
        end
      end
    end

    def set_instance_variable
      @currencies = Currency.all
      @list_internal_bank_accounts = ListInternalBankAccount.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3')

      payment_suppliers = PaymentSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved2').includes(supplier: [:supplier_banks], template_bank_items: [:template_bank])
      payment_supplier_checked   = payment_suppliers.where(:template_banks=> {:id=> params[:id]}).where(:template_bank_items=> {:status=> 'active'})
      payment_supplier_unchecked = payment_suppliers.where(:template_bank_status=> 'N')
      payment_suppliers = payment_suppliers.where(:id=> params[:value])
      # 20220315
      voucher_payments = VoucherPayment.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved2').includes(template_bank_items: [:template_bank])
      voucher_payment_checked   = voucher_payments.where(:template_banks=> {:id=> params[:id]}).where(:template_bank_items=> {:status=> 'active'})
      voucher_payment_unchecked = voucher_payments.where(:template_bank_status=> 'N')
      voucher_payments = voucher_payments.where(:id=> params[:value2])

      @vp_lists = payment_suppliers + voucher_payments
      @vp_check_updated   = payment_supplier_checked +  voucher_payment_checked
      @vp_uncheck_updated = payment_supplier_unchecked + voucher_payment_unchecked

    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def template_bank_params
      params.require(:template_bank).permit(:number, :date, :company_profile_id, :list_internal_bank_account_id, :created_by, :created_at, :updated_by, :updated_at, :grand_total)
    end
end
