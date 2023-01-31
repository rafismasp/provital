class ShopFloorOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shop_floor_order, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /shop_floor_orders
  # GET /shop_floor_orders.json
  def index        
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    shop_floor_orders = ShopFloorOrder.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']]
      @option_filter_records = shop_floor_orders 
      
      if params[:filter_column].present?
        shop_floor_orders = shop_floor_orders.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    if params[:sales_order_id].present?
      @products    = @products.where(:id=> SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]).select(:product_id))
    end




    if params[:tbl_kind] == 'items' or params[:view_kind] == 'item'
      shop_floor_orders    = ShopFloorOrderItem.where(:status=> 'active').includes(:shop_floor_order).where(:shop_floor_orders => { :company_profile_id => current_user.company_profile_id }).order("shop_floor_orders.number desc") 
    else
      shop_floor_orders    = shop_floor_orders.order("number desc")
    end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @shop_floor_orders = pagy(shop_floor_orders, page: params[:page], items: pagy_items) 
  end

  # GET /shop_floor_orders/1
  # GET /shop_floor_orders/1.json
  def show
    if params[:recheck]== 'true'

      ShopFloorOrderItem.where(:shop_floor_order_id=> @shop_floor_order.id, :status=> 'active').each do |item|
        ProductBatchNumber.where(:shop_floor_order_item_id=> item.id, :status=> 'active').each do |bn|
          bn.update(:updated_at=> DateTime.now())
        end

      end
    end
  end

  # GET /shop_floor_orders/new
  def new
    @shop_floor_order = ShopFloorOrder.new
  end

  # GET /shop_floor_orders/1/edit
  def edit
  end

  # POST /shop_floor_orders
  # POST /shop_floor_orders.json
  def create    
    params[:shop_floor_order]["company_profile_id"] = current_user.company_profile_id
    params[:shop_floor_order]["created_by"] = current_user.id
    params[:shop_floor_order]["created_at"] = DateTime.now()
    params[:shop_floor_order]["number"] = document_number(controller_name, params[:shop_floor_order]["date"].to_date, nil, nil, nil)
    @shop_floor_order = ShopFloorOrder.new(shop_floor_order_params)
    periode = params[:shop_floor_order]["date"]

    respond_to do |format|
      if @shop_floor_order.save
        params[:new_record_item].each do |item|
          product = Product.find_by(:id=> item["product_id"])
          outstanding_sterilization = 0
          outstanding_sterilization_out = 0
          if product.present? and product.sterilization
            outstanding_sterilization = item["quantity"]
            outstanding_sterilization_out = item["quantity"]
          end
          transfer_item = ShopFloorOrderItem.create({
            :shop_floor_order_id=> @shop_floor_order.id,
            :sales_order_id=> item["sales_order_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          product_batch_number = ProductBatchNumber.find_by(:shop_floor_order_item_id=> transfer_item.id, :product_id=> item["product_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
          if product_batch_number.blank?
            ProductBatchNumber.create(
              :shop_floor_order_item_id=> transfer_item.id, 
              :product_id=> item["product_id"], 
              :number=>  gen_product_batch_number(item["product_id"], periode),
              :outstanding=> item["quantity"],
              :outstanding_sterilization=> outstanding_sterilization,
              :outstanding_sterilization_out=> outstanding_sterilization_out,
              :outstanding_direct_labor=> item["quantity"],
              :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
              )
          end   

        end if params[:new_record_item].present?
        format.html { redirect_to shop_floor_order_path(:id=> @shop_floor_order.id), notice: "#{@shop_floor_order.number} was successfully created." }
        format.json { render :show, status: :ok, location: @shop_floor_order }  
      else
        format.html { render :new }
        format.json { render json: @shop_floor_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shop_floor_orders/1
  # PATCH/PUT /shop_floor_orders/1.json
  def update
    respond_to do |format|
      params[:shop_floor_order]["updated_by"] = current_user.id
      params[:shop_floor_order]["updated_at"] = DateTime.now()
      params[:shop_floor_order]["number"] = @shop_floor_order.number
      periode = params[:shop_floor_order]["date"]

      if @shop_floor_order.update(shop_floor_order_params)                
        params[:new_record_item].each do |item|
          transfer_item = ShopFloorOrderItem.create({
            :shop_floor_order_id=> @shop_floor_order.id,
            :sales_order_id=> item["sales_order_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          create_batch_number(periode, transfer_item.product_id, item["product_id"], transfer_item.id, item["quantity"])
        end if params[:new_record_item].present?

        params[:shop_floor_order_item].each do |item|
          transfer_item = ShopFloorOrderItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
            product_batch_number = ProductBatchNumber.find_by(:shop_floor_order_item_id=> transfer_item.id, :status=> 'active')
            product_batch_number.update(:status=> 'suspend') if product_batch_number.present?
          else
            create_batch_number(periode, transfer_item.product_id, item["product_id"], transfer_item.id, item["quantity"])
            transfer_item.update({
              :sales_order_id=> item["sales_order_id"],
              :product_id=> item["product_id"],
              :quantity=> (item["quantity"].present? ? item["quantity"] : transfer_item.quantity),
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:shop_floor_order_item].present?

        format.html { redirect_to shop_floor_orders_path(), notice: "#{@shop_floor_order.number} was successfully updated." }
        format.json { render :show, status: :ok, location: @shop_floor_order }      
      else
        format.html { render :edit }
        format.json { render json: @shop_floor_order.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @shop_floor_order.update_columns({:img_approved1_by=> current_user.signature, :status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @shop_floor_order.update_columns({:img_approved1_by=> nil, :status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @shop_floor_order.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @shop_floor_order.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @shop_floor_order.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
    when 'cancel_approve3'
      @shop_floor_order.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
    when 'unlock_print'
      @shop_floor_order.update_columns({:printed_by=> nil, :printed_at=> nil, :unlock_printed_by=> current_user.id, :unlock_printed_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to shop_floor_order_path(:id=> @shop_floor_order.id), notice: "SFO was successfully #{@shop_floor_order.status}." }
      format.json { head :no_content }
    end
  end

  def print
    if @shop_floor_order.status == 'approved3'
      if @shop_floor_order.printed_by.blank?
        sop_number      = "SOP-03A-001"

        image_path      = "app/assets/images/logo-bw.png"  
        company_name    = "PT. PROVITAL PERDANA"
        company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

        header = @shop_floor_order
        items  = @shop_floor_order_items
        # po_number = (header.sales_order.present? ? header.sales_order.po_number : "")
        order_number = (header.present? ? header.number : "")  

        name_approved3_by = account_name(header.approved3_by)

        user_approved3_by = User.find_by(:id=> header.approved3_by) if header.img_approved3_signature.present?
        if user_approved3_by.present? and header.img_approved3_signature.present? #ttd approval 3
          img_approved3_by = "public/uploads/signature/#{user_approved3_by.id}/#{header.img_approved3_signature}"
          if FileTest.exist?("#{img_approved3_by}")
            puts "File Exist"
          else
            puts "File not found #{img_approved3_by}"
            img_approved3_by = nil
          end
        else
          img_approved3_by = nil
        end

        form_number     = "F-03A-003 Rev 02"

        document_name = "SHOP FLOOR ORDER FOR PRODUCTION"
        respond_to do |format|
          format.html do
            pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
           
            # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

            pdf.move_down 120

            tbl_width = [30, 70, 450, 80, 80, 80, 50]
            c = 1
            pdf.move_down 2
            items.each do |item|
              # (1..20).each do 
                product_batch_number = ProductBatchNumber.where(:status=> 'active', :shop_floor_order_item_id=> item.id).map { |e| e.number }.join(", ").to_s
                y = pdf.y
                pdf.start_new_page if y < 150
                pdf.move_down 120 if y < 150

                pdf.table( [
                  [
                    {:content=> c.to_s, :align=>:center}, 
                    {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                    {:content=>(item.product.name if item.product.present?)},
                    {:content=>(item.product.type_name if item.product.present?)},
                    {:content=> product_batch_number},
                    {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right},
                    {:content=>(item.product.unit_name if item.product.present?), :align=>:center}
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
                    [{:image => image_path, :image_width => 120}, "", "", ""],
                    [company_name, "", "", sop_number]],
                    :column_widths => [250,340, 100, 150], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>1}) 
                  pdf.move_down 10
                  pdf.table([
                    ["",{:content=> document_name, :align=> :center}, ""]],
                    :column_widths => [150,540, 150], :cell_style => {:size=> 17, :border_color => "f0f0f0", :background_color => "f0f0f0", :padding=>1})  
                  
                    pdf.table([
                      # ["Customer PO Number", ":", po_number, "", "", ""],
                      ["Order Number", ":", order_number, "", "", ""]
                      ], :column_widths => [130, 20, 470, 100, 20, 100], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>5}) 
                 

                  pdf.move_down 5
                  pdf.table([ ["No.","Product Code","Product Name", "Type", "Batch No.", "Quantity", "Unit"]], 
                    :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                  
                }
              # header end

              # content begin
                  den_row = 0
                  tbl_top_position = 472
                  bound_height = 350

                tbl_width.each do |i|
                  # puts den_row
                  den_row += i
                  pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => bound_height) do
                    pdf.stroke_color '000000'
                    pdf.stroke_bounds
                  end
                end
              # content end

              # footer begin
                pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                  pdf.go_to_page i+1
                  pdf.move_up 110

                  pdf.table([
                    ["","", "", {:content=>"Prepared by,", :align=>:center, :padding=>0},""],
                    ["","", "", (img_approved3_by.present? ? {:image=>(img_approved3_by), :height=>40, :position=>:center, :scale=>0.18, :padding=>2} : {:content=>'', :height=>40}),""],
                    ["","", "", {:content=>"#{name_approved3_by if name_approved3_by.present?}", :align=>:center, :padding=>0}, ""]
                    ], :column_widths => [30, 100, 530, 150, 30], :cell_style => {:size=> 11, :border_color => "ffffff"})


                  pdf.move_down 20
                  pdf.table([
                    ["",{:content=> "CONFIDENTIAL", :align=> :center}, {:content=> form_number, :align=> :right}]],
                    :column_widths => [250,340, 250], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})  
                 
                }
                
                pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 25]
              # footer end
            end

            send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
            @shop_floor_order.update_columns({:printed_by=> current_user.id, :printed_at=> DateTime.now()}) 
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to @shop_floor_order, alert: 'sudah pernah diprint, jika ingin print ulang minta ke Pak Johnny' }
          format.json { render :show, status: :ok, location: @shop_floor_order }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @shop_floor_order, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @shop_floor_order }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /shop_floor_orders/1
  # DELETE /shop_floor_orders/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to shop_floor_orders_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shop_floor_order
      @shop_floor_order = ShopFloorOrder.find_by(:id=> params[:id])
      if @shop_floor_order.present?
        @shop_floor_order_items = ShopFloorOrderItem.where(:status=> 'active').includes(:shop_floor_order).where(:shop_floor_orders => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("shop_floor_orders.number desc") 
      else                
        respond_to do |format|
          format.html { redirect_to shop_floor_orders_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @sales_orders  = SalesOrder.where(:service_type_str=> 0, :status=> 'approved3', :company_profile_id => current_user.company_profile_id)
       @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes([:unit, :product_type], sales_order_items: [:sales_order])
      .where(:sales_order_items=> {:status=> 'active'})
      .where(:sales_orders=> {:service_type_str=> 0, :status=> 'approved3', :company_profile_id => current_user.company_profile_id})
      # hanya menampilkan yg bukan service type STR = Sterilisasi
      # sfo tidak merelasi SO mana, karena 1 SFO beberapa SO
      # @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')

      # 20200903 => Pak Jaenal Request: SFO harus pilih Sales Order

      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).includes([product: [:unit, :product_type]])

      case params[:partial]
      when 'change_quantity'
        select_product = SalesOrderItem.where(:status=> 'active', :product_id=> params[:product_id], :sales_order_id=> params[:sales_order_id])

        @quantity_max = select_product.sum(:quantity)
      end
    end
    def check_status   
      if @shop_floor_order.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @shop_floor_order.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to shop_floor_order_path(:id=> @shop_floor_order.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @shop_floor_order }
          end
        end
      end
    end

    
    def create_batch_number(periode, old_product_id, new_product_id, shop_floor_order_item_id, new_quantity)
      if old_product_id.to_i != new_product_id.to_i
        ProductBatchNumber.where(:shop_floor_order_item_id=> shop_floor_order_item_id, :status=> 'active').each do |product_batch_number|
          product_batch_number.update_columns(:status=> 'suspend')
        end
      end

      product = Product.find_by(:id=> new_product_id)
      outstanding_sterilization = 0
      outstanding_sterilization_out = 0
      if product.present? and product.sterilization
        outstanding_sterilization = new_quantity
        outstanding_sterilization_out = new_quantity
      end

      product_batch_number = ProductBatchNumber.find_by(:shop_floor_order_item_id=> shop_floor_order_item_id, :product_id=> new_product_id, :periode_yyyy=> periode.to_date.strftime("%Y"))
      if product_batch_number.present?
        product_batch_number.update_columns(:status=> 'active') if product_batch_number.status == 'suspend'
      else
        ProductBatchNumber.create(
          :shop_floor_order_item_id=> shop_floor_order_item_id, 
          :product_id=> new_product_id, 
          :number=>  gen_product_batch_number(new_product_id, periode),
          :outstanding=> new_quantity,
          :outstanding_sterilization=> outstanding_sterilization,
          :outstanding_sterilization_out=> outstanding_sterilization_out,
          :outstanding_direct_labor=> new_quantity,
          :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
          )
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shop_floor_order_params
      params.require(:shop_floor_order).permit(:company_profile_id, :number, :sales_order_id, :date, :kind, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end

end
