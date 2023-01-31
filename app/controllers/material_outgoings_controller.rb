class MaterialOutgoingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material_outgoing, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /material_outgoings
  # GET /material_outgoings.json
  def index     
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    material_outgoings = MaterialOutgoing.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['Product Batch Number','product_batch_number_id']]
      @option_filter_records = material_outgoings 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'product_batch_number_id'
          @option_filter_records = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).order("number asc")
        end

        material_outgoings = material_outgoings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    if params[:shop_floor_order_id].present?
      @shop_floor_order_items = @shop_floor_order_items.where(:shop_floor_order_id=> params[:shop_floor_order_id], :status=> 'active')
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :shop_floor_order_item_id=> @shop_floor_order_items)
    end

    case params[:partial]
    when "load_bom_item"
      @inventory_material_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> params[:date].to_date.strftime("%Y%m")).where("material_id > 0").where("end_stock > 0")
      @inventory_product_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> params[:date].to_date.strftime("%Y%m")).where("product_id > 0").where("end_stock > 0")
    end

    case params[:view_kind]
    when 'item'
      material_outgoings = MaterialOutgoingItem.where(:status=> 'active').includes(:material_outgoing).where(:material_outgoings => { :company_profile_id => current_user.company_profile_id }).order("material_outgoings.number desc")
    else
      material_outgoings = material_outgoings.order("number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @material_outgoings = pagy(material_outgoings, page: params[:page], items: pagy_items)

  end

  # GET /material_outgoings/1
  # GET /material_outgoings/1.json
  def show
  end

  # GET /material_outgoings/new
  def new
    @material_outgoing = MaterialOutgoing.new
  end

  # GET /material_outgoings/1/edit
  def edit   
    @shop_floor_order_items = @shop_floor_order_items.where(:shop_floor_order_id=> @material_outgoing.shop_floor_order_id, :status=> 'active')
    @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :shop_floor_order_item_id=> @shop_floor_order_items)
  end

  # POST /material_outgoings
  # POST /material_outgoings.json
  def create
    params[:material_outgoing]["company_profile_id"] = current_user.company_profile_id
    params[:material_outgoing]["created_by"] = current_user.id
    params[:material_outgoing]["created_at"] = DateTime.now()
    params[:material_outgoing]["status"] = 'new'
    params[:material_outgoing]["number"] = document_number(controller_name, params[:material_outgoing]["date"].to_date, nil, nil, nil)
    @material_outgoing = MaterialOutgoing.new(material_outgoing_params)

    respond_to do |format|
      if @material_outgoing.save
        params[:new_record_item].each do |item|
          puts ":material_outgoing_id=> #{@material_outgoing.id},"
          puts ":material_id=> #{item["material_id"]},"
          puts ":material_batch_number_id=> #{item["material_batch_number_id"]},"
          puts ":product_id=> #{item["product_id"]},"
          puts ":product_batch_number_id=> #{item["product_batch_number_id"]},"
          puts ":quantity=> #{item["quantity"]},"
          puts ":remarks=> #{item["remarks"]},"
          transfer_item = MaterialOutgoingItem.new({
            :material_outgoing_id=> @material_outgoing.id,
            :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
            :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
            :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
            :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          transfer_item.save
          puts transfer_item.errors.full_messages
        end if params[:new_record_item].present?
        
        format.html { redirect_to material_outgoing_path(:id=> @material_outgoing.id), notice: "#{@material_outgoing.number} was successfully Created" }
        format.json { render :show, status: :created, location: @material_outgoing }
      else
        format.html { render :new }
        format.json { render json: @material_outgoing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /material_outgoings/1
  # PATCH/PUT /material_outgoings/1.json
  def update
    params[:material_outgoing]["updated_by"] = current_user.id
    params[:material_outgoing]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @material_outgoing.update(material_outgoing_params) 
        MaterialOutgoingItem.where(:material_outgoing_id=> @material_outgoing.id).each do |item|
          item.update_columns(:status=> 'deleted')
        end               
        params[:new_record_item].each do |item|
          transfer_item = MaterialOutgoingItem.find_by({
            :material_outgoing_id=> @material_outgoing.id,
            :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
            :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
            :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
            :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
            :quantity=> item["quantity"]
          })
          if transfer_item.present?
            transfer_item.update_columns({:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> current_user.id})
          else
            transfer_item = MaterialOutgoingItem.create({
              :material_outgoing_id=> @material_outgoing.id,
              :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
              :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
              :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
              :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if params[:new_record_item].present?

        params[:material_outgoing_item].each do |item|
          transfer_item = MaterialOutgoingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            transfer_item.update_columns({
              :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
              :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
              :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
              :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:material_outgoing_item].present?

        format.html { redirect_to material_outgoing_path(:id=> @material_outgoing.id), notice: "#{@material_outgoing.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @material_outgoing }     
      else
        format.html { render :edit }
        format.json { render json: @material_outgoing.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @material_outgoing.date.strftime("%Y%m")
    prev_periode = (@material_outgoing.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @material_outgoing.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @material_outgoing.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @material_outgoing.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @material_outgoing.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      # 2021-11-16: dokumen keluar gudang jika di approve maka akan mengurangi stok
      # stok tidak boleh minus jika di approve
        alert = nil
        @material_outgoing_items.each do |item|
          # 2021-11-16 check stok berdasarkan batch number stok
          if item.material.present?
            # stock = Inventory.find_by(:periode=> periode, :material_id=> item.material_id)
            stock = item.material.current_stock_batch_number(current_user.company_profile_id, item.material_batch_number_id, periode).to_f
          
            if stock.present? and (stock.to_f - item.quantity.to_f) < 0
              alert = "#{item.material.part_id} = #{item.quantity}. Tidak boleh lebih dari stock! #{stock}"
            end
          elsif item.product.present?
            stock = item.product.current_stock_batch_number(current_user.company_profile_id, item.product_batch_number_id, periode).to_f
          
            if stock.present? and (stock.to_f - item.quantity.to_f) < 0
              alert = "#{item.product.part_id} = #{item.quantity}. Tidak boleh lebih dari stock! #{stock}"
            end
          end
        end

      if alert.blank?
        @material_outgoing.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=>current_user.signature})  
        inventory(controller_name, @material_outgoing.id, periode, prev_periode, 'approved')  
      end
    when 'cancel_approve3'
      # 2021-11-16: dokumen keluar gudang jika di cancel maka akan menambah stok
      alert = nil
      if alert.blank?
        @material_outgoing.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=>nil}) 
        inventory(controller_name, @material_outgoing.id, periode, prev_periode, 'canceled')    
      end
    end

    respond_to do |format|
      if alert.present?
        format.html { redirect_to material_outgoing_path(:id=> @material_outgoing.id), alert: "#{alert}" }
      else
        format.html { redirect_to material_outgoing_path(:id=> @material_outgoing.id), notice: "Material Issue was successfully #{@material_outgoing.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    case @material_outgoing.status 
    when 'approved1', 'canceled2'
      # 2022-07-22 Dipta request dikembalikan lagi menjadi print setelah approve1
      # when 'approved3'
      # request dipta, print tampil saat approve 3
      # when 'approved1', 'canceled2'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @material_outgoing
      items  = @material_outgoing_items
      document_number = (header.present? ? header.number : "")
      order_number = (header.shop_floor_order.present? ? header.shop_floor_order.number : "")

      if header.product_batch_number.present?
        product = header.product_batch_number.product
        product_name = (product.present? ? product.name : "")
        product_code = (product.present? ? product.part_id : "")
        product_batch_number = header.product_batch_number.number
        batch_size = (product.present? ? product.max_batch : "")
      end

      name_approved3_by = account_name(header.approved3_by)
      if header.status == 'approved3'  
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

      document_name = "Material Issue"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 163
          tbl_width = [30, 70, 290, 80, 80, 50, 80, 80, 80]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..20).each do 
              part = nil
              batch_number = nil
              if item.material.present?
                part = item.material
                batch_number = (item.material_batch_number.present? ? item.material_batch_number.number : "")
              elsif item.product.present?
                part = item.product
                batch_number = (item.product_batch_number.present? ? item.product_batch_number.number : "")
              end

              y = pdf.y
              pdf.start_new_page if y < 150
              pdf.move_down 163 if y < 150
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=>(part.part_id if part.present?), :align=>:center},
                  {:content=>(part.name if part.present?)},
                  {:content=>batch_number},
                  {:content=>number_with_precision(item.quantity, precision: 2, delimiter: ".", separator: ","), :align=>:right},
                  {:content=>(part.unit_name if part.present?), :align=>:center}
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
                  ["",{:content=> document_name.upcase, :align=> :center}, ""]],
                  :column_widths => [250,340, 250], :cell_style => {:size=> 17, :border_color => "f0f0f0", :background_color => "f0f0f0", :padding=>1})  
                
                pdf.table([
                  ["Product Name", ":", product_name, "Material Issue No.", ":", document_number],
                  ["Product Code", ":", product_code, "Order Number", ":", order_number],
                  ["Product Batch Number", ":", product_batch_number, "Batch Size", ":", batch_size]
                  ], :column_widths => [130, 20, 470, 100, 20, 100], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>5}) 
                
                pdf.move_down 5
                pdf.table([ ["No.","Material Code","Material Name", "Batch Number", "Quantity", "Uom", "Quantity Actual", "Dispatch by", "Received by"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 429
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 300) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 120

                pdf.table([
                  ["Mengetahui", "", ""]
                  ], :column_widths => [340,250, 250], :cell_style => {:size=> 11, :border_color => "ffffff",  :padding=>0})  
                pdf.move_down 10
                pdf.table([
                  ["Material Management:", "Production:", ""]
                  ], :column_widths => [340,250, 250], :cell_style => {:size=> 11, :border_color => "ffffff",  :padding=>0})
                pdf.table([
                  ["", (img_approved3_by.present? ? {:image=>img_approved3_by, :position=>:center, :scale=>0.25, :vposition=>:center, :height=>55} : {:content=>'', :height=>55}), "", ""],
                  ["", {:content=>"( #{name_approved3_by.present? ? name_approved3_by : ' Sign Name '} )"}, "", ""]
                ], :column_widths => [100,120,325, 295], :cell_style => {:size=> 11, :border_color => "ffffff",  :padding=>0, :align=>:center})
                # pdf.move_down 10
                pdf.table([
                  ["",{:content=> "CONFIDENTIAL", :align=> :center}, {:content=> "F-03A-004-Rev 02", :align=> :right}]],
                  :column_widths => [250,340, 250], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})  
               
              }

              pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
        end
      end
    else      
      respond_to do |format|
        format.html { redirect_to @material_outgoing, alert: 'Cannot be displayed, status must be Approve 1' }
        format.json { render :show, status: :ok, location: @material_outgoing }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /material_outgoings/1
  # DELETE /material_outgoings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to material_outgoings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_outgoing
      @material_outgoing = MaterialOutgoing.find_by(:id=> params[:id])
      if @material_outgoing.present?
        @material_outgoing_items = MaterialOutgoingItem.where(:status=> 'active').includes(:material_outgoing).where(:material_outgoings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("material_outgoings.number desc")
      else
        respond_to do |format|
          format.html { redirect_to material_outgoings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @shop_floor_orders = ShopFloorOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
      @shop_floor_order_items = ShopFloorOrderItem.where(:shop_floor_order_id=> @shop_floor_orders, :status=> 'active')
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :shop_floor_order_item_id=> @shop_floor_order_items)
      @bill_of_material_items = BillOfMaterialItem.where(:status=> 'active').includes(:bill_of_material).where(:bill_of_materials => {:product_id=> params[:product_id], :company_profile_id => current_user.company_profile_id })
      @bom_wip = BillOfMaterial.find_by(:company_profile_id=> current_user.company_profile_id, :product_id=> params[:product_id])

      @wip1_bom_items = nil
      @wip2_bom_items = nil
      if @bom_wip.present?
        @wip1_bom_items = BillOfMaterialItem.where(:status=> 'active').includes(:bill_of_material).where(:bill_of_materials => {:product_id=> @bom_wip.product_wip1_id, :company_profile_id => current_user.company_profile_id }) if @bom_wip.product_wip1.present? and @bom_wip.product_wip1_prf == 'yes'
        @wip2_bom_items = BillOfMaterialItem.where(:status=> 'active').includes(:bill_of_material).where(:bill_of_materials => {:product_id=> @bom_wip.product_wip2_id, :company_profile_id => current_user.company_profile_id }) if @bom_wip.product_wip2.present? and @bom_wip.product_wip2_prf == 'yes'
      end
      
      @material_receivings = MaterialReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=>'approved3')
      @material_receiving_items = MaterialReceivingItem.where(:material_receiving_id=> @material_receivings, :status=> 'active')
      # @material_batch_number = MaterialBatchNumber.where(:status=> 'active', :material_receiving_item_id=> @material_receiving_items)
      @inventory_material_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> DateTime.now().strftime("%Y%m")).where("material_id > 0").where("end_stock > 0")
      @inventory_product_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> DateTime.now().strftime("%Y%m")).where("product_id > 0").where("end_stock > 0")
      
    end
    def check_status      
      if @material_outgoing.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @material_outgoing.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @material_outgoing, notice: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @material_outgoing }
          end
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def material_outgoing_params
      params.require(:material_outgoing).permit(:company_profile_id, :number, :date, :shop_floor_order_id, :product_batch_number_id, :status, :created_by, :created_at, :updated_by, :updated_at)
    end

end
