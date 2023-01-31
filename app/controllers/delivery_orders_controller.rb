class DeliveryOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_delivery_order, only: [:show, :edit, :update, :destroy, :approve, :print]
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
  include DeliveryOrdersHelper

  # GET /delivery_orders
  # GET /delivery_orders.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    
    # contoh preload
    delivery_orders = DeliveryOrder.where(:company_profile_id=> current_user.company_profile_id).where("delivery_orders.date between ? and ?", session[:date_begin], session[:date_end])
    .includes([:sales_order, :invoice_customer, :customer, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Customer Name', 'customer_id'], ['PO Customer', 'sales_order_id'], ['Driver Name', 'vehicle_driver_name'], ['Car', 'vehicle_number']] 
      @option_filter_records = delivery_orders
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'sales_order_id'
          @option_filter_records = SalesOrder.where(:id=> delivery_orders.select(:sales_order_id))
        when 'delivery_driver_id'
          @option_filter_records = DeliveryDriver.all
        when 'delivery_car_id'
          @option_filter_records = DeliveryCar.all
        end

        delivery_orders = delivery_orders.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @picking_slips = PickingSlip.where(:customer_id=> params[:customer_id]).outgoing_inspection_released if params[:customer_id].present?
    # @picking_slips = PickingSlip.where(:status=> 'approved3', :customer_id=> params[:customer_id]).where("outstanding > 0") if params[:customer_id].present?
    @picking_slip_items = PickingSlipItem.where(:picking_slip_id=> params[:picking_slip_id], :status=> 'active').where("outstanding > 0") if params[:picking_slip_id].present?

    case params[:view_kind]
    when 'item'
      # contoh eager load
      delivery_orders = DeliveryOrderItem.where(:status=> 'active')
      .includes([:product_batch_number, :product])
      .includes(delivery_order: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3]).where(:delivery_orders => {:company_profile_id => current_user.company_profile_id }).where("delivery_orders.date between ? and ?", session[:date_begin], session[:date_end])
      .order("delivery_orders.number desc, products.part_id desc")
    else
      delivery_orders = delivery_orders.order("delivery_orders.number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @delivery_orders = pagy(delivery_orders, page: params[:page], items: pagy_items)
  end

  # GET /delivery_orders/1
  # GET /delivery_orders/1.json
  def show
  end

  # GET /delivery_orders/new
  def new
    @delivery_order = DeliveryOrder.new
    @invoice_customers = InvoiceCustomer.all
    @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
    @drivers = DeliveryDriver.all
    @cars = DeliveryCar.all
  end

  # GET /delivery_orders/1/edit
  def edit
  end

  # POST /delivery_orders
  # POST /delivery_orders.json
  def create
    params[:delivery_order]["company_profile_id"] = current_user.company_profile_id
    params[:delivery_order]["created_by"] = current_user.id
    params[:delivery_order]["img_created_signature"] = current_user.signature
    params[:delivery_order]["created_at"] = DateTime.now()
    params[:delivery_order]["status"] = "new"
    params[:delivery_order]["number"] = document_number(controller_name, params[:delivery_order]["date"].to_date, nil, nil, nil)
    @delivery_order = DeliveryOrder.new(delivery_order_params)

    respond_to do |format|
      if @delivery_order.save
        params[:new_record_item].each do |item|
          DeliveryOrderItem.create({
            :delivery_order_id=> @delivery_order.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :sales_order_item_id=> item["sales_order_item_id"],
            :picking_slip_item_id=> item["picking_slip_item_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          # puts inv_cus_item.inspect
        end if params[:new_record_item].present?

        generate_invoice_customer(@delivery_order.id)

        format.html { redirect_to @delivery_order, notice: 'Delivery order was successfully created.' }
        format.json { render :show, status: :created, location: @delivery_order }
      else
        format.html { render :new }
        format.json { render json: @delivery_order.errors, status: :unprocessable_entity }
      end
      logger.info @delivery_order.errors
    end
  end

  # PATCH/PUT /delivery_orders/1
  # PATCH/PUT /delivery_orders/1.json
  def update
    params[:delivery_order]["updated_by"] = current_user.id
    params[:delivery_order]["updated_at"] = DateTime.now()
    params[:delivery_order]["customer_id"] = @delivery_order.customer_id
    params[:delivery_order]["date"] = @delivery_order.date
    params[:delivery_order]["number"] = @delivery_order.number
    respond_to do |format|
      if @delivery_order.update(delivery_order_params)
        DeliveryOrderItem.where(:delivery_order_id=> @delivery_order.id, :status=> 'active').each do |item|
          item.update({:status=> 'deleted'})
        end
        params[:new_record_item].each do |item|
          delivery_item = DeliveryOrderItem.find_by({
            :delivery_order_id=> @delivery_order.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :sales_order_item_id=> item["sales_order_item_id"],
            :picking_slip_item_id=> item["picking_slip_item_id"]
          })
          if delivery_item.present?
            delivery_item.update({
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            delivery_item = DeliveryOrderItem.create({
              :delivery_order_id=> @delivery_order.id,
              :product_batch_number_id=> item["product_batch_number_id"],
              :product_id=> item["product_id"],
              :sales_order_item_id=> item["sales_order_item_id"],
              :picking_slip_item_id=> item["picking_slip_item_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if params[:new_record_item].present?
        params[:delivery_order_item].each do |item|
          delivery_item = DeliveryOrderItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            delivery_item.update({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            delivery_item.update({
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if delivery_item.present?
        end if params[:delivery_order_item].present?

        update_invoice_customer(@delivery_order.id)
        format.html { redirect_to @delivery_order, notice: 'Delivery order was successfully updated.' }
        format.json { render :show, status: :ok, location: @delivery_order }
      else
        format.html { render :edit }
        format.json { render json: @delivery_order.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve
    periode = @delivery_order.date.strftime("%Y%m")
    prev_periode = (@delivery_order.date.to_date-1.month()).strftime("%Y%m")
    notif_msg = nil
    notif_type = "notice"
    case params[:status]
    when 'approve1'
      @delivery_order.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @delivery_order.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @delivery_order.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @delivery_order.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @delivery_order_items.each do |item|
        if item.product_batch_number.present?
          check_inventory = InventoryBatchNumber.find_by(:company_profile_id=> @delivery_order.company_profile_id, :product_batch_number_id=> item.product_batch_number_id, :periode=> DateTime.now().strftime("%Y%m"))
          if check_inventory.present?
            if item.quantity.to_f > check_inventory.end_stock.to_f
              notif_type = "alert"
              notif_msg  = "BN: #{item.product_batch_number.number} tidak boleh lebih dari stock"
            end
          end
        end
        if item.sales_order_item.outstanding.to_f-item.quantity.to_f < 0
          notif_msg  = "more than outstanding PO: #{item.sales_order_item.sales_order.po_number}" if notif_msg.blank?
        end
        if item.picking_slip_item.outstanding.to_f-item.quantity.to_f < 0
          notif_msg  = "more than outstanding Picking Slip: #{item.picking_slip_item.picking_slip.number}" if notif_msg.blank?
        end
      end
      if notif_msg.blank?
        @delivery_order.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})
        inventory(controller_name, @delivery_order.id, periode, prev_periode, 'approved')  

        @delivery_order_items.each do |item|
          sales_order_item = SalesOrderItem.find_by(:id=> item.sales_order_item_id)
          sales_order_item.update({:outstanding=> sales_order_item.outstanding.to_f-item.quantity.to_f}) if sales_order_item.present?

          picking_slip_item = PickingSlipItem.find_by(:id=> item.picking_slip_item_id)
          picking_slip_item.update({:outstanding=> picking_slip_item.outstanding.to_f-item.quantity.to_f}) if picking_slip_item.present?
        end
      else
        notif_type = "alert"
      end
    when 'cancel_approve3'
      notif_msg = nil
      if @delivery_order.invoice_customer.present? and @delivery_order.invoice_customer.status == 'approved3'
        notif_msg = "Invoice: #{@delivery_order.invoice_customer.number} approved3"
        notif_type = "alert"
      end

      if notif_msg.blank?
        @delivery_order.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
        inventory(controller_name, @delivery_order.id, periode, prev_periode, 'canceled')

        @delivery_order_items.each do |item|
          sales_order_item = SalesOrderItem.find_by(:id=> item.sales_order_item_id)
          sales_order_item.update({:outstanding=> sales_order_item.outstanding.to_f+item.quantity.to_f}) if sales_order_item.present?

          picking_slip_item = PickingSlipItem.find_by(:id=> item.picking_slip_item_id)
          picking_slip_item.update({:outstanding=> picking_slip_item.outstanding.to_f+item.quantity.to_f}) if picking_slip_item.present?
        end
      end
    end

    if notif_msg.blank?
      case params[:status]
      when 'approve3', 'cancel_approve3'
        sales_order = SalesOrder.find_by(:id=> @delivery_order.sales_order_id)
        if sales_order.present?
          sum_outstanding = SalesOrderItem.where(:sales_order_id=> sales_order.id, :status=> 'active').sum(:outstanding)
          sales_order.update_columns(:outstanding=> sum_outstanding)
        end
        picking_slip = PickingSlip.find_by(:id=> @delivery_order.picking_slip_id)
        if picking_slip.present?
          sum_outstanding = PickingSlipItem.where(:picking_slip_id=> picking_slip.id, :status=> 'active').sum(:outstanding)
          picking_slip.update_columns(:outstanding=> sum_outstanding)
        end
      end
      notif_msg = "Delivery Order was successfully #{@delivery_order.status}."
    end

    respond_to do |format|
      format.html { redirect_to delivery_order_path(:id=> @delivery_order.id), notif_type.to_sym=> notif_msg}
      format.json { head :no_content }
    end
  end

  def print
    if @delivery_order.status == 'approved3'
      sop_number      = "SOP-03C-006"
      form_number     = "F-03C-010-Rev 03"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @delivery_order
      items  = @delivery_order_items
      order_number = ""

      customer_name  = (header.customer.present? ? header.customer.name : '')
      customer_code  = (header.customer.present? ? header.customer.number : '')
      customer_address = CustomerAddress.find_by(:customer_id=> header.customer_id)

      summary_qty_do = number_with_precision(items.sum(:quantity), precision: 0, delimiter: ".", separator: ",")

      name_prepared_by = account_name(header.created_by) 
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


      document_name = "DELIVERY ORDER"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 250
          tbl_width = [30, 74, 220, 80, 60, 50, 80]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..30).each do 
              y = pdf.y
              pdf.start_new_page if y < 255
              pdf.move_down 250 if y < 255
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                  {:content=>("#{item.product.name} #{item.product.type_name}" if item.product.present?)},
                  {:content=> (item.product_batch_number.present? ? item.product_batch_number.number : ""), :align=>:center},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right},
                  {:content=>(item.product.unit_name if item.product.present?), :align=>:center},
                  {:content=>item.remarks}
                ]], :column_widths => tbl_width, :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff"})
              c +=1
            # end
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1

                pdf.bounding_box([0, 822], :width => 595) do
                  pdf.text "________________________", :align => :center
                end

                pdf.bounding_box([1, 720], :width => 324, :height => 60) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end

                pdf.bounding_box([424, 780], :width => 70, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([494, 780], :width => 100, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([424, 750], :width => 70, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([494, 750], :width => 100, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([424, 720], :width => 70, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([494, 720], :width => 100, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([424, 690], :width => 70, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([494, 690], :width => 100, :height => 30) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              }

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.table([
                  [{:image => image_path, :image_width => 120}, "", {:content=>document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>19}, "", ""]],
                  :column_widths => [150, 20, 254, 20, 150], :cell_style => {:border_color => "ffffff", :padding=>1}) 
                
                pdf.table([
                  ["", "", {:content=>"Surat Jalan", :font_style => :italic, :align=>:center, :valign=>:top, :size=>10}, "", ""]],
                  :column_widths => [150, 20, 254, 20, 150], :cell_style => {:border_width => 0, :border_color => "ffffff", :padding=>1, :borders=>[:top]}) 

                pdf.table([
                  [{:content=>company_name, :font_style => :bold, :size=>12}, "", "", "", ""]
                  ], :column_widths => [150, 20, 254, 20, 150], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 

                pdf.table([
                  [{:content=>company_address1, :size=>10, :height=>15}, "", {:content=>"Delivery No.", :size=>10, :rowspan=> 2}, {:content=>"#{header.number}", :size=>10, :rowspan=> 2}],
                  [{:content=>company_address2, :size=>10, :height=>15}, ""],
                  [{:content=>company_address3, :size=>10, :height=>15}, "", {:content=>"Delivery Date", :size=>10, :rowspan=> 2}, {:content=>"#{header.date}", :size=>10, :rowspan=> 2}],
                  [{:content=>"", :size=>10, :height=>15}, ""],
                  [{:content=>"Ship to :", :size=>10, :height=>15}, {:content=>"", :size=>10, :height=>15}, {:content=>"Customer ID", :size=>10, :rowspan=> 2}, {:content=>"#{customer_code}", :size=>10, :rowspan=> 2}],
                  [{:content=>"#{customer_name}", :size=>10, :height=>15}, ""],
                  [{:content=>"#{customer_address.present? ? customer_address.office : ''}", :size=>10, :rowspan=> 2, :height=>30}, "", {:content=>"PO No.", :size=>10, :rowspan=> 2}, {:content=>"#{header.sales_order.present? ? header.sales_order.po_number : ''}", :size=>10, :rowspan=> 2}],
                  [{:content=>"", :size=>10}]
                  ], :column_widths => [324, 100, 70, 100], :cell_style => {:border_width => 0, :border_color => "000000", :padding=> [4, 5, 0, 4] }) 
                pdf.move_down 10
                pdf.table([
                  [{:content=>"Transporter   :#{header.transforter_name}", :size=>10, :height=>35}, {:content=>"Licence No.   :#{header.vehicle_number}", :size=>10}, {:content=>"Driver   : #{header.vehicle_driver_name}", :size=>10}],
                  ], :column_widths => [198, 198, 198], :cell_style => {:border_width => 0.2, :border_color => "000000", :padding=> [4, 5, 0, 4] }) 
                pdf.move_down 10

                pdf.table([ ["No.","Product Code","Product Name", "Batch No.","Qty", "Unit", "Remarks"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 589
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 350) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              den_row = 0
              [404, 60, 50, 80].each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position-350], :width => den_row, :height => 20) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              pdf.bounding_box([330, tbl_top_position-355], :width => 100) do
                pdf.text "Grand Total"
              end
              pdf.bounding_box([360, tbl_top_position-355], :width => 100) do
                pdf.text "#{summary_qty_do}", :align=> :right
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 200
                pdf.table([
                  [
                    {:content=> "Issued By", :align=> :center},
                    {:content=> "Checked By", :align=> :center},
                    {:content=> "Shipped By", :align=> :center},
                    {:content=> "Received By", :align=> :center}
                  ]
                  ], :column_widths => [148, 148, 148, 148], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})
                pdf.table([
                  [
                    (header.img_created_signature.present? ? {:image=>img_prepared_by, :position=>:center, :scale=>0.3, :vposition=>:center} : {:content=> ""}),
                    {:content=> ""},
                    {:content=> ""},
                    {:content=> ""}
                  ]
                  ], :column_widths => [148, 148, 148, 148], :cell_style => {:size=> 11, :align=> :center, :border_color => "ffffff", :padding=>2, :height=>70, :inline_format=>true})  

                # pdf.move_down 70
                pdf.table([
                  [
                    (name_prepared_by.present? ? {:content=> "( #{name_prepared_by} )"} : {:content=>"(          <i>Sign Name</i>          )" }),
                    {:content=> "(                             )"},
                    {:content=> "(                             )"},
                    {:content=> "(                             )"}
                  ]
                ], :column_widths => [148, 148, 148, 148], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1, :align=> :center, :inline_format=>true})  
                pdf.move_down 20
                pdf.table([
                  ["Note", "", "", "", ""],
                  [
                    "White : Finance", "Red : Customer", "Yellow : Warehouse", "Green : Transporter", "Blue : Security "
                  ]
                  ], :column_widths => [118, 118, 118, 118, 118], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  
                
                pdf.move_down 10
                pdf.table([
                  ["#{sop_number}", {:content=> "#{form_number}", :align=> :right}]
                  ], :column_widths => [297, 297], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  

              }

              # pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
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
        format.html { redirect_to @delivery_order, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @delivery_order }
      end
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /delivery_orders/1
  # DELETE /delivery_orders/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to delivery_orders_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_delivery_order
      @delivery_order = DeliveryOrder.find_by(:id=> params[:id])
      if @delivery_order.present?
        @delivery_order_items = DeliveryOrderItem.where(:status=> 'active').includes(:delivery_order).where(:delivery_orders => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("delivery_orders.number desc")
      else
        respond_to do |format|
          format.html { redirect_to finish_good_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def check_status      
      noitce_msg = nil 
      if @delivery_order.invoice_customer.present? and @delivery_order.invoice_customer.status == 'approved3'
        noitce_msg = "Cannot be edited because a Invoice: #{@delivery_order.invoice_customer.number} has been created"
      else
        if @delivery_order.status == 'approved3' 
          if params[:status] == "cancel_approve3"
          else 
            noitce_msg = 'Cannot be edited because it has been approved'
          end
        end
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @delivery_order.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @delivery_order, alert: noitce_msg }
          format.json { render :show, status: :created, location: @delivery_order }
        end
      end
    end

    def set_instance_variable
      @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id)
      @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
      @picking_slips = PickingSlip.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:sales_order)
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @drivers = DeliveryDriver.all
      @cars = DeliveryCar.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def delivery_order_params
      params.require(:delivery_order).permit(:number, :status, :company_profile_id, :customer_id, :transforter_name, :date, :remarks, :picking_slip_id, :sales_order_id,:invoice_customer_id, :vehicle_driver_name, :vehicle_number, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end
end
