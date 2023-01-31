class PickingSlipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_picking_slip, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /picking_slips
  # GET /picking_slips.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    
    picking_slips = PickingSlip.where(:company_profile_id=> current_user.company_profile_id).where("picking_slips.date between ? and ?", session[:date_begin], session[:date_end]).order("picking_slips.date desc")
    .includes([:customer, :sales_order, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided])
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Customer Name', 'customer_id'], ['PO Customer', 'sales_order_id'], ['Driver Name', 'delivery_driver_id'], ['Car', 'delivery_car_id']] 
      @option_filter_records = picking_slips
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'sales_order_id'
          @option_filter_records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        when 'delivery_driver_id'
          @option_filter_records = DeliveryDriver.all
        when 'delivery_car_id'
          @option_filter_records = DeliveryCar.all
        end

        picking_slips = picking_slips.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

  
    @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :customer_id=> params[:customer_id]).where("outstanding > 0") if params[:customer_id].present?
    @sales_order_items = SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]).where("outstanding > 0") if params[:sales_order_id].present?
    
    if params[:sales_order_id].present?
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :id=> @sales_order_items.select(:product_id))
    else
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    end
    # menampilkan batch number yg sudah dibuatkan dokumen finish good receiving note
    if params[:product_id].present?
      @product_batch_number = @product_batch_number.where(:product_id=> params[:product_id]) 
    elsif params[:product_batch_number_id].present?
      @product_batch_number = @product_batch_number.where(:product_batch_number_id=> params[:product_batch_number_id])
      @picking_slip_items = PickingSlipItem.where(:status=> 'active', :picking_slip_id => params[:id] )
        
    end

    case params[:view_kind]
    when 'item'
      picking_slips = PickingSlipItem.where(:status=> 'active')
      .includes([:product, :product_batch_number])
      .includes(:picking_slip).where(:picking_slips => { :company_profile_id => current_user.company_profile_id }).order("picking_slips.number desc")
    else
      picking_slips = picking_slips.order("number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @picking_slips = pagy(picking_slips, page: params[:page], items: pagy_items)

  end

  # GET /picking_slips/1
  # GET /picking_slips/1.json
  def show
  end

  # GET /picking_slips/new
  def new
    @picking_slip = PickingSlip.new
    @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id)
    @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
    @drivers = DeliveryDriver.all
    @cars = DeliveryCar.all
  end

  # GET /picking_slips/1/edit
  def edit
  end

  # POST /picking_slips
  # POST /picking_slips.json
  def create
    params[:picking_slip]["outstanding"] = 0
    params[:picking_slip]["company_profile_id"] = current_user.company_profile_id
    params[:picking_slip]["created_by"] = current_user.id
    params[:picking_slip]["created_at"] = DateTime.now()
    params[:picking_slip]["status"] = "new"
    params[:picking_slip]["number"] = document_number(controller_name, params[:picking_slip]["date"].to_date, nil, nil, nil)
    @picking_slip = PickingSlip.new(picking_slip_params)

    respond_to do |format|
      if @picking_slip.save
        sum_outstanding = 0
        params[:new_record_item].each do |item|
          delivery_item = PickingSlipItem.create({
            :picking_slip_id=> @picking_slip.id,
            :sales_order_item_id=> item["sales_order_item_id"],
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"].to_f, :outstanding=> item["quantity"].to_f, 
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          sum_outstanding += item["quantity"].to_f
          puts sum_outstanding
        end if params[:new_record_item].present?
        @picking_slip.update_columns(:outstanding=> sum_outstanding)

        format.html { redirect_to @picking_slip, notice: 'Delivery order was successfully created.' }
        format.json { render :show, status: :created, location: @picking_slip }
      else
        format.html { render :new }
        format.json { render json: @picking_slip.errors, status: :unprocessable_entity }
      end
      logger.info @picking_slip.errors
    end
  end

  # PATCH/PUT /picking_slips/1
  # PATCH/PUT /picking_slips/1.json
  def update
    params[:picking_slip]["updated_by"] = current_user.id
    params[:picking_slip]["updated_at"] = DateTime.now()
    params[:picking_slip]["number"] = @picking_slip.number
    respond_to do |format|
      if @picking_slip.update(picking_slip_params)
        if params[:new_record_item].present?
          PickingSlipItem.where(:status=> 'active', :picking_slip_id=> @picking_slip.id).each do |item|
            item.update({:status=> 'deleted', :deleted_at=> DateTime.now(), :deleted_by=> current_user.id})
          end

          params[:new_record_item].each do |item|
            picking_slip_item = PickingSlipItem.create({
              :picking_slip_id=> @picking_slip.id,
              :product_id=> item["product_id"],
              :product_batch_number_id=> item["product_batch_number_id"],
              :sales_order_item_id=> item["sales_order_item_id"],
              :quantity=> item["quantity"].to_f, :outstanding=> item["quantity"].to_f, 
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end 
        end
        params[:picking_slip_item].each do |item|
          picking_slip_item = PickingSlipItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            picking_slip_item.update({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            # aden 20201007
            outstanding = item["quantity"].to_f
            DeliveryOrderItem.where(:picking_slip_item_id=> picking_slip_item.id, :status=> 'active').each do |do_item|
              if do_item.delivery_order.status == 'approved3'
                outstanding -= do_item.quantity.to_f
              end
            end

            picking_slip_item.update({
              :product_id=> item["product_id"],
              :product_batch_number_id=> item["product_batch_number_id"],
              :sales_order_item_id=> item["sales_order_item_id"],
              :quantity=> item["quantity"].to_f, :outstanding=> outstanding,
              :remarks=> item["remarks"].to_f,
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if picking_slip_item.present?
        end if params[:picking_slip_item].present?

        sum_outstanding = 0
        PickingSlipItem.where(:status=> 'active', :picking_slip_id=> @picking_slip.id).each do |item|
          sum_outstanding += item.outstanding.to_f
        end
        @picking_slip.update_columns(:outstanding=> sum_outstanding)
        format.html { redirect_to @picking_slip, notice: "#{@picking_slip.number} was successfully updated." }
        format.json { render :show, status: :ok, location: @picking_slip }
      else
        format.html { render :edit }
        format.json { render json: @picking_slip.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve
    notif_msg = nil
    notif_type = "notice"

    case params[:status]
    when 'approve1'
      @picking_slip.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @picking_slip.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @picking_slip.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @picking_slip.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @picking_slip.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})
    when 'cancel_approve3'
      check_delivery = DeliveryOrder.find_by(:status=> 'approved3', :picking_slip_id=> @picking_slip.id)
      if check_delivery.present?
        notif_type = "alert"
        notif_msg  = "DO: #{check_delivery.number} current status #{check_delivery.status}!"
      else
        @picking_slip.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
      end
    end

    if notif_msg.blank?
      notif_msg = "Picking Slip was successfully #{@picking_slip.status}."
    end

    respond_to do |format|
      format.html { redirect_to picking_slip_path(:id=> @picking_slip.id), notif_type.to_sym=> notif_msg}
      format.json { head :no_content }
    end
  end

  def print
    print_allow = false 
    case @picking_slip.status 
    when 'approved1','canceled2' 
      print_allow = true 
    end 

    if current_user.present? and current_user.id == 1 
      print_allow = true 
    end 

    if print_allow == true 
      sop_number      = ""
      form_number     = "F-03C-007-Rev 02"
      image_path      = "app/assets/images/logo.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @picking_slip
      items  = @picking_slip_items
      customer_name = "#{header.customer.name if header.customer.present?}"
      customer_address = CustomerAddress.find_by(:customer_id=> header.customer_id)
      customer_address = "#{customer_address.office if customer_address.present?}"

      sales_order = header.sales_order


      term_of_payment = ""
      supplier_name  = ""
      supplier_code  = ""
      supplier_address  = ""
      supplier_phone  = ""
      supplier_email  = ""

      subtotal = 0

      document_name = "PICKING SLIP"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 20,
            :bottom_margin => 20, 
            :left_margin=> 20, 
            :right_margin=> 20) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 200
          tbl_width = [25, 80, 80, 210, 80, 80]
          c = 1
          pdf.move_down 2
          items.each do |item|
            part = item.product
            # (1..50).each do 
              order_number = nil

              batch_number = item.product_batch_number
              if batch_number.present?
                if batch_number.shop_floor_order_item.present?
                  order_number = batch_number.shop_floor_order_item.shop_floor_order.number
                else
                  if batch_number.sterilization_product_receiving_item.present?
                    order_number = batch_number.sterilization_product_receiving_item.sterilization_product_receiving.number
                  end
                end
              end

              y = pdf.y
              pdf.start_new_page if y < 190
              pdf.move_down 190 if y < 190
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=> "#{order_number}"},
                  {:content=>(part.part_id if part.present?)},
                  {:content=>(part.name if part.present?)},
                  {:content=> "#{item.product_batch_number.number if item.product_batch_number.present?}"},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right},
                ]], :column_widths => tbl_width, :cell_style => {:padding => [2, 5, 1, 5], :border_color=>"ffffff", :size=> 10})
              c +=1
              subtotal += item.quantity
            # end
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1

                pdf.bounding_box([277, 765], :width => 93, :height => 60) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([370, 765], :width => 185, :height => 60) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              }

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.table([
                  [ 
                    {:image => image_path, :image_width => 100}, 
                    {:content=>"PICKING SLIP", :font_style => :bold, :align=>:right, :valign=>:center, :size=>12}
                  ]],
                  :column_widths => [455,100], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 15
                pdf.table([
                  [ 
                    {:content=> company_name}, {:content=>"Date", :font_style => :bold, :size=>10}, ":", {:content=>"#{header.date}", :font_style => :bold, :size=>10}
                  ],
                  [ 
                    {:content=> "#{company_address1}", :size=>10, :padding=> 0}, {:content=>"Customer ID", :font_style => :bold, :size=>10}, ":", {:content=>"#{header.customer.number if header.customer.present?}", :font_style => :bold, :size=>10}
                  ],
                  [ 
                    {:content=> "#{company_address2}", :size=>10, :padding=> 0}, {:content=>"PO No.", :font_style => :bold, :size=>10}, ":", {:content=>"#{sales_order.po_number if sales_order.present?}", :font_style => :bold, :size=>10}
                  ]
                  ], :column_widths => [280, 90, 5, 180], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 15
                pdf.table([
                  [ 
                    {:content=>"Bill To: ", :font_style => :bold, :size=>10, :height=> 20},
                    {:content=>"Ship To: ", :font_style => :bold,  :size=>10, :height=> 20}
                  ] ], :column_widths => [277, 277], :cell_style => {:border_width => 0.4, :border_color => "000000", :background_color => "f0f0f0", :padding=> [2,5,0,5] }) 
                pdf.table([
                  [ 
                    {:content=>"#{customer_name}
                    #{customer_address.to_s[0, 70]}", :size=>10, :height=> 40},
                    {:content=>"#{customer_name}
                    #{customer_address.to_s[0, 70]}", :size=>10, :height=> 40}
                  ]],
                  :column_widths => [277, 277], :cell_style => {:border_width => 0.4, :border_color => "000000", :padding=> [2,5,0,5] })
                pdf.move_down 20
                
                pdf.table([ ["No.","Order Number", "Product Code", "Product Name", "Batch Number", "Quantity"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 600
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 440) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              den_row = 0


              pdf.bounding_box([0, 160], :width => 475, :height => 20) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([475, 160], :width => 80, :height => 20) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, 155], :width => 80) do
                pdf.text "TOTAL", :size=> 10
              end
              pdf.bounding_box([475, 155], :width => 78) do
                pdf.text number_with_precision(subtotal, precision: 0, delimiter: ".", separator: ","), :align=> :right , :size=> 10
              end
              pdf.move_down 15
              pdf.table([
                [ 
                  {:content=>"Picked by", :font_style => :bold, :size=>10, :height=> 20, :align=> :center},
                  {:content=>"Checked by", :font_style => :bold,  :size=>10, :height=> 20, :align=> :center},
                  {:content=>"Verified by", :font_style => :bold,  :size=>10, :height=> 20, :align=> :center}
                ] ], :column_widths => [184, 184, 184], :cell_style => {:border_width => 0.4, :border_color => "000000", :background_color => "f0f0f0", :padding=> [2,5,0,5] }) 
              pdf.table([
                [ 
                  {:content=>"", :font_style => :bold, :size=>10, :height=> 60},
                  {:content=>"", :font_style => :bold,  :size=>10, :height=> 60},
                  {:content=>"", :font_style => :bold,  :size=>10, :height=> 60}
                ] ], :column_widths => [184, 184, 184], :cell_style => {:border_width => 0.4, :border_color => "000000", :padding=> [2,5,0,5] }) 
                
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 10
                
                pdf.table([
                  [
                    "", "", "", {:content=> "#{form_number}", :align=> :right}
                  ]
                  ], :column_widths => [138, 138, 138, 138], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  

              }

              pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @picking_slip, alert: 'Cannot be displayed, status must be Approve 1' }
        format.json { render :show, status: :ok, location: @picking_slip }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  # DELETE /picking_slips/1
  # DELETE /picking_slips/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to picking_slips_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_picking_slip
      @picking_slip = PickingSlip.find_by(:id=> params[:id])

      if @picking_slip.present?
        @picking_slip_items = PickingSlipItem.where(:status=> 'active').includes(:picking_slip).where(:picking_slips => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("picking_slips.number desc")
        @sales_order_items = SalesOrderItem.where(:sales_order_id=> @picking_slip.sales_order_id, :status=> 'active') 
        @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :id=> @sales_order_items.select(:product_id))
      else
        respond_to do |format|
          format.html { redirect_to picking_slips_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable      
      # batch_number_stock_product = InventoryBatchNumber.where(:periode=> DateTime.now().strftime("%Y%m")).where("product_id > 0").where("end_stock > 0")
      # @product_batch_number = ProductBatchNumber.where(:periode_yyyy=> DateTime.now().strftime("%Y")).where(:product_id=> batch_number_stock_product.select(:product_id))
      periode_selected = (params[:date].present? ? params[:date].to_date.strftime("%Y%m") : DateTime.now().strftime("%Y%m") )
      @product_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> periode_selected).where("inventory_batch_numbers.product_id > 0").where("inventory_batch_numbers.end_stock > 0")
      .includes(:product_batch_number)
      .where(:product_batch_numbers => {:company_profile_id => current_user.company_profile_id })
      .where("product_batch_numbers.outstanding_picking_slip > 0")
      .order("product_batch_numbers.number asc")
      
      @invoice_customers = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id)
      @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where("outstanding > 0")
      
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @drivers = DeliveryDriver.all
      @cars = DeliveryCar.all
    end

    def check_status
      if @picking_slip.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          respond_to do |format|
            format.html { redirect_to @picking_slip, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @picking_slip }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def picking_slip_params
      params.require(:picking_slip).permit(:company_profile_id, :status, :number, :customer_id, :date, :outstanding, :remarks, :sales_order_id,:invoice_customer_id, :delivery_car_id, :delivery_driver_id, :created_by, :created_at, :updated_by, :updated_at)
    end
end
