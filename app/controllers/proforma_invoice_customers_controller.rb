class ProformaInvoiceCustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_proforma_invoice_customer, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /proforma_invoice_customers
  # GET /proforma_invoice_customers.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    proforma_invoice_customers = ProformaInvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id).where("proforma_invoice_customers.date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided).order("created_at desc")

    # filter select - begin
      @option_filters = [['Number','number'],['Customer','customer_id'],['Status','status']] 
      @option_filter_records = proforma_invoice_customers
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'sales_order_id'
          @option_filter_records = proforma_invoice_customer_items.group('sales_order_id')
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        end
        proforma_invoice_customers = proforma_invoice_customers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:partial]
    when 'load_pi_list'
      @sales_orders = @sales_orders.where(:id=>params[:stuff1])
      @sales_order_items = SalesOrderItem.where(:sales_order_id=>params[:stuff1], :status=> 'active').includes(product: [:product_type, :unit])

    when 'change_pi'
      so_exist = []
      proforma_invoice_customer_items = ProformaInvoiceCustomerItem.where(:status=> 'active').group('sales_order_id')
      proforma_invoice_customer_items.each { |e| so_exist << e.sales_order_id}
      @sales_orders = @sales_orders.where(:customer_id=> params[:cs_id])
      @sales_orders = @sales_orders.where.not(:id=>so_exist) if so_exist.present?
      # @sales_order_items = SalesOrderItem.where(:status=> 'active').where.not(:id => (@proforma_invoice_customer_items.each {|e| e.sales_order_item_id}))
      # .includes(:sales_order)
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @proforma_invoice_customers = pagy(proforma_invoice_customers, page: params[:page], items: pagy_items) 
  end

  # GET /proforma_invoice_customers/1
  # GET /proforma_invoice_customers/1.json
  def show
  end

  # GET /proforma_invoice_customers/new
  def new
    @proforma_invoice_customer = ProformaInvoiceCustomer.new

    params[:stuff1] = (params[:stuff1].present? ? params[:stuff1] : [])
    @sales_orders      = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> ['new','approved1','canceled1','approved2','canceled2','canceled3'])
    @sales_order_items = SalesOrderItem.where(:sales_order_id=>params[:stuff1], :status=> 'active')
  end

  # GET /proforma_invoice_customers/1/edit
  def edit
    params[:stuff1] = (params[:stuff1].present? ? params[:stuff1] : [])

    @proforma_invoice_customer_items.each do |item|
      if item.sales_order_id.present?
        params[:stuff1] << item.sales_order_id
      end
    end

    arr = []
    proforma_invoice_customer_items = ProformaInvoiceCustomerItem.where(:status=> 'active').where.not(:proforma_invoice_customer_id => params[:id]).group('sales_order_id')
    proforma_invoice_customer_items.each { |e| arr << e.sales_order_id} 

    current_so_id = @proforma_invoice_customer_items.map { |e| e.sales_order_id }.uniq
    # arr.delete([55,68])

    # logger.info "current_so_id: #{current_so_id}"
    @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> ['new','approved1','canceled1','approved2','canceled2','canceled3'], :customer_id=>@proforma_invoice_customer.customer_id).where.not(:id=>arr)
    @sales_orders += SalesOrder.where(:id=> current_so_id)
    @sales_order_items = SalesOrderItem.where(:sales_order_id=>params[:stuff1], :status=> 'active')
  end

  # POST /proforma_invoice_customers
  # POST /proforma_invoice_customers.json
  def create
    params[:proforma_invoice_customer]["company_profile_id"] = current_user.company_profile_id
    params[:proforma_invoice_customer]["created_by"] = current_user.id
    params[:proforma_invoice_customer]["created_at"] = DateTime.now()
    params[:proforma_invoice_customer]["img_created_signature"] = current_user.signature
    params[:proforma_invoice_customer]["number"] = document_number(controller_name, params[:proforma_invoice_customer]['date'].to_date, nil, nil, nil)
    @proforma_invoice_customer = ProformaInvoiceCustomer.new(proforma_invoice_customer_params.except(:updated_at, :updated_by))

    respond_to do |format|
      if @proforma_invoice_customer.save
        params[:new_record_item].each do |item|
          mf = ProformaInvoiceCustomerItem.create({
            :proforma_invoice_customer_id => @proforma_invoice_customer.id,
            :sales_order_id=> item["sales_order_id"],
            :sales_order_item_id=> item["sales_order_item_id"],
            :amount => item["amount"].gsub(".",""),
            :amountdisc => item["amountdisc"].gsub(".",""),
            :status => 'active',
            :created_at => DateTime.now(), :created_by => current_user.id
          })
          mf.save!
          # test
          # sales_order = SalesOrder.find_by(:id=> item["sales_order_id"])
          # sales_order.update_columns(:proforma_invoice_customer_id=> @proforma_invoice_customer.id) if sales_order.present?
        
        end if params[:new_record_item].present?
        @proforma_invoice_customer.update({:updated_at=> DateTime.now()})
        format.html { redirect_to proforma_invoice_customer_path(:id=> @proforma_invoice_customer.id), notice: "#{@proforma_invoice_customer.number} was successfully created." }
        format.json { render :show, status: :created, location: @proforma_invoice_customer }
      else
        format.html { render :new }
        format.json { render json: @proforma_invoice_customer.errors, status: :unprocessable_entity }
      end
      logger.info @proforma_invoice_customer.errors
    end
  end

  # PATCH/PUT /proforma_invoice_customers/1
  # PATCH/PUT /proforma_invoice_customers/1.json
  def update
    respond_to do |format|
      params[:proforma_invoice_customer]["updated_by"] = current_user.id
      params[:proforma_invoice_customer]["updated_at"] = DateTime.now()
      params[:proforma_invoice_customer]["number"] = @proforma_invoice_customer.number
      params[:proforma_invoice_customer]["date"] = @proforma_invoice_customer.date
      if @proforma_invoice_customer.update(proforma_invoice_customer_params.except(:created_at, :created_by))
        logger.info "update "
        # clear all, jika load tanpa pilih data
        if params[:new_record_item].present?
          ProformaInvoiceCustomerItem.where(:proforma_invoice_customer_id=>@proforma_invoice_customer.id, :status=> 'active').each do |item|
            item.update({:status=> 'deleted', :updated_at=> DateTime.now(), :updated_by=> current_user.id })
          end
        end

        # parameter new_record_item digunakan untuk load data
        logger.info "params[:new_record_item]: #{params[:new_record_item].present?}"
        if params[:new_record_item].present?
          # insert or update
          params[:new_record_item].each do |item|
            # jika data tidak ditemukan makan insert baru
            item_present = ProformaInvoiceCustomerItem.find_by(:proforma_invoice_customer_id=> @proforma_invoice_customer.id, :sales_order_item_id => item['sales_order_item_id'])
            if item_present.present? 
              # if item_present.status != 'active'
                item_present.update_columns({
                  :amount => item["amount"].gsub(".",""),
                  :amountdisc => item["amountdisc"].gsub(".",""),
                  :status=>'active',
                  :updated_at=> DateTime.now(), :updated_by=> current_user.id
                })
              # end
            else
              record_item = ProformaInvoiceCustomerItem.new({
                :proforma_invoice_customer_id=> @proforma_invoice_customer.id,
                :sales_order_id=> item["sales_order_id"],
                :sales_order_item_id=> item["sales_order_item_id"],
                :amount => item["amount"].gsub(".",""),
                :amountdisc => item["amountdisc"].gsub(".",""),
                :status=> 'active',
                :created_at=> DateTime.now(), :created_by=> current_user.id
              })
              record_item.save
            end

          end

        end
        # parameter record_item digunakan untuk update amount
        params[:record_item].each do |item|
          record_item = ProformaInvoiceCustomerItem.find_by(:id=> item["id"])
          if record_item.present?
            case item["status"]
            when 'deleted'
              record_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })        
            else
              record_item.update_columns({
                :proforma_invoice_customer_id=> @proforma_invoice_customer.id,
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            end
          end
        end if params[:record_item].present?

        format.html { redirect_to @proforma_invoice_customer, notice: "#{@proforma_invoice_customer.number} was successfully updated." }
        format.json { render :show, status: :ok, location: @proforma_invoice_customer }
      else
        logger.info "Error: #{@proforma_invoice_customer.errors}"
        format.html { render :edit }
        format.json { render json: @proforma_invoice_customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    notice_kind = "notice"
    notice_msg  = "Proforma invoice customer was successfully #{params[:status]}."
    case params[:status]
    when 'approve1'
      @proforma_invoice_customer.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @proforma_invoice_customer.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @proforma_invoice_customer.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now(), :img_approved2_signature=> current_user.signature}) 
    when 'cancel_approve2'
      @proforma_invoice_customer.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now(), :img_approved2_signature=> nil})
    when 'approve3'
      @proforma_invoice_customer.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
    when 'cancel_approve3'
      if params[:multi_id].present?
        @proforma_invoice_customer.each do |pi_customer|
          if pi_customer.payment_customer.present?
            notice_msg  = "already paid can not be canceled: #{pi_customer.payment_customer.number}"
            notice_kind = "alert"
          else
            notice_kind = "notice"
            notice_msg  = "Successfully App3"
            @proforma_invoice_customer.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
          end
        end
      else
        if @proforma_invoice_customer.payment_customer.present?
          notice_msg  = "already paid can not be canceled: #{@proforma_invoice_customer.payment_customer.number}"
          notice_kind = "alert"
        else
          @proforma_invoice_customer.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
        end
      end
    # when 'void'
      # @proforma_invoice_customer.update_columns({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()})
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to proforma_invoice_customers_url, notice_kind.to_sym=> notice_msg}
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to proforma_invoice_customer_path(:id=> @proforma_invoice_customer.id), notice_kind.to_sym=> notice_msg }
        format.json { head :no_content }
      end
    end

  end

  def print
    if @proforma_invoice_customer.status == 'approved3'  
      sop_number      = ""
      form_number     = ""
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. Provital Perdana"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @proforma_invoice_customer
      items  = @proforma_invoice_customer_items
      name_prepared_by = account_name(header.created_by) 
      name_approved2_by = account_name(header.approved2_by)
      # name_approved3_by = account_name(header.approved3_by)
      name_approved3_by = "#{header.approved3.first_name if header.approved3.present?} #{header.approved3.last_name if header.approved3.present?}" 
      user_prepared_by = User.find_by(:id=> header.created_by)
      
      if user_prepared_by.present? and header.img_created_signature.present?
        img_prepared_by = "public/uploads/signature/#{user_prepared_by.id}/#{header.img_created_signature}"
        if FileTest.exist?("#{img_prepared_by}")
          puts "File Exist"
          puts img_prepared_by
        else
          puts "File not found"
          img_prepared_by = nil
        end
      else
        img_prepared_by = nil
      end

      if header.status == 'approved3' 
        if header.img_approved2_signature.present? 
          user_approved2_by = User.find_by(:id=> header.approved2_by)
          if user_approved2_by.present?
            img_approved2_by = "public/uploads/signature/#{user_approved2_by.id}/#{header.img_approved2_signature}"
            if FileTest.exist?("#{img_approved2_by}")
              puts "File Exist"
              puts img_approved2_by
            else
              puts "File not found: #{img_approved2_by}"
              img_approved2_by = nil
            end
          else
            img_approved2_by = nil
          end      
        else
          img_approved2_by = nil
        end   
        
        if header.img_approved3_signature.present? 
          user_approved3_by = User.find_by(:id=> header.approved3_by)
          if user_approved3_by.present?
            img_approved3_by = "public/uploads/signature/#{user_approved3_by.id}/#{header.img_approved3_signature}"
            if FileTest.exist?("#{img_approved3_by}")
              puts "File Exist"
              puts img_approved3_by
            else
              puts "File not found: #{img_approved3_by}"
              img_approved3_by = nil
            end
          else
            img_approved3_by = nil
          end
        else
          img_approved3_by = nil
        end
      end 

      sub_total = 0
      dp = 0
      disc = 0
      amountdiscount = 0
      discount_total = 0
      ppn_total = 0
      grand_total = 0
      document_name = "SOLD TO/ CUSTOMER"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 

          pdf.move_down 185
          tbl_width = [30, 270, 80, 54, 80, 80]

          pdf.page_count.times do |i|
            item = ProformaInvoiceCustomerItem.find_by(:proforma_invoice_customer_id => @proforma_invoice_customer.id) # po number header
            # items.each do |item|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.bounding_box([0, 747], :width => 250, :height => 30) do
                  pdf.stroke_color '000000' # dk colom customer
                  pdf.stroke_bounds
                end
              }

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                # company
                pdf.table([
                  [ 
                    {:content=>company_name.upcase, :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", "",
                    {:content=>"PROFORMA INVOICE", :font_style => :bold, :valign=>:center, :size=>12}
                  ]],
                  :column_widths => [200, 84, 110, 200], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 2
                pdf.table([
                  [{:content=> "#{company_address1}", :size=> 9}, "", "", ""],
                  [{:content=> "#{company_address2}", :size=> 9}, "", "",""],
                  [{:content=> "021 5011 6422", :size=> 9}, "", "", ""]
                  ],
                  :column_widths => [300, 88, 116, 88], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 
                
                # sold cs
                pdf.move_down 8
                pdf.table([
                  [ 
                    {:content=>document_name, :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", "", ""
                  ]],
                  :column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                  po_num = ""
                  # items.map {|item| po_num+= po_num.present? ? ", #{item.sales_order.po_number}" : "#{item.sales_order.po_number}" }
                  po_num = items.map {|item| item.sales_order.po_number}.uniq.join(", ")

                pdf.table([
                  [{:content=>"", :font_style => :bold, :size=>9, :align=>:center}, "", {:content=>"Proforma Invoice Number", :size=>9, :height=>20},":", {:content=> "#{header.present? ? header.number : nil}", :size=>9}],
                  [{:content=>"#{header.customer.present? ? header.customer.name : nil}", :size=>9}, "", {:content=>"Proforma Invoice Date", :size=>9, :height=>20},":", {:content=> "#{header.present? ? header.date : nil}", :size=>9}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Due Date", :size=>9, :height=>20},":", {:content=> "#{header.present? ? header.due_date : nil}", :size=>9}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"PO Number", :size=>9, :height=>20},":", {:content=> po_num, :size=>9}]
                  ], :column_widths => [310, 5, 120, 10, 125], :cell_style => {:border_width => 0, :border_color => "000000", :padding=> [0,0,0,1]}) 
                
                pdf.move_down 5
                pdf.table([ [{content: "NO", rowspan: 2, width: 30, valign: :center},{:content=> "DESCRIPTION", colspan: 2}, {content: "QUANTITY", rowspan: 2, valign: :center}, {content: "UNIT PRICE", rowspan: 2, width: 80, valign: :center}, {content: "AMOUNT", rowspan: 2, width: 80, valign: :center}],
                    [{:content=> "PART NAME", width: 270}, {:content=> "PART NUMBER", width: 80},]],
                  :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
          
                c = 1
                # pdf.move_down 2
                items.each do |item|
                  pdf.table( [
                    [
                      {:content=> c.to_s, :align=>:center, :size=> 10}, 
                      {:content=>"#{item.sales_order_item.product.name if item.sales_order_item.product.present?}", :size=> 10},
                      {:content=>"#{item.sales_order_item.product.part_id if item.sales_order_item.product.present?}", :size=> 10},
                      {:content=>number_with_precision((item.sales_order_item.quantity if item.sales_order_item.present?), precision: 1, delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                      {:content=>number_with_precision((item.sales_order_item.unit_price if item.sales_order_item.present?), precision: 2, delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                      {:content=>number_with_precision(item.amount, precision: 2, delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                    ]], :column_widths => [30, 270, 80, 54, 80, 80], :cell_style => {:padding => [2, 5, 0, 4], :border_color=>"000000"})

                  c +=1
                  # RUMUS
                  # subtotal = sum amount
                  sub_total += item.amount.to_f

                  # dp total = sum amount * down payment
                  dp = sub_total * ("#{header.down_payment}".to_f / 100 )

                  # call discount
                  disc = "#{item.sales_order_item.discount if item.sales_order_item.present?}".to_f

                  # amountdisc = discount * amount
                  amountdisc = (disc.to_f / 100) * item.amount.to_f

                  # amountdiscount = sum amountdiscount
                  amountdiscount += amountdisc.to_f
                end
                discount_total = "#{header.discount_total}"
                ppn_total = "#{header.ppn_total}"
                grand_total = "#{header.grand_total}"


                pdf.table([
                  [{:content=>"Sum Of : "+number_to_words(grand_total.to_i).upcase+"  ", :height=> 10, width: 300, rowspan: 6, valign: :center }, {:content=>"Subtotal", width: 134 }, {:content=>"IDR", width: 80, :align=> :right }, {:content=> number_with_precision(sub_total, precision: 2, delimiter: ".", separator: ","), width: 80, :align => :right }],
                  [{:content=>"Down Payment #{number_with_precision(header.down_payment, :precision=>1)}%", width: 134 }, {:content=>"IDR", width: 80, :align=> :right }, {:content=> number_with_precision(dp, precision: 2, delimiter: ".", separator: ","), width: 80, :align=> :right }],
                  [{:content=>"Discount", width: 134 }, {:content=>"IDR", width: 80, :align=> :right }, {:content=> number_with_precision(discount_total, precision: 2, delimiter: ".", separator: ","), width: 80, :align=> :right }],
                  [{:content=>"VAT #{("#{header.tax.value if header.tax.present? }".to_f * 100 )}%", width: 134 }, {:content=>"IDR", width: 80, :align=> :right }, {:content=> number_with_precision(ppn_total, precision: 2, delimiter: ".", separator: ","), width: 80, :align=> :right }],
                  [{:content=>"Grand Total", width: 134 }, {:content=>"IDR", width: 80, :align=> :right }, {:content=> number_with_precision(grand_total, precision: 2, delimiter: ".", separator: ","), width: 80, :align=> :right }],
                  [{:content=>"PLEASE PAY FULL AMOUNT", width: 134, colspan: 3, :align=> :center, :font_style => :bold }]
                ], :cell_style => {:size=>9})

                pdf.move_down 10
                if img_approved3_by.present?
                  pdf.table([
                    [{:content=>"#{company_name}", width: 134, :align=> :center }, {:content=>"", width: 120 }, {:content=>"", width: 130 }, {:content=> "#{company_name.upcase}", width: 170, :align=> :left }],
                    [{:image=>img_approved3_by, :position=>:center, :scale=>0.15, :height=>30, rowspan: 2, :height=> 15, width: 134},{:content=>"", width: 134 }, {:content=>"", width: 80 }, {:content=> "A/C : 5223-7277-77", width: 120, :align=> :left }],
                    [{:content=>"", width: 134 }, {:content=>"", width: 80 }, {:content=> "BANK: PT. Bank Central Asia", width: 120, :align=> :left }],
                    [{:content=>"#{name_approved3_by}", width: 134, :align=> :center }, {:content=>"", width: 80 },{:content=>"", width: 120 }, {:content=> "THANK YOU FOR YOUR BUSINESS", width: 150, :align=> :left }]
                  ], :cell_style => {:size=>9, :border_color=>"FFFFFF"})
                else
                  pdf.table([
                    [{:content=>"#{company_name}", width: 134, :align=> :center }, {:content=>"", width: 120 }, {:content=>"", width: 130 }, {:content=> "#{company_name.upcase}", width: 170, :align=> :left }],
                    [{:content=> "-", :align=> :center, :height=>30, rowspan: 2, :height=> 15, width: 134},{:content=>"", width: 134 }, {:content=>"", width: 80 }, {:content=> "A/C : 5223-7277-77", width: 120, :align=> :left }],
                    [{:content=>"", width: 134 }, {:content=>"", width: 80 }, {:content=> "BANK: PT. Bank Central Asia", width: 120, :align=> :left }],
                    [{:content=>"#{name_approved3_by}", width: 134, :align=> :center }, {:content=>"", width: 80 },{:content=>"", width: 120 }, {:content=> "THANK YOU FOR YOUR BUSINESS", width: 150, :align=> :left }]
                  ], :cell_style => {:size=>9, :border_color=>"FFFFFF"})
                end

              }
            # end
            # header end

            # content begin
              
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 420
                # pdf.table([
                #   ["","","",""]
                #   ], :column_widths => [147, 147, 147, 147], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})
              }
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to proforma_invoice_customer_path(:id=> @proforma_invoice_customer.id), alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @proforma_invoice_customer }
      end
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /proforma_invoice_customers/1
  # DELETE /proforma_invoice_customers/1.json
  def destroy
    @proforma_invoice_customer.update_columns({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    respond_to do |format|
      format.html { redirect_to proforma_invoice_customers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_proforma_invoice_customer
      if params[:multi_id].present?
        id_selected       = params[:multi_id].split(',')
        @proforma_invoice_customer = ProformaInvoiceCustomer.where(:id=> id_selected)
      else
        id_selected       = params[:id]
        @proforma_invoice_customer = ProformaInvoiceCustomer.find_by(:id=> id_selected)
      end

      if @proforma_invoice_customer.present?
        @proforma_invoice_customer_items = ProformaInvoiceCustomerItem.where(:status=> 'active')
        .includes(:proforma_invoice_customer).where(:proforma_invoice_customers => {:id=> id_selected, :company_profile_id => current_user.company_profile_id }) 
        .order("proforma_invoice_customers.number desc")
      else
        respond_to do |format|
          format.html { redirect_to proforma_invoice_customers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> ['new','approved1','canceled1','approved2','canceled2','canceled3']).includes(:tax, :term_of_payment)
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=>'active')
      @term_of_payments = TermOfPayment.all
      @taxes = Tax.where(:status=> "active")
    end
    def check_status  
      if @proforma_invoice_customer.status == 'approved3'   
        if params[:status] == "cancel_approve3"
        else   
          puts "-------------------------------"
          puts  @proforma_invoice_customer.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @proforma_invoice_customer, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @proforma_invoice_customer }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def proforma_invoice_customer_params
      params.require(:proforma_invoice_customer).permit(:proforma_invoice_customer_id, :tax_id, :customer_id, :term_of_payment_id, :sales_order_id, :sales_order_item_id, :company_profile_id, :number, :top_day, :payment_terms, :down_payment, :date, :due_date, :total, :grand_total, :remarks, :amount, :amountdisc, :down_payment_total, :discount_total, :ppn_total, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end
end
