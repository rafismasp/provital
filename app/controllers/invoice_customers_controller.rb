class InvoiceCustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_invoice_customer, only: [:show, :edit, :update, :approve, :print]
  before_action :check_status, only: [:edit]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /invoice_customers
  # GET /invoice_customers.json
  def index    
    @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Customer Name', 'customer_id']] 
      @option_filter_records = @invoice_customers
      
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

        @invoice_customers = @invoice_customers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:partial]
    when "change_customer"
      delivery_orders = DeliveryOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> "approved3", :customer_id=> params[:customer_id]).where(:invoice_customer_id=> nil)
      @delivery_order_items = DeliveryOrderItem.where(:delivery_order_id=> delivery_orders, :status=> 'active')
    end
  end

  # GET /invoice_customers/1
  # GET /invoice_customers/1.json
  def show
    case params[:status]
    when 'load'
      @invoice_customer.invoice_customer_items.each do |item|
        if item.delivery_order_item.present?
          if item.delivery_order_item.status == 'active'
            if item.delivery_order_item.delivery_order.status == 'deleted'
              item.update({:status=> 'deleted', :updated_at=> DateTime.now(), :updated_by=> current_user.id})
            else
              if item.delivery_order_item.delivery_order.invoice_customer_id.to_i == @invoice_customer.id.to_i
                item.update({:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> current_user.id})
              end
            end
          end
        end
      end
      @invoice_customer.update({:updated_at=> DateTime.now(), :updated_by=> current_user.id})
      logger.info "#{@invoice_customer.subtotal}; ppn: #{@invoice_customer.ppntotal}"
    end
  end

  # GET /invoice_customers/new
  def new
    @invoice_customer = InvoiceCustomer.new
  end

  # GET /invoice_customers/1/edit
  def edit
  end

  # POST /invoice_customers
  # POST /invoice_customers.json
  def create
    params[:invoice_customer]["company_profile_id"] = current_user.company_profile_id
    params[:invoice_customer]["created_by"] = current_user.id
    params[:invoice_customer]["created_at"] = DateTime.now()
    params[:invoice_customer]["number"] = document_number(controller_name, DateTime.now(), nil, nil, nil)
    @invoice_customer = InvoiceCustomer.new(invoice_customer_params)

    respond_to do |format|
      if @invoice_customer.save
        format.html { redirect_to @invoice_customer, notice: 'Invoice customer was successfully created.' }
        format.json { render :show, status: :created, location: @invoice_customer }
      else
        format.html { render :new }
        format.json { render json: @invoice_customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invoice_customers/1
  # PATCH/PUT /invoice_customers/1.json
  def update
    respond_to do |format|
      params[:invoice_customer]["updated_by"] = current_user.id
      params[:invoice_customer]["updated_at"] = DateTime.now()
      params[:invoice_customer]["number"] = @invoice_customer.number
      params[:invoice_customer_item].each do |item|
        invoice_item = InvoiceCustomerItem.find_by(:id=> item["id"])
        case item["status"]
        when 'deleted'
          invoice_item.update_columns({
            :status=> item["status"],
            :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
          })
        else
          # 20210715: aden: req pak johnny: bisa diubah jika harga lebih besar dari harga sebelumnya
          if item["unit_price"].to_f > invoice_item.unit_price.to_f
            invoice_item.update_columns({
              :unit_price=> item["unit_price"],
              :total_price=> item["unit_price"].to_f*invoice_item.quantity.to_f,
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          elsif item["unit_price"].to_f < invoice_item.unit_price.to_f
            price_log = InvoiceCustomerPriceLog.find_by({
              :company_profile_id=> @invoice_customer.company_profile_id,
              :invoice_customer_id=> @invoice_customer.id,
              :invoice_customer_item_id=> invoice_item.id,
              :status=> 'active'
            })
            if price_log.present?
              price_log.update({:status=> 'deleted', :deleted_at=> DateTime.now(), :deleted_by=> current_user.id, :remarks=> "dihapus karena ada pengajuan harga baru"})
            end

            InvoiceCustomerPriceLog.create({
              :company_profile_id=> @invoice_customer.company_profile_id,
              :invoice_customer_id=> @invoice_customer.id,
              :invoice_customer_item_id=> invoice_item.id,
              :old_price=> invoice_item.unit_price,
              :new_price=> item["unit_price"],
              :status=> 'active',
              :created_at=> DateTime.now(), 
              :created_by=> current_user.id
            })
          end
        end if invoice_item.present?
      end if params[:invoice_customer_item].present?
      if @invoice_customer.update(invoice_customer_params)

        format.html { redirect_to @invoice_customer, notice: 'Invoice customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @invoice_customer }
      else
        format.html { render :edit }
        format.json { render json: @invoice_customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    notif_msg = nil
    notif_type = "notice"
    case params[:status]
    when 'approve1'
      @invoice_customer.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @invoice_customer.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @invoice_customer.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @invoice_customer.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @invoice_customer_items.each do |item|
        if item.delivery_order_item.delivery_order.status != 'approved3'
          notif_msg = "#{item.delivery_order_item.delivery_order.number}, This number has not been approved"
          notif_type = "alert"
        end
      end
      if notif_msg.blank?
        @invoice_customer.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})
      end
    when 'cancel_approve3'
      @invoice_customer.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    if notif_msg.blank?
      notif_msg = "Invoice Customer was successfully #{@invoice_customer.status}."
    end
    respond_to do |format|
      format.html { redirect_to invoice_customer_path(:id=> @invoice_customer.id), notif_type.to_sym=> notif_msg }
      format.json { head :no_content }
    end
  end

  def print
    pdf = Prawn::Document.new(:page_size=> "A4", :margin=>10)
    pdf.font "Helvetica"
    pdf.font_size 9

    # HEADER
      my_company       = CompanyProfile.find_by(:id=> current_user.company_profile_id)

      image_path      = "app/assets/images/logo.png"  
      company_ori     = my_company.name
      company         = my_company.name
      company_address1 = my_company.address_row1
      company_address2 = my_company.address_row2
      phone_number    =  my_company.phone_number
    

    # CONTENT
      pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10)
      pdf.font "Helvetica"
      pdf.font_size 9

      header = InvoiceCustomer.find_by(:id=> params[:id], :company_profile_id=> current_user.company_profile_id)
      if header.status == 'approved3'
        currency  = (header.currency.name.to_s if header.currency.present?)
        currency == "IDR" ? cur_prec = 2 : cur_prec = 4
        items     = InvoiceCustomerItem.where(:invoice_customer_id => header.id, :status=> 'active').order("created_at asc")
        tax_value = header.tax.present? ? header.tax.value : nil

        if header.date.to_date.strftime("%Y-%m-%d") < '2022-04-01'
          if tax_value == 0.11
            tax_value = "10"
          end
        else
          # 2022-04-07: tax_value invoice berdasarkan tax PO customer 
          if tax_value == 0.10
            tax_value = "11"
          else
            tax_value = tax_value.to_f * 100
          end
        end

        case params[:print_kind]
        when 'print'
          currency == "IDR" ? cur_prec = 0 : cur_prec = 4
          pdf.move_down 95
          tbl_header = [[
            {content: "NO", rowspan: 2, width: 25, valign: :center },
            {content: "DESCRIPTION", colspan: 2},
            {content: "QUANTITY", rowspan: 2, width: 50, valign: :center},
            {content: "UNIT PRICE", rowspan: 2, width: 70, valign: :center},
            {content: "AMOUNT", rowspan: 2, width: 90, valign: :center}
            ],[
            {content: "PART NAME", width: 240},
            {content: "PART NUMBER", width: 100}]]
          
          delivery_orders  = DeliveryOrder.where(:company_profile_id=> current_user.company_profile_id, :invoice_customer_id=> header.id, :status=> 'approved3')
          pdf.table(tbl_header, cell_style: {align: :center, size: 9, padding: 1})
          c = 1
          InvoiceCustomerItem.where(:invoice_customer_id=> header.id, :status=> 'active').group(:product_id).order("product_id asc").each do |record|
            record_sum = InvoiceCustomerItem.where(:invoice_customer_id=> header.id, :status=> 'active', :product_id=> record.product_id)
            
            y = pdf.y
            pdf.stroke_horizontal_rule if y < 30
            pdf.start_new_page if y < 30
            pdf.move_down 95 if y < 30
            pdf.table(tbl_header, cell_style: {align: :center, size: 9, padding: 1}) if y < 30
            pdf.table([[
              {:content=>c.to_s+".", :align=>:right}, 
              "#{record.product.name.to_s[0..60]} - #{record.product.type_name}", 
              {:content=> record.product.part_id.to_s, :align=>:center}, 
              {:content=> number_with_precision( record_sum.sum(:quantity) , precision: 0, delimiter: ".").to_s,:align=>:right}, # qty DO item
              {:content=> number_with_precision( record.unit_price, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}, 
              {:content=> number_with_precision( record_sum.sum(:total_price), precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right}
              ] ], :column_widths => [25, 240, 100,50, 70, 90], :cell_style => {:padding=>[1,3,1,2], :borders=>[:left,:right]})
            c +=1
          end

          pdf.stroke_horizontal_rule
          

          symbol            = header.currency.symbol.to_s
          subtotal          = header.subtotal
          ppn               = header.ppntotal
          grand_total       = header.grandtotal
          terbilang         = (currency != "IDR" ? number_to_word_eng(grand_total) : number_to_words(grand_total))
          receive_payment   = header.company_payment_receiving
          # CompanyPaymentReceiving.find_by(:company_profile_id=> current_user.company_profile_id, 
          #   :currency_id=> header.currency_id )

          pdf.table([
            [{:content=>"DO :"+(delivery_orders.limit(10).map {|e|[e.number]}.join(", ")+"...").to_s, :rowspan=>2},"SUB TOTAL",currency,{:content=>number_with_precision(subtotal, precision: cur_prec, delimiter: ".", separator: ","),:align=>:right}],
            ["VAT #{tax_value}%",currency, {:content=>number_with_precision(ppn, precision: cur_prec, delimiter: ".", separator: ","),:align=>:right}],
            [{:content=>"Sum Of : "+terbilang.to_s+(currency == "IDR" ? " RUPIAH" : ""), :rowspan=>2, :font_style=> :italic}, "GRAND TOTAL",currency,{:content=>number_with_precision(grand_total, precision: cur_prec, delimiter: ".", separator: ","),:align=>:right} ],
            [{:content=>"PLEASE PAY FULL AMOUNT", :colspan=>3}]
            ], :column_widths => [365,90, 30, 90], :cell_style => {:padding=>[1,3,1,2]})
          
          pdf.move_down 10
          pdf.table([[company_ori,"MAKE ALL PAYABLE TO  :"]], :column_widths=>[300,250], :cell_style => {:border_color => "ffffff",:padding => 1})
          pdf.move_down 13
          pdf.table([["",company_ori],["","A/C : "+receive_payment.bank_account.to_s],["","BANK : "+receive_payment.bank_name.to_s]], :column_widths=>[300,250], :cell_style => {:border_color => "ffffff",:padding => 1})
          pdf.move_down 20
          pdf.table([[receive_payment.signature,"THANK YOU FOR YOUR BUSINESS"]], :column_widths=>[300,250], :cell_style => {:border_color => "ffffff",:padding => 1})
        when 'attachment1','attachment2'
          # attachment2 = sama seperti attachment 1, bedanya menampilkan part number customer bukan internal, dan tidak menampilkan amont per-part
          #  jika Nomor PO tidak tampil maka check ship_do_items pastika mkt_po_id is not null
          # sort = (params[:print_kind] == "attachment1" ? "product_id asc" : "part_name asc, customer_part_number asc, do_date asc")
          
          pdf.move_down 68
          pdf.font_size 6.5
          check_record = nil
          c = 1
          c2 = 2
          grand_total = 0
          invoice_items = InvoiceCustomerItem.where(:invoice_customer_id=> header.id, :status=> 'active')
          invoice_items.group(:product_id).each do |record|
            y = pdf.y
            pdf.stroke_horizontal_rule if y < 50
            pdf.start_new_page if y < 50
            pdf.move_down 68 if y < 50
            sum_quantity = invoice_items.where(:product_id=> record.product_id).sum(:quantity)
            total_price = (sum_quantity.to_f*record.unit_price.to_f)
            case params[:print_kind]
            when "attachment1"
              if check_record == record.product_id                        
                pdf.table([[
                  {:content=> nil, :width=> 20, :borders=>[:left, :right]},
                  {:content=> nil, :width=> 65, :borders=>[:right]},
                  {:content=> nil, :width=> 125, :rowspan=>2, :borders=>[:right]},
                  {:content=> record.sales_order_item.sales_order.po_number.to_s, :width=>60, :borders=>[:right]},
                    {:content=> record.delivery_order_item.delivery_order.number.to_s, :width=>60, :borders=>[:right]},
                    {:content=> record.delivery_order_item.delivery_order.date.strftime("%d-%b-%Y").to_s, :width=>60, :borders=>[:right]},
                    {:content=> number_with_precision(sum_quantity.to_f, precision: 0, delimiter: ".").to_s, :width=>50, :borders=>[:right], :align=>:right},
                    {:content=> number_with_precision(record.unit_price, precision: cur_prec, delimiter: ".", separator: ",").to_s, :width=>60, :borders=>[:right], :align=>:right},
                    {:content=> number_with_precision(total_price, precision: cur_prec, delimiter: ".", separator: ",").to_s, :width=>74, :borders=>[:right], :align=>:right}
                  ]], :cell_style => {:padding => [0,3,0,2]} )
              else
                pdf.table([[
                  {:content=> c.to_s, :width=> 20, :borders=>[:left, :right], :align=>:right},
                  {:content=> record.product.part_id.to_s, :width=> 65, :borders=>[:right]},
                  {:content=> record.product.name.to_s, :width=> 125, :borders=>[:right]},
                  {:content=> record.sales_order_item.sales_order.number.to_s, :width=>60, :borders=>[:right]},
                    {:content=> record.delivery_order_item.delivery_order.number.to_s, :width=>60, :borders=>[:right]},
                    {:content=> record.delivery_order_item.delivery_order.date.strftime("%d-%b-%Y").to_s, :width=>60, :borders=>[:right]},
                    {:content=> number_with_precision(sum_quantity.to_f, precision: 0, delimiter: ".").to_s, :width=>50, :borders=>[:right], :align=>:right},
                    {:content=> number_with_precision(record.unit_price, precision: cur_prec, delimiter: ".", separator: ",").to_s, :width=>60, :borders=>[:right], :align=>:right},
                    {:content=> number_with_precision(total_price, precision: cur_prec, delimiter: ".", separator: ",").to_s, :width=>74, :borders=>[:right], :align=>:right}
                  ]], :cell_style => {:padding => [0,3,0,2]} )

                c+=1
              end
            when "attachment2"
              if check_record == record.product_id                        
                pdf.table([[
                  {:content=> nil, :width=> 20, :borders=>[:left, :right]},
                  {:content=> nil, :width=> 65, :borders=>[:right]},
                  {:content=> nil, :width=> 200, :rowspan=>2, :borders=>[:right]},
                  {:content=> record.sales_order_item.sales_order.po_number.to_s, :width=>60, :borders=>[:right]},
                  {:content=> record.delivery_order_item.delivery_order.number.to_s, :width=>60, :borders=>[:right]},
                  {:content=> record.delivery_order_item.delivery_order.date.strftime("%d-%b-%Y").to_s, :width=>60, :borders=>[:right]},
                  {:content=> number_with_precision(sum_quantity.to_f, precision: 0, delimiter: ".").to_s, :width=>50, :borders=>[:right], :align=>:right},
                  {:content=> nil, :width=>60, :borders=>[:right], :align=>:right}
                ]], :cell_style => {:padding => [0,3,5,2]} )
                
                do_qty_by_part = InvoiceCustomerItem.where(:invoice_customer_id=> header.id, :product_id=> record.product_id).sum(:quantity)
                pdf.table([[
                  {:content=>"", :borders=> [:left, :bottom]},
                  {:content=>"", :borders=> [:bottom, :top]},
                  {:content=>"", :borders=> [:bottom, :top]},
                  {:content=>"Sub-total Qty DO: ", :borders=>[:bottom, :top], :align=> :right}, 
                  {:content=>"#{do_qty_by_part}", :align=> :right, :borders=>[:left, :bottom, :top]},
                  {:content=>"", :borders=> [:right, :bottom, :top]}
                  ]], :column_widths => [285, 60, 60, 60, 50, 60], :cell_style => {:padding => [3,3,3,2]})  
                
                c2+=1
              else                    
                pdf.table([[
                  {:content=> c.to_s, :width=> 20, :borders=>[:left, :right], :align=>:right},
                  {:content=> record.product.part_id.to_s, :width=> 65, :borders=>[:right]},
                  {:content=> record.product.name.to_s, :width=> 200, :borders=>[:right]},
                  {:content=> record.sales_order_item.sales_order.po_number.to_s, :width=>60, :borders=>[:right]},
                    {:content=> record.delivery_order_item.delivery_order.number.to_s, :width=>60, :borders=>[:right]},
                    {:content=> record.delivery_order_item.delivery_order.date.strftime("%d-%b-%Y").to_s, :width=>60, :borders=>[:right]},
                    {:content=> number_with_precision(sum_quantity.to_f, precision: 0, delimiter: ".").to_s, :width=>50, :borders=>[:right], :align=>:right},
                    {:content=> number_with_precision(record.unit_price, precision: cur_prec, delimiter: ".", separator: ",").to_s, :width=>60, :borders=>[:right], :align=>:right}
                  ]], :cell_style => {:padding => [2,3,5,2]} )     
                c2 = 2              
                c+=1
              end 
            end
            check_record = record.product_id
            grand_total += total_price
          end
          pdf.table([
            [
              {:content=>"Grand Total : ", :align=>:right, :borders=>[:bottom], :font_style => :bold},
              {:content=> number_with_precision(grand_total, precision: cur_prec, delimiter: ".", separator: ",").to_s, :align=>:right, :borders=>[:bottom]}
            ]], :column_widths => [500,75], :cell_style => {:padding => 2} )

          pdf.stroke_horizontal_rule

          pdf.font_size 9
        end

        pdf.move_down 10
        # item end
        # header and footer start
        pdf.page_count.times do |i|
          # Header              
          pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width) {
            pdf.go_to_page i+1
            case params[:print_kind]
            when 'print'
              po_number = []
              c_po = 0
              InvoiceCustomerItem.where(:invoice_customer_id=> header.id, :status=> 'active').group(:sales_order_item_id).each do |inv_item|
                po_number.push(inv_item.sales_order_item.sales_order.po_number)
                c_po += 1
              end
              po_number = po_number.uniq.join(", ")
              po_number = (c_po > 1 ? "#{po_number}, Etc." : "#{po_number}")
              
              pdf.table([
                [
                  {:content=>company_ori, :size=>13, :font_style => :bold},
                  "",{:content=>"INVOICE", :size=>14, :font_style => :bold}
                ]], :column_widths => [350, 80, 130], :cell_style => {:border_width => 0, :border_color => "000000",:padding => 0}, :header => true)  
              
              pdf.table([[company_address1],[company_address2],[phone_number]], :cell_style => {:border_width => 0, :border_color => "000000",:padding => 0})
              pdf.move_down 5
              customer = [[{:content=>header.customer.name.to_s, :width=>300, :valign=>"center", :size=>10}]]
              pdf.table([
                [{:content=>"SOLD TO / CUSTOMER", :font_style => :bold},"Invoice Number",":",header.number],
                [{:content=>customer, :rowspan=>2},"Invoice Date",":",header.date.strftime("%d-%b-%Y")],
                ["PO Number",":",po_number]
                ], :column_widths => [320, 90, 10,150], :cell_style => {:border_color => "ffffff", :padding=>1})
            when 'attachment1'  
              pdf.font_size 9                   
              pdf.table([
                    [{:content=>"", :rowspan=>2}, {:content=>"INVOICE LAMPIRAN-1", :align=>:center, :size=>12, :rowspan=>2, :font_style => :bold},{:content=>"Print Date:", :size=>8}],
                    [{:content=> DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S"), :size=>8}]
                    ], :column_widths => [100,370,100], :cell_style => {:border_color => "ffffff", :padding=>2})
              pdf.table([
                ["No.Invoice",":",header.number.to_s, "", "Customer",":",header.customer.name.to_s],
                ["Tgl.Invoice",":",header.date.to_s, "", "Currency",":",(header.currency.name.to_s if header.currency.present?)]
                ], :column_widths => [50,10,100, 10, 50, 10, 340], :cell_style => {:border_color => "ffffff", :padding=>2})
              pdf.font_size 6.5
              pdf.table([
                [ {:content=>"NO"},
                  {:content=>"Product Code"},
                  {:content=>"Product Name"},
                  {:content=>"No.PO"},
                  {:content=>"No.DO"},
                  {:content=>"Tgl.DO"},
                  {:content=>"Qty.DO"},
                  {:content=>"Unit Price"},
                  {:content=>"Amount"}
                ]], :column_widths => [20, 65, 125, 60, 60, 60, 50, 60, 75], :cell_style => {:padding => 2, :align=>:center})
            when 'attachment2'  
              pdf.font_size 9 
              pdf.table([
                [{:content=>"", :rowspan=>2}, {:content=>"INVOICE LAMPIRAN-2", :align=>:center, :size=>12, :rowspan=>2, :font_style => :bold},{:content=>"Print Date:", :size=>8}],
                [{:content=> DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S"), :size=>8}]
                ], :column_widths => [100,370,100], :cell_style => {:border_color => "ffffff", :padding=>2})
              pdf.table([
                ["No.Invoice",":",header.number.to_s, "", "Customer",":",header.customer.name.to_s],
                ["Tgl.Invoice",":",header.date.to_s, "", "","",""]
                ], :column_widths => [50,10,100, 10, 50, 10, 340], :cell_style => {:border_color => "ffffff", :padding=>2})
              pdf.font_size 6.5
              pdf.table([
                [ {:content=>"NO"},
                  {:content=>"Product Code"},
                  {:content=>"Product Name"},
                  {:content=>"No.PO"},
                  {:content=>"No.DO"},
                  {:content=>"Tgl.DO"},
                  {:content=>"Qty.DO"},
                  {:content=>"Price"},
                ]], :column_widths => [20, 65, 200, 60, 60, 60, 50, 60], :cell_style => {:padding => 2, :align=>:center})
            end
          
          }

          pdf.bounding_box([510, pdf.bounds.top], :width => pdf.bounds.width) {
            pdf.go_to_page i+1
            case params[:print_kind]
            when 'print'            
              pdf.number_pages "(page <page> / <total>)"
            end
          }
        end 
        # footer
        if params[:print_kind] != 'print'
          pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => 100) {
            pdf.move_up 80
            pdf.number_pages "Halaman <page> s/d <total>", :size => 9                             
          }
        end
        header.update({:printed_by=> current_user.id, :printed_at=> DateTime.now()})
      else
        pdf.text "Belum approve 3"
      end

    # FOOTER
    pdf.move_down 10
    send_data pdf.render, type: "application/pdf", disposition: "inline"
  
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /invoice_customers/1
  # DELETE /invoice_customers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to invoice_customers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invoice_customer
      @invoice_customer = InvoiceCustomer.find(params[:id])
      @invoice_customer_items = InvoiceCustomerItem.where(:invoice_customer_id=> @invoice_customer.id, :status=> 'active')
      @company_payment_receivings = @company_payment_receivings.where(:currency_id=> @invoice_customer.currency_id)
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
      @company_payment_receivings = CompanyPaymentReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    
    end


    def check_status      
      noitce_msg = nil 
      if @invoice_customer.status == 'approved3'
        noitce_msg = 'Cannot be edited because it has been approved'
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @invoice_customer.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @invoice_customer, alert: noitce_msg }
          format.json { render :show, status: :created, location: @invoice_customer }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invoice_customer_params
      params.require(:invoice_customer).permit(:customer_id, :company_payment_receiving_id, :company_profile_id, :number, :efaktur_number, :due_date, :date, :subtotal, :discount, :ppntotal, :grandtotal, :remarks, :received_at, :received_name, :created_at, :created_by, :updated_at, :updated_by)
    end
end
