class PaymentCustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_customer, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :set_instance_variable
  before_action :check_status, only: [:edit]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end
  # GET /payment_customers
  # GET /payment_customers.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    payment_customers = PaymentCustomer.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).where(:status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'])
    
    # filter select - begin
      @option_filters = [['Inv.Number','number'],['Inv.Status','status'], ['Customer Name', 'customer_id'], ['PO Customer', 'sales_order_id'] ] 
      @option_filter_records = @delivery_orders
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'sales_order_id'
          @option_filter_records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').order("number asc")
        end

        payment_customers = payment_customers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @payment_customers = payment_customers.order("number desc")
    if params[:customer_id].present?
      case params[:kind]
      when 'proforma'
        @invoice_customers = ProformaInvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> nil).where(:customer_id=> params[:customer_id])
      else
        @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> nil).where(:customer_id=> params[:customer_id])
      end
    end

    if params[:partial] == 'load_invoice_customer'
      @invoice_customer_selected = @invoice_customers.where(:id=> params[:invoice_customer_id])
    end
  end

  # GET /payment_customers/1
  # GET /payment_customers/1.json
  def show
  end

  # GET /payment_customers/new
  def new
    @payment_customer = PaymentCustomer.new
  end

  # GET /payment_customers/1/edit
  def edit
    case @payment_customer.invoice_kind
    when 'proforma'
      @invoice_customers = ProformaInvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> nil).where(:customer_id=> @payment_customer.customer_id)
    else
      @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> nil).where(:customer_id=> @payment_customer.customer_id)
    end
  end

  # POST /payment_customers
  # POST /payment_customers.json
  def create
    params[:payment_customer]["company_profile_id"] = current_user.company_profile_id
    params[:payment_customer]["created_by"] = current_user.id
    params[:payment_customer]["created_at"] = DateTime.now()
    params[:payment_customer]["invoice_kind"] = params[:invoice_kind]
    params[:payment_customer]["status"] = "new"
    @payment_customer = PaymentCustomer.new(payment_customer_params)

    respond_to do |format|
        
      if @payment_customer.save!

        params[:record].each do |record|
          case params[:invoice_kind]
          when 'proforma'
            invoice_customer = ProformaInvoiceCustomer.find_by(:id=> record["proforma_invoice_customer_id"])
          else
            invoice_customer = InvoiceCustomer.find_by(:id=> record["invoice_customer_id"])
          end
          if invoice_customer.present?
            logger.info "invoice exist #{invoice_customer.id}"
            invoice_customer.update_columns({:payment_customer_id=> @payment_customer.id})
          end

        end if params[:record].present?

        format.html { redirect_to payment_customer_path(:id=> @payment_customer.id, :kind=> params[:invoice_kind]), notice: "Payment customer #{@payment_customer.number} was successfully created." }
        format.json { render :show, status: :created, location: @payment_customer }
      else
        @invoice_customers = InvoiceCustomer.where(:id=> params[:record].map { |e| e["invoice_customer_id"] }) if params[:record].present?
  
        format.html { render :new }
        format.json { render json: @payment_customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payment_customers/1
  # PATCH/PUT /payment_customers/1.json
  def update
    respond_to do |format|
      params[:payment_customer]["updated_by"] = current_user.id
      params[:payment_customer]["updated_at"] = DateTime.now()
      params[:record].each do |record|
        case @payment_customer.invoice_kind
        when 'proforma'
          invoice_customer = ProformaInvoiceCustomer.find_by(:id=> record["proforma_invoice_customer_id"])
        else
          invoice_customer = InvoiceCustomer.find_by(:id=> record["invoice_customer_id"])
        end

        if invoice_customer.present?
          case record["status"]
          when 'deleted'
            invoice_customer.update_columns({:payment_customer_id=> nil})
          else
            invoice_customer.update_columns({:payment_customer_id=> @payment_customer.id})
          end
        end
      end if params[:record].present?
      if @payment_customer.update(payment_customer_params)
        format.html { redirect_to payment_customer_path(:id=> @payment_customer.id, :kind=> @payment_customer.invoice_kind), notice: 'Payment customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @payment_customer }
      else
        format.html { render :edit }
        format.json { render json: @payment_customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  def print
    if @payment_customer.status == 'approved3'
      image_path      = "app/assets/images/logo.png" 
      company_ori     = "PT. PROVITAL PERDANA" 
      company         = "PT. PROVITAL PERDANA"
      company_address = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      city            = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      title           = "Jl. Kranji Blok F15 No. 1C,
          Delta Silicon 2, Lippo Cikarang"
      phone_number    = " "
      
      my_company       = CompanyProfile.find_by(:id=> current_user.company_profile_id, :status=> 'active')

      pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10)
      pdf.font "Helvetica"
      pdf.font_size 9

      header = @payment_customer
      case @payment_customer.invoice_kind
      when 'proforma'
        items = ProformaInvoiceCustomer.where(:payment_customer_id=> header.id, :status=> "approved3")
      else
        items = InvoiceCustomer.where(:payment_customer_id=> header.id, :status=> "approved3")
      end

      currency = (header.currency.present? ? header.currency.name.upcase : "-")
      
      if header.status == 'approved3'
        currency == "IDR" ? cur_prec = 2 : cur_prec = 4

        case params[:print_kind]
        when 'print'
          pdf.move_down 115
          pdf.table([["No.", "No.Invoice", "Tgl.Invoice","Due Date", "Subtotal", "PPN", "Amount"]], 
            :column_widths => [25, 110, 65, 65, 100, 90, 120], :cell_style => {:padding => 2, :align=>:center})
          
          c = 1
          items.each do |record|
            y = pdf.y
            pdf.start_new_page if y < 65
            pdf.move_down 115 if y < 65 
            pdf.table([["No.", "No.Invoice", "Tgl.Invoice","Due Date", "Subtotal", "PPN", "Amount"]], 
            :column_widths => [25, 110, 65, 65, 100, 90, 120], :cell_style => {:padding => 2, :align=>:center}) if y < 65 
          
            case @payment_customer.invoice_kind
            when 'proforma'
              pdf.table([[
                {:content=>c.to_s+".", :align=>:right}, 
                record.number.to_s, 
                {:content=> record.date.to_s, :align=> :center}, 
                {:content=> record.due_date.to_s, :align=> :center}, 
                {:content=> number_with_precision(record.total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}, 
                {:content=> number_with_precision(record.ppn_total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right},
                {:content=> number_with_precision(record.grand_total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                ] ], :column_widths => [25, 110, 65, 65, 100, 90, 120], :cell_style => {:padding => 3, :borders=> [:left, :right]})
            else
              pdf.table([[
                {:content=>c.to_s+".", :align=>:right}, 
                record.number.to_s, 
                {:content=> record.date.to_s, :align=> :center}, 
                {:content=> record.due_date.to_s, :align=> :center}, 
                {:content=> number_with_precision(record.subtotal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}, 
                {:content=> number_with_precision(record.ppntotal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right},
                {:content=> number_with_precision(record.grandtotal, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
                ] ], :column_widths => [25, 110, 65, 65, 100, 90, 120], :cell_style => {:padding => 3, :borders=> [:left, :right]})
            end
            c +=1               
          end 
          if pdf.y.to_i < 65
            pdf.start_new_page 
            pdf.move_down 115
          end

          pdf.stroke_horizontal_rule
          case @payment_customer.invoice_kind
          when 'proforma'
            pdf.table([
              [
                {:content=>"Subtotal", :align=>:right, :borders=>[:left, :right]}, 
                {:content=> number_with_precision(items.sum(:total), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}, 
                {:content=> number_with_precision(items.sum(:ppn_total), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right},
                {:content=> number_with_precision(items.sum(:grand_total), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
              ],  [
                {:content=>"Potongan", :align=>:right, :borders=>[:left, :right]}, 
                {:content=> number_with_precision(header.other_cut_cost, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :colspan=>3}
              ],  [
                {:content=>"Grand Total", :align=>:right, :borders=>[:left, :right]}, 
                {:content=> number_with_precision(header.paid, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :colspan=>3}
              ]], :column_widths => [265, 100, 90, 120], :cell_style => {:padding => 3})
          else
            pdf.table([
              [
                {:content=>"Subtotal", :align=>:right, :borders=>[:left, :right]}, 
                {:content=> number_with_precision(items.sum(:subtotal), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}, 
                {:content=> number_with_precision(items.sum(:ppntotal), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right},
                {:content=> number_with_precision(items.sum(:grandtotal), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
              ],  [
                {:content=>"Potongan", :align=>:right, :borders=>[:left, :right]}, 
                {:content=> number_with_precision(header.other_cut_cost, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :colspan=>3}
              ],  [
                {:content=>"Grand Total", :align=>:right, :borders=>[:left, :right]}, 
                {:content=> number_with_precision(header.paid, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :colspan=>3}
              ]], :column_widths => [265, 100, 90, 120], :cell_style => {:padding => 3})
          end
          pdf.stroke_horizontal_rule
           
          pdf.table([
            [{:content=>currency == "IDR" ? "Terbilang :" : "In Words :", :align=>:right, :height=>30, :borders=>[:left, :bottom]},
            {:content=>currency == "IDR" ? "#{number_to_words(header.paid)} rupiah" : number_to_word_eng(header.paid),:borders=>[:right, :bottom]}
            ]], :column_widths => [70, 505], :cell_style => {:padding => 3})
          pdf.move_down 5
          pdf.table([[
              {:content=>"", :borders=>[:right]},{:content=>"Disetujui oleh,", :align=>:center},{:content=>"Dicatat oleh,", :align=>:center},{:content=>"Diterima oleh,", :align=>:center}],[
              {:content=>"", :borders=>[:right]},{:content=>"", :height=>35},{:content=>"", :height=>35},{:content=>"", :height=>35}],[
              {:content=>"", :borders=>[:right]},{:content=>"Dir.Utama / Dir.Keuangan", :align=>:center},{:content=>"Akuntansi", :align=>:center},{:content=>"Finance", :align=>:center}
            ]], :column_widths => [215, 120, 120, 120], :cell_style => {:padding => 3})

      
       
          pdf.move_down 10
          # item end
          # header and footer start
          pdf.page_count.times do |i|
            # Header              
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
              pdf.go_to_page i+1
              pdf.font_size 8
              pdf.move_down 30
              case params[:print_kind]
              when 'print'
                pdf.table([[
                  {:content=>company, :font_style=> :bold},
                  {:content=>"ACCOUNT RECEIVABLE", :font_style=> :bold, :align=>:center},
                   "Print Date",":",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")
                  ],[title,{:content=>"( Payment Received )", :align=>:center},"No.Voucher",":",header.number
                  ]], :column_widths => [160, 250, 50, 10,100], :cell_style => {:border_color => "ffffff", :padding=>1}) 
                pdf.move_down 5
                pdf.stroke_horizontal_rule
                pdf.move_down 5
                pdf.table([
                  [{:content=>"Tgl.Transfer"},":",{:content=>header.date.strftime("%d-%b-%Y").to_s},
                    "Uang sejumlah",":",currency, number_with_precision(header.paid, precision: cur_prec, delimiter: ".", separator: ",")],
                  ["Dari",":", {:content=>"#{header.customer.name if header.customer.present?}"}, "Bank",":",{:content=>"#{(header.bank_transfer.name if header.bank_transfer.present?)}", :colspan=>2}]
                  ],  :column_widths => [50,10, 220, 60,10,50,170], :cell_style => {:border_color => "ffffff", :padding=>1})                  
                pdf.move_down 5
                pdf.stroke_horizontal_rule
              end
            
            }
            # footer
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => 100) {
              pdf.go_to_page i+1
              pdf.move_up 80
              pdf.number_pages "Halaman <page> s/d <total>", :size => 9  
                        
            }
          end 
          header.update({:printed_by=> session[:id], :printed_at=> DateTime.now()})
        end
      else
        'Belum Approve 3'
      end

      pdf.move_down 10
      send_data pdf.render, type: "application/pdf", disposition: "inline"  
    else
      respond_to do |format|
        format.html { redirect_to @payment_customer, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @payment_customer }
      end
    end
  end


  def approve
    case params[:status]
    when 'approve1'
      @payment_customer.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @payment_customer.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @payment_customer.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @payment_customer.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @payment_customer.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @payment_customer.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to payment_customer_path(:id=> @payment_customer.id, :kind=> @payment_customer.invoice_kind), notice: "Invoice Customer was successfully #{@payment_customer.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /payment_customers/1
  # DELETE /payment_customers/1.json
  def destroy
    set_number = "#{@payment_customer.number}-#{@payment_customer.id}-DELETE"
    @payment_customer.update_columns({:number=> set_number, :status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    case @payment_customer.invoice_kind
    when 'proforma'
      ProformaInvoiceCustomer.where(:payment_customer_id=> @payment_customer.id).each do |invoice_customer|
        invoice_customer.update_columns(:payment_customer_id=> nil)
      end
    else
      InvoiceCustomer.where(:payment_customer_id=> @payment_customer.id).each do |invoice_customer|
        invoice_customer.update_columns(:payment_customer_id=> nil)
      end
    end

    respond_to do |format|
      format.html { redirect_to payment_customers_url, notice: 'Payment Request Customer was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment_customer
      @payment_customer = PaymentCustomer.find_by(:id=> params[:id])

      if @payment_customer.present?
        @invoice_customer_by_payments = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> @payment_customer.id)

        case @payment_customer.invoice_kind
        when 'proforma'
          @invoice_customer_by_payments = ProformaInvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> @payment_customer.id)
        else
          @invoice_customer_by_payments = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :payment_customer_id=> @payment_customer.id)
        end
      else
        respond_to do |format|
          format.html { redirect_to payment_customers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @bank_transfers = BankTransfer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')

      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
    end

    def check_status      
      noitce_msg = nil 

      if @payment_customer.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          noitce_msg = 'Cannot be edited because it has been approved'
        end
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @payment_customer.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @payment_customer, alert: noitce_msg }
          format.json { render :show, status: :created, location: @payment_customer }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def payment_customer_params      
      params[:payment_customer]['total_tax']     = params[:payment_customer]['total_tax'].gsub(/[^0-9,]/, '').gsub(/\,/, '.')
      params[:payment_customer]['total_amount']   = params[:payment_customer]['total_amount'].gsub(/[^0-9,]/, '').gsub(/\,/, '.')
      params[:payment_customer]['adm_fee']        = params[:payment_customer]['adm_fee'].gsub(/[^0-9,]/, '').gsub(/\,/, '.')
      params[:payment_customer]['other_cut_cost'] = params[:payment_customer]['other_cut_cost'].gsub(/[^0-9,]/, '').gsub(/\,/, '.')
      params[:payment_customer]['paid']           = params[:payment_customer]['paid'].gsub(/[^0-9,]/, '').gsub(/\,/, '.')
      params.require(:payment_customer).permit(:company_profile_id, :status, :number, :invoice_kind, :customer_id, :currency_id, :date, :bank_transfer_id, :total_tax, :total_amount, :adm_fee, :other_cut_cost, :paid, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end
end
