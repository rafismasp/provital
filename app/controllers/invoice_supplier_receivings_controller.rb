class InvoiceSupplierReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_invoice_supplier_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /invoice_supplier_receivings
  # GET /invoice_supplier_receivings.json
  def index
    invoice_supplier_receivings = InvoiceSupplierReceivingItem.where(:status=> 'active').where("invoice_date between ? and ?", session[:date_begin], session[:date_end]).includes(:invoice_supplier_receiving).where(:invoice_supplier_receivings => {:status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'], :company_profile_id => current_user.company_profile_id })
    .includes(invoice_supplier_receiving: [:supplier])
    .order("invoice_supplier_receivings.number desc")

    # filter select - begin
      @option_filters = [['Inv.Number','number'],['Inv.Status','status'], ['Supplier Name', 'supplier_id'], ['PO Supplier', 'purchase_order_supplier_id'] ] 
      @option_filter_records = @delivery_orders
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:currency).order("name asc")
        when 'purchase_order_supplier_id'
          @option_filter_records = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').order("number asc")
        end

        case params[:filter_column] 
        when 'supplier_id'
          invoice_supplier_receivings = invoice_supplier_receivings.where("invoice_supplier_receivings.supplier_id = ?", params[:filter_value])
        else
          invoice_supplier_receivings = invoice_supplier_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
        end
      end
    # filter select - end
    @invoice_supplier_receivings = invoice_supplier_receivings

  end

  # GET /invoice_supplier_receivings/1
  # GET /invoice_supplier_receivings/1.json
  def show
  end

  # GET /invoice_supplier_receivings/new
  def new
    @invoice_supplier_receiving = InvoiceSupplierReceiving.new
  end

  # GET /invoice_supplier_receivings/1/edit
  def edit
  end

  # POST /invoice_supplier_receivings
  # POST /invoice_supplier_receivings.json
  def create
    params[:invoice_supplier_receiving]["company_profile_id"] = current_user.company_profile_id
    params[:invoice_supplier_receiving]["created_by"] = current_user.id
    params[:invoice_supplier_receiving]["created_at"] = DateTime.now()
    params[:invoice_supplier_receiving]["number"] = document_number(controller_name, params[:invoice_supplier_receiving]["date"].to_date, nil, nil, nil)
    @invoice_supplier_receiving = InvoiceSupplierReceiving.new(invoice_supplier_receiving_params)

    respond_to do |format|
      if @invoice_supplier_receiving.save

        params[:new_record_item].each do |item|
          tax_rate = TaxRate.find_by(:id=> item["tax_rate_id"])
          if tax_rate.present?
            tax_rate_currency_value = tax_rate.currency_value
          else
            tax_rate_currency_value = 0
          end
          isr_record = invoice_supplier_receiving_index_number(@invoice_supplier_receiving.id, item["fp_number"], item["invoice_date"], tax_rate_currency_value, item["currency_id"], item["dpp"], item["remarks"])
          
          invoice_item = InvoiceSupplierReceivingItem.create({
            :invoice_supplier_receiving_id=> @invoice_supplier_receiving.id,
            :index_number=> isr_record[:index_number],
            :supplier_tax_invoice_id=> isr_record[:supplier_tax_invoice_id],
            :erp_system=> (item["erp_system"].present? ? 1 : nil),
            :currency_id=> item["currency_id"],
            :tax_rate_id=> item["tax_rate_id"],
            :invoice_number=> item["invoice_number"],
            :invoice_date=> item["invoice_date"],
            :fp_number=> item["fp_number"],
            :dpp=> item["dpp"],
            :ppn=> item["ppn"],
            :total=> item["total"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          amount_payment = 0
          create_supplier_ap_recap(item["invoice_date"].to_date.strftime("%Y%m"), @invoice_supplier_receiving.supplier, amount_payment, item, isr_record[:supplier_tax_invoice_id], invoice_item.id)
        
        end if params[:new_record_item].present?
        format.html { redirect_to @invoice_supplier_receiving, notice: 'Invoice supplier was successfully created.' }
        format.json { render :show, status: :created, location: @invoice_supplier_receiving }
      else
        format.html { render :new }
        format.json { render json: @invoice_supplier_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invoice_supplier_receivings/1
  # PATCH/PUT /invoice_supplier_receivings/1.json
  def update
    respond_to do |format|
      params[:invoice_supplier_receiving]["updated_by"] = current_user.id
      params[:invoice_supplier_receiving]["updated_at"] = DateTime.now()
      params[:invoice_supplier_receiving]["number"] = @invoice_supplier_receiving.number
      if @invoice_supplier_receiving.update(invoice_supplier_receiving_params)
        params[:new_record_item].each do |item|
          tax_rate = TaxRate.find_by(:id=> item["tax_rate_id"])
          if tax_rate.present?
            tax_rate_currency_value = tax_rate.currency_value
          else
            tax_rate_currency_value = 0
          end
          isr_record = invoice_supplier_receiving_index_number(@invoice_supplier_receiving.id, item["fp_number"], item["invoice_date"], tax_rate_currency_value, item["currency_id"], item["dpp"], item["remarks"])
          invoice_item = InvoiceSupplierReceivingItem.create({
            :invoice_supplier_receiving_id=> @invoice_supplier_receiving.id,
            :index_number=> isr_record[:index_number],
            :supplier_tax_invoice_id=> isr_record[:supplier_tax_invoice_id],
            :erp_system=> (item["erp_system"].present? ? 1 : nil),
            :currency_id=> item["currency_id"],
            :tax_rate_id=> item["tax_rate_id"],
            :invoice_number=> item["invoice_number"],
            :invoice_date=> item["invoice_date"],
            :fp_number=> item["fp_number"],
            :dpp=> item["dpp"],
            :ppn=> item["ppn"],
            :total=> item["total"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          amount_payment = 0
          create_supplier_ap_recap(item["invoice_date"].to_date.strftime("%Y%m"), @invoice_supplier_receiving.supplier, amount_payment, item, isr_record[:supplier_tax_invoice_id], invoice_item.id)
        end if params[:new_record_item].present?

        params[:invoice_supplier_receiving_item].each do |item|
          invoice_item = InvoiceSupplierReceivingItem.find_by(:id=> item["id"])
          if invoice_item.present?
            case item["status"]
            when 'deleted'
              invoice_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })
            else

              supplier_id = @invoice_supplier_receiving.supplier_id
              supplier_tax_invoice = SupplierTaxInvoice.find_by(:company_profile_id=> current_user.company_profile_id, :supplier_id=> supplier_id, :number=> item["fp_number"])

              invoice_item.update_columns({
                :erp_system=> (item["erp_system"].present? ? 1 : nil),
                :supplier_tax_invoice_id=> (supplier_tax_invoice.present? ? supplier_tax_invoice.id : nil),
                :currency_id=> item["currency_id"],
                :tax_rate_id=> item["tax_rate_id"],
                :invoice_number=> item["invoice_number"],
                :invoice_date=> item["invoice_date"],
                :fp_number=> item["fp_number"],
                :dpp=> item["dpp"],
                :ppn=> item["ppn"],
                :total=> item["total"],
                :remarks=> item["remarks"],
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
              amount_payment = 0
              create_supplier_ap_recap(item["invoice_date"].to_date.strftime("%Y%m"), @invoice_supplier_receiving.supplier, amount_payment, item, (supplier_tax_invoice.present? ? supplier_tax_invoice.id : nil), invoice_item.id)
        
            end
          end
        end if params[:invoice_supplier_receiving_item].present?
        format.html { redirect_to @invoice_supplier_receiving, notice: 'Invoice supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @invoice_supplier_receiving }
      else
        format.html { render :edit }
        format.json { render json: @invoice_supplier_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  def print
    respond_to do |format|
      format.html do
        pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>17, :right_margin=>17)
        pdf.font "Helvetica"
        pdf.font_size 9

        header = @invoice_supplier_receiving 
        image_path      = "app/assets/images/logo-bw.png"  
        company         = header.company_profile.name if header.company_profile.present?
        title = header.company_profile.address_row1 if header.company_profile.present?

        supplier_name = (header.supplier.name if header.supplier.present?)
        supplier_address = (header.supplier.address if header.supplier.present?)
        document_name = "DOCUMENT RECEIPT"
        case params[:print_kind]
        when 'print'
          pdf.draw_text ("#{document_name}"), :at => [210,740], :size => 14, :style=> :bold 
          
          pdf.draw_text "Tgl.Terima", :at => [8,725], :size => 10
          pdf.draw_text ":", :at => [90,725], :size => 10
          pdf.draw_text header.date, :at => [100,725], :size => 10

          pdf.draw_text "No.Dokumen", :at => [8,715], :size => 10
          pdf.draw_text ":", :at => [90,715], :size => 10
          pdf.draw_text header.number, :at => [100,715], :size => 10

          pdf.draw_text "Tgl.Jatuh Tempo", :at => [8,705], :size => 10
          pdf.draw_text ":", :at => [90,705], :size => 10
          pdf.draw_text header.due_date, :at => [100,705], :size => 10

          pdf.draw_text "Supplier", :at => [8,695], :size => 10
          pdf.draw_text ":", :at => [90,695], :size => 10
          pdf.draw_text "#{supplier_name}", :at => [100,695], :size => 10

          invoice_check_list = [
              [{:content=> "Invoice Check List", :borders=> [:bottom], :colspan=>2, :padding=> [2, 2, 4, 4]}],
              [{:content=> (header.check_list1.to_i == 1 ? "[ x ]" : "[   ]"), :width=> 25, :padding=> [2, 2, 4, 4]}, {:content=>"Invoice Asli", :width=> 160, :padding=> [2, 2, 4, 4]}],
              [{:content=> (header.check_list2.to_i == 1 ? "[ x ]" : "[   ]"), :padding=> [2, 2, 4, 4]}, {:content=> "Faktur Pajak Asli", :padding=> [2, 2, 4, 4]}],
              [{:content=> (header.check_list3.to_i == 1 ? "[ x ]" : "[   ]"), :padding=> [2, 2, 4, 4]}, {:content=> "Faktur Pajak Copy", :padding=> [2, 2, 4, 4]}],
              [{:content=> (header.check_list4.to_i == 1 ? "[ x ]" : "[   ]"), :padding=> [2, 2, 4, 4]}, {:content=> "Surat Jalan DO Asli", :padding=> [2, 2, 4, 4]}],
              [{:content=> (header.check_list5.to_i == 1 ? "[ x ]" : "[   ]"), :padding=> [2, 2, 4, 4]}, {:content=> "GRN Asli (Jika PO Sistem)", :padding=> [2, 2, 4, 4]}],
              [{:content=> (header.check_list6.to_i == 1 ? "[ x ]" : "[   ]"), :padding=> [2, 2, 4, 4]}, {:content=> "PO Copy", :padding=> [2, 2, 4, 4]}]
            ]

          company_header = [[{:content=> company, :font_style=> :bold, :borders=> [:bottom]}],
                            [{:content=> title, :borders=> [:top], :width=> 200}]
                            ]             
          
          pdf.table([[company_header,"", invoice_check_list
            ] ], :column_widths => [200, 170, 190], :cell_style => {:padding=> 1, :border_color=> "ffffff"})   
          pdf.move_down 10
        
          pdf.table([[
            {:content=> "No"},
            {:content=> "No.Index"},
            {:content=> "No.Invoice"},
            {:content=> "Tgl.Invoice"},
            {:content=> "No.Faktur Pajak"},
            {:content=> "Kurs"},
            {:content=> "Cur"},
            {:content=> "DPP"},
            {:content=> "PPN"},
            {:content=> "Amount"}
            ] ], :column_widths => [20, 50, 86, 60, 80, 36, 25, 70, 57, 70], :cell_style => {:padding=> 2})  
          c = 0
          @invoice_supplier_receiving_items.each do |item|
            c+=1
            pdf.table([[
              c.to_s,
              item.index_number.to_s, 
              item.invoice_number.to_s, 
              item.invoice_date.to_s, 
              {:content=> item.fp_number}, 
              {:content=> number_with_precision( (item.tax_rate.currency_value.to_s if item.tax_rate.present?) , precision: 0, delimiter: ".").to_s,:align=>:right}, 
              {:content=> (item.currency.name if item.currency.present?), :align=> :center},
              {:content=> number_with_precision( item.dpp , precision: 0, delimiter: ".").to_s,:align=>:right}, 
              {:content=> number_with_precision( item.ppn , precision: 0, delimiter: ".").to_s,:align=>:right}, 
              {:content=> number_with_precision( item.total , precision: 0, delimiter: ".").to_s,:align=>:right}
              ] ], :column_widths => [20, 50, 86, 60, 80, 36, 25, 70, 57, 70], :cell_style => {:padding=> 2})    
          end
          pdf.move_down 10
          pdf.table([[
            {:content=> "Delivery by: ", :align=> :center},
            {:content=> "Received by: ", :align=> :center }
            ], [
            {:content=> "", :height=> 50},
            {:content=> "" }
            ], [
            {:content=> "( ...................... )", :align=> :center},
            {:content=> "( ...................... )", :align=> :center}
            ] ], :column_widths => [80, 80], :cell_style => {:padding=> 4})    
          pdf.move_down 10
          pdf.table([["","Print Date:  "+ DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
            :column_widths => [400,  150], :cell_style => {:border_color => "ffffff", :padding=>1}, :header => true)                  
        end
        header.update({:printed_by=> current_user.id, :printed_at=> DateTime.now()})
        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
      end
    end
            
  end

  def approve
    case params[:status]
    when 'approve1'
      @invoice_supplier_receiving.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @invoice_supplier_receiving.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @invoice_supplier_receiving.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @invoice_supplier_receiving.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @invoice_supplier_receiving.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @invoice_supplier_receiving.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to invoice_supplier_receiving_path(:id=> @invoice_supplier_receiving.id), notice: "Invoice Supplier was successfully #{@invoice_supplier_receiving.status}." }
      format.json { head :no_content }
    end
  end

  # DELETE /invoice_supplier_receivings/1
  # DELETE /invoice_supplier_receivings/1.json
  def destroy
    @invoice_supplier_receiving.update_columns({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    respond_to do |format|
      format.html { redirect_to invoice_supplier_receivings_url, notice: 'Invoice supplier was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invoice_supplier_receiving
      @invoice_supplier_receiving = InvoiceSupplierReceiving.find(params[:id])
      @invoice_supplier_receiving_items = InvoiceSupplierReceivingItem.where(:invoice_supplier_receiving_id=> params[:id], :status=> 'active')
    end
    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @material_receivings = MaterialReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
      @tax_rates = TaxRate.where(:status=> "active").where("end_date >= ?", DateTime.now()).order("end_date desc")
      @currencies = Currency.all
    end

    def check_status     
      if @invoice_supplier_receiving.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          respond_to do |format|
            format.html { redirect_to @invoice_supplier_receiving, notice: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @invoice_supplier_receiving }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invoice_supplier_receiving_params
      params.require(:invoice_supplier_receiving).permit(:company_profile_id, :supplier_id, :number, :due_date, :date, :check_list1, :check_list2, :check_list3, :check_list4, :check_list5, :check_list6, :created_by, :created_at, :updated_by, :updated_at)
    end
end
