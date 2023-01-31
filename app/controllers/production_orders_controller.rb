class ProductionOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_production_order, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable
  
  include UserPermissionsHelper
  include ProductionOrdersHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /production_orders
  # GET /production_orders.json
  def index        
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    production_orders = ProductionOrder.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end])
    .includes(:sales_order, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3)
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['SO Number', 'sales_order_id'], ['Customer Name','customer_id']]
      @option_filter_records = production_orders 
      
      if params[:filter_column].present?
        case params[:filter_column]
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        when 'sales_order_id'
          @option_filter_records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id).order("date desc")
        end

        case params[:filter_column]
        when 'customer_id'
          production_orders = production_orders.where(:sales_orders=> {"#{params[:filter_column]}".to_sym=> params[:filter_value]})
        else
          production_orders = production_orders.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
        end
        
      end
    # filter select - end
    if params[:sales_order_id].present?
      @products    = @products.where(:id=> SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]).select(:product_id))
    end

    if params[:tbl_kind] == 'items' or params[:view_kind] == 'item'
      production_orders    = ProductionOrderItem.where(:status=> 'active')
      .includes(product: [:product_type, :unit])
      .includes(production_order: [:sales_order, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3]).where(:production_orders => { :company_profile_id => current_user.company_profile_id })
      .order("production_orders.number desc") 
    else
      production_orders    = production_orders.order("production_orders.number desc") 
    end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @production_orders = pagy(production_orders, page: params[:page], items: pagy_items) 
  end

  # GET /production_orders/1
  # GET /production_orders/1.json
  def show
  end

  # GET /production_orders/new
  def new
    @production_order = ProductionOrder.new
  end

  # GET /production_orders/1/edit
  def edit
  end

  # POST /production_orders
  # POST /production_orders.json
  def create    
    params[:production_order]["company_profile_id"] = current_user.company_profile_id
    params[:production_order]["created_by"] = current_user.id
    params[:production_order]["img_created_signature"] = current_user.signature
    params[:production_order]["created_at"] = DateTime.now()
    params[:production_order]["number"] = document_number(controller_name, params[:production_order]["date"].to_date, nil, nil, nil)
    @production_order = ProductionOrder.new(production_order_params)
    periode = params[:production_order]["date"]

    respond_to do |format|
      if @production_order.save
        params[:new_record_item].each do |item|
          transfer_item = ProductionOrderItem.create({
            :production_order_id=> @production_order.id,
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })

        end if params[:new_record_item].present?
        format.html { redirect_to production_order_path(:id=> @production_order.id), notice: "#{@production_order.number} was successfully created." }
        format.json { render :show, status: :ok, location: @production_order }  
      else
        format.html { render :new }
        format.json { render json: @production_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /production_orders/1
  # PATCH/PUT /production_orders/1.json
  def update
    respond_to do |format|
      params[:production_order]["updated_by"] = current_user.id
      params[:production_order]["updated_at"] = DateTime.now()
      params[:production_order]["number"] = @production_order.number
      periode = params[:production_order]["date"]

      if @production_order.update(production_order_params)                
        params[:new_record_item].each do |item|
          transfer_item = ProductionOrderItem.create({
            :production_order_id=> @production_order.id,
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })   
        end if params[:new_record_item].present?
        params[:production_order_item].each do |item|
          transfer_item = ProductionOrderItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            transfer_item.update_columns({
              :product_id=> item["product_id"],
              :quantity=> (item["quantity"].present? ? item["quantity"] : transfer_item.quantity),
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:production_order_item].present?

        format.html { redirect_to production_orders_path(), notice: "#{@production_order.number} was successfully updated." }
        format.json { render :show, status: :ok, location: @production_order }      
      else
        format.html { render :edit }
        format.json { render json: @production_order.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    alert_text = nil
    case params[:status]
    when 'approve1'
      @production_order.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @production_order.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @production_order.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @production_order.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      if @production_order.sales_order.status == 'approved3'
        @production_order.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
        load_bom(@production_order.id)
      else
        alert_text = "#{@production_order.sales_order.number} harus diapprove3 terlebih dahulu!"
      end
    when 'cancel_approve3'
      prf_check = ProductionOrderUsedPrf.where(:status=> 'active')
      .includes(production_order_item: [:production_order])
      .where(:production_order_items => {:status=> 'active', :production_order_id => @production_order.id })
      
      if prf_check.present?
        alert_text = 'Sudah dibuatkan PRF tidak bisa dicancel'
      else
        @production_order.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
        canceled_bom(@production_order.id)
      end
    when 'unlock_print'
      @production_order.update_columns({:printed_by=> nil, :printed_at=> nil, :unlock_printed_by=> current_user.id, :unlock_printed_at=> DateTime.now()})
    end

    respond_to do |format|
      if alert_text.present?
        format.html { redirect_to production_order_path(:id=> @production_order.id), alert: "#{alert_text}" }
      else
        format.html { redirect_to production_order_path(:id=> @production_order.id), notice: "SPP was successfully #{@production_order.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    if @production_order.status == 'approved3'
      sop_number      = ""

      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @production_order
      items  = @production_order_items
      customer = (header.sales_order.present? ? header.sales_order.customer : "")
      customer_name = (customer.present? ? customer.name : "")
      customer_top_day = (customer.present? ? customer.top_day : "")
      customer_top     = (customer.present? ? customer.term_of_payment.name : "")
      po_number = (header.sales_order.present? ? header.sales_order.po_number : "")
      order_number = (header.present? ? header.number : "")  
      order_date   = (header.present? ? header.date : "")
      
      name_prepared_by = account_name(header.created_by) 
      name_approved_by = account_name(header.approved3_by)
      
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

      if header.status == 'approved3' and header.img_approved3_signature.present?
        user_approved_by = User.find_by(:id=> header.approved3_by)
        if user_approved_by.present?
          img_approved_by = "public/uploads/signature/#{user_approved_by.id}/#{header.img_approved3_signature}"
          if FileTest.exist?("#{img_approved_by}")
            puts "File Exist"
            puts img_approved_by
          else
            puts "File not found: #{img_approved_by}"
            img_approved_by = nil
          end
        else
          img_approved_by = nil
        end
      else
        img_approved_by = nil
      end  

    
      form_number     = "F-03A-003 Rev 02"

      document_name = "Surat Perintah Produksi"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 140

          tbl_width = [30, 70, 480, 80, 50, 130]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..20).each do 
              y = pdf.y
              pdf.start_new_page if y < 140
              pdf.move_down 140 if y < 140

              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                  {:content=>"#{(item.product.name if item.product.present?)} - #{(item.product.type_name if item.product.present?)}"},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right},
                  {:content=>(item.product.unit_name if item.product.present?), :align=>:center},
                  {:content=>item.remarks}
                ]], :column_widths => tbl_width, :cell_style => {:padding => [4, 5, 0, 4], :border_color=>"ffffff"})
              c +=1
            # end
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 590
                pdf.table([
                  [{:image => image_path, :image_width => 120}, "", {:content=> "Printed at : ", :align=> :right}, " #{DateTime.now().strftime("%Y-%m-%d %H:%M:%S")}"],
                  [company_name, "", "", sop_number]],
                  :column_widths => [250,340, 100, 150], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>1}) 
                pdf.move_down 10
                pdf.table([
                  ["",{:content=> document_name, :align=> :center}, ""]],
                  :column_widths => [150,540, 150], :cell_style => {:size=> 17, :border_color => "f0f0f0", :background_color => "f0f0f0", :padding=>1})  
                
                  pdf.table([
                    ["Customer", ":", customer_name, "TOP ", ":"," #{customer_top_day} #{customer_top}", "", "Date",":", order_date],
                    ["PO Customer", ":", po_number,  "remarks", ":"," #{header.remarks}", "", "No.Number", ":", order_number]
                    ], :column_widths => [70, 20, 200, 50, 20, 180, 110, 70, 20, 100], :cell_style => {:size=> 10, :border_color => "f0f0f0", :padding=>5}) 
               

                pdf.move_down 5
                pdf.table([ ["No.","Product Code","Product Name",  "Quantity", "Unit", "Remarks"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
                den_row = 0
                tbl_top_position = 452
                bound_height = 330

              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => bound_height) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end

              pdf.bounding_box([0, 122], :width => 500, :height => 80) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end

              pdf.bounding_box([500, 122], :width => 340, :height => 80) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 115

                pdf.table([
                  ["", {:content=> "Prepared by", :align=> :center}, "", {:content=> "Approved by", :align=> :center},""]
                  ], :column_widths => [30, 100, 580, 100, 30], :cell_style => {:size=> 11, :border_width=> 0, :border_color => "ffffff",  :padding=>0})

                # pdf.draw_text "-------------", :at => [15,800]
                pdf.image "#{img_prepared_by}", :at => [40,700], :width => 100 if img_prepared_by.present?
                pdf.image "#{img_approved_by}", :at => [710,700], :width => 100 if img_approved_by.present? 

                pdf.move_down 45
                pdf.table([
                  ["", {:content=> "#{name_prepared_by}", :align=> :center}, "", {:content=> "#{name_approved_by}", :align=> :center},""]
                ], :column_widths => [30, 100, 580, 100, 30], :cell_style => {:size=> 11, :border_width=> 0, :border_color => "ffffff",  :padding=>0})

                pdf.move_down 25
                pdf.table([
                  ["",{:content=> "CONFIDENTIAL", :align=> :center}, {:content=> form_number, :align=> :right}]],
                  :column_widths => [250,340, 250], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})  
               
              }

              # pdf.image "#{img_prepared_by}", :at => [700, 100], :width => 100 if img_prepared_by.present?
              # pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 25]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @production_order, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @production_order }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /production_orders/1
  # DELETE /production_orders/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to production_orders_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_production_order
      @production_order = ProductionOrder.find_by(:id=> params[:id])
      if @production_order.present?
        @production_order_items = ProductionOrderItem.where(:status=> 'active').includes(:production_order).where(:production_orders => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("production_orders.number desc") 
        @production_order_detail_materials = ProductionOrderDetailMaterial.where(:company_profile_id=> current_user.company_profile_id, :production_order_id=> @production_order.id, :status=> 'active')
        @production_order_used_prf = ProductionOrderUsedPrf.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :production_order_detail_material_id=> @production_order_detail_materials.select(:id))
      else                
        respond_to do |format|
          format.html { redirect_to production_orders_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')

    end
    
    def check_status   
      if @production_order.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @production_order.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to production_order_path(:id=> @production_order.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @production_order }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def production_order_params
      params.require(:production_order).permit(:company_profile_id, :number, :sales_order_id, :date, :kind, :remarks, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end

end
