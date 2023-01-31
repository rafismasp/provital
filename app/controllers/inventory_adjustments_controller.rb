class InventoryAdjustmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inventory_adjustment, only: [:show, :edit, :update, :destroy, :approve, :print]
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


  # GET /inventory_adjustments
  # GET /inventory_adjustments.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    inventory_adjustments = InventoryAdjustment.where("date between ? and ?", session[:date_begin], session[:date_end])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']]
      @option_filter_records = inventory_adjustments 
      
      if params[:filter_column].present?
        inventory_adjustments = inventory_adjustments.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      inventory_adjustments = InventoryAdjustmentItem.where(:status=> 'active').includes(:inventory_adjustment).where(:inventory_adjustments => { :company_profile_id => current_user.company_profile_id }).order("inventory_adjustments.number desc")
    else
      inventory_adjustments = inventory_adjustments.order("number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @inventory_adjustments = pagy(inventory_adjustments, page: params[:page], items: pagy_items) 
  end
  # GET /inventory_adjustments/1
  # GET /inventory_adjustments/1.json
  def show
  end

  # GET /inventory_adjustments/new
  def new
    @inventory_adjustment = InventoryAdjustment.new
  end

  # GET /inventory_adjustments/1/edit
  def edit
  end

  # POST /inventory_adjustments
  # POST /inventory_adjustments.json
  def create
    params[:inventory_adjustment]['company_profile_id'] = current_user.company_profile_id
    params[:inventory_adjustment]["created_by"] = current_user.id
    params[:inventory_adjustment]["created_at"] = DateTime.now()
    params[:inventory_adjustment]["number"] = document_number(controller_name, params[:inventory_adjustment]["date"].to_date, nil, nil, nil)
    @inventory_adjustment = InventoryAdjustment.new(inventory_adjustment_params)
    kind = params[:inventory_adjustment]["kind"]
    periode = params[:inventory_adjustment]["date"].to_date.strftime("%Y%m")
    respond_to do |format|
      params[:new_record_item].each do |item|
        stock_bn = InventoryBatchNumber.find_by("#{kind}_batch_number_id".to_sym => item["#{kind}_batch_number_id"], :periode=> periode)
        current_stock = (stock_bn.present? ? stock_bn.end_stock : 0)
        @inventory_adjustment.inventory_adjustment_items.build({
          :inventory_adjustment_id=> @inventory_adjustment.id,
          "#{kind}_id".to_sym => item["#{kind}_id"],
          "#{kind}_batch_number_id".to_sym => item["#{kind}_batch_number_id"],
          :quantity=> item["quantity"],
          :stock_quantity=> current_stock,
          :remarks=> item["remarks"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })
      end if params[:new_record_item].present?
      if @inventory_adjustment.save
        format.html { redirect_to inventory_adjustment_path(:id=> @inventory_adjustment.id), notice: "#{@inventory_adjustment.number} was successfully created." }
        format.json { render :show, status: :created, location: @inventory_adjustment }
      else
        format.html { render :new }
        format.json { render json: @inventory_adjustment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory_adjustments/1
  # PATCH/PUT /inventory_adjustments/1.json
  def update
    params[:inventory_adjustment]["updated_by"] = current_user.id
    params[:inventory_adjustment]["updated_at"] = DateTime.now()
    params[:inventory_adjustment]["number"] = @inventory_adjustment.number
    kind = @inventory_adjustment.kind
    periode = @inventory_adjustment.date.to_date.strftime("%Y%m")
    respond_to do |format|
      if @inventory_adjustment.update(inventory_adjustment_params)                
        params[:new_record_item].each do |item|
          stock_bn = InventoryBatchNumber.find_by("#{kind}_batch_number_id".to_sym => item["#{kind}_batch_number_id"], :periode=> periode)
          current_stock = (stock_bn.present? ? stock_bn.end_stock : 0)
          transfer_item = InventoryAdjustmentItem.create({
            :inventory_adjustment_id=> @inventory_adjustment.id,
            "#{kind}_id".to_sym => item["#{kind}_id"],
            "#{kind}_batch_number_id".to_sym => item["#{kind}_batch_number_id"],
            :stock_quantity=> current_stock,
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?
        params[:inventory_adjustment_item].each do |item|
          transfer_item = InventoryAdjustmentItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            stock_bn = InventoryBatchNumber.find_by("#{kind}_batch_number_id".to_sym => item["#{kind}_batch_number_id"], :periode=> periode)
            current_stock = (stock_bn.present? ? stock_bn.end_stock : 0)
            transfer_item.update_columns({
              "#{kind}_id".to_sym => item["#{kind}_id"],
              "#{kind}_batch_number_id".to_sym => item["#{kind}_batch_number_id"],
              :stock_quantity=> current_stock,
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:inventory_adjustment_item].present?

        format.html { redirect_to inventory_adjustment_path(:id=> @inventory_adjustment.id), notice: "#{@inventory_adjustment.number} was successfully created." }
        format.json { render :show, status: :ok, location: @inventory_adjustment }      
      else
        format.html { render :edit }
        format.json { render json: @inventory_adjustment.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @inventory_adjustment.date.strftime("%Y%m")
    prev_periode = (@inventory_adjustment.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @inventory_adjustment.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @inventory_adjustment.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @inventory_adjustment.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @inventory_adjustment.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @inventory_adjustment.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})  
      inventory(controller_name, @inventory_adjustment.id, periode, prev_periode, 'approved')
    when 'cancel_approve3'
      @inventory_adjustment.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
      inventory(controller_name, @inventory_adjustment.id, periode, prev_periode, 'canceled')    
    end

    respond_to do |format|
      if alert.present?
        format.html { redirect_to inventory_adjustment_path(:id=> @inventory_adjustment.id), alert: "#{alert}" }
      else
        format.html { redirect_to inventory_adjustment_path(:id=> @inventory_adjustment.id), notice: "#{@inventory_adjustment.number} was successfully #{@inventory_adjustment.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    if @inventory_adjustment.status == 'approved3'
      sop_number      = "SOP-03C-005"
      form_number     = "F-03C-021-Rev 00"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @inventory_adjustment
      items  = @inventory_adjustment_items
      order_number = nil

      document_name = "Finished Goods Receiving Note"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 120
          tbl_width = [30,100, 70, 430, 80, 80, 50]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..20).each do 
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
              pdf.start_new_page if y < 150
              pdf.move_down 120 if y < 150
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=> order_number, :align=>:center},
                  {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                  {:content=>(item.product.name if item.product.present?)},
                  {:content=>(item.product_batch_number.number if item.product_batch_number.present?)},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right},
                  {:content=>(item.product.unit.name if item.product.present? and item.product.unit.present?), :align=>:center}
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
                  :column_widths => [250,340, 250], :cell_style => {:size=> 17, :border_color => "f0f0f0", :background_color => "f0f0f0", :padding=>1})  
                
                pdf.table([
                  ["FGRN Number", ":", header.number, "Date", ":", header.date]
                  # ["Order Number", ":", order_number, "", "", ""]
                  ], :column_widths => [130, 20, 470, 100, 20, 100], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>5}) 
                
                pdf.move_down 5
                pdf.table([ ["No.","Order Number","Product Code","Product Name", "Batch No.", "Quantity", "Unit"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 472
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 350) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 120
   
                pdf.move_down 10
                pdf.table([
                  ["","Submitted by,", "", "Received by,",""]
                  ], :column_widths => [30, 100, 580, 100, 30], :cell_style => {:size=> 11, :border_color => "ffffff",  :padding=>0})

                pdf.move_down 70
                pdf.table([
                  ["",{:content=> "CONFIDENTIAL", :align=> :center}, {:content=> form_number, :align=> :right}]],
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
        format.html { redirect_to @inventory_adjustment, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @inventory_adjustment }
      end
    end
  end

  def import
    if params[:upload].present?
      require 'roo'
      logger.info "path: #{params[:upload][:file].as_json}"
      workbook = Roo::Spreadsheet.open("#{params[:upload][:file].path}", extension: :xlsx)
      new_array = Array.new()
      c = 0
      # logger.info workbook.sheets
      sheet_name = workbook.sheets[0]
      
      case sheet_name
      when 'product', 'material'
        workbook.sheet(0).each do |row|
          # logger.info "row=> #{row}"
          inventory_batch_number = InventoryBatchNumber.find_by(:id=> row[1])
          if inventory_batch_number.present?
            part = nil
            if inventory_batch_number.product.present?
              part = inventory_batch_number.product
            elsif inventory_batch_number.material.present?
              part = inventory_batch_number.material
            end

            new_array.push({
              :counter=> "#{c+=1}",
              :inventory_batch_number_id=> inventory_batch_number.id,
              :product_id=> inventory_batch_number.product_id,
              :material_id=> inventory_batch_number.material_id,
              :product_batch_number_id=> inventory_batch_number.product_batch_number_id,
              :material_batch_number_id=> inventory_batch_number.material_batch_number_id,
              :part_name=> row[2],
              :part_id=> row[3],
              :part_type_name=> inventory_batch_number.product.present? ? inventory_batch_number.product.type_name : nil,
              :part_unit_name=> part.present? ? part.unit_name : nil,
              :batch_number=> row[4],
              :end_stock=> row[6],
              :actual_stock=> row[7]
            })
          end
        end
      else
        flash[:error] = 'Sheet name must be product or material'
      end
      @import_results = new_array
      @inventory_adjustment = InventoryAdjustment.new({:kind=> sheet_name})
      logger.info "sheet_name=> #{sheet_name}"

      # redirect_to new_inventory_adjustment_url(@import_results)
    else
      redirect_to new_inventory_adjustment_path
    end
    # logger.info "@import_results:=> #{@import_results}"
  end

  def export
    logger.info "kind: #{params[:kind]}"
    case params[:kind]
    when 'master'
      filename = 'Master Import Adjustment'
      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook
      part_kinds = ['product','material']
      part_kinds.each do |kind|
        wb.add_worksheet(name: kind) do |sheet|
          c = 0
          inventory_batch_number_lists = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> DateTime.now().strftime("%Y%m")).where("#{kind}_id > 0").includes(:material, :product, :material_batch_number, :product_batch_number)
          sheet.add_row ["No.","inventory_batch_number_id","Part Name","Part ID","Batch Number", "periode","Stok Akhir", "Stok seharusnya"]
               
          inventory_batch_number_lists.each do |item|
            sheet.add_row ["#{c+=1}","#{item.id}",
              "#{item.try("#{kind}").name if item.try("#{kind}").present?}",
              "#{item.try("#{kind}").part_id if item.try("#{kind}").present?}",
              "#{item.try("#{kind}_batch_number").number if item.try("#{kind}_batch_number").present?}",
              "#{item.periode}","#{item.end_stock}", nil
            ]
          end
        end
      end

      filename_xlsx = filename.upcase+"_"+DateTime.now.strftime(" %Y%m%d_%H%M%S")+".xlsx"
      send_data axlsx_package.to_stream.read, :type => "application/vnd.ms-excel", :filename => filename_xlsx, :stream => true
    else
      template_report(controller_name, current_user.id, nil)
    end
  end

  # DELETE /inventory_adjustments/1
  # DELETE /inventory_adjustments/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to inventory_adjustments_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory_adjustment
      @inventory_adjustment = InventoryAdjustment.find_by(:id=> params[:id])
      if @inventory_adjustment.present?
        @inventory_adjustment_items = InventoryAdjustmentItem.where(:status=> 'active')
        .includes(:inventory_adjustment, :product_batch_number, :material_batch_number, material:[:unit], product:[:unit])
        .where(:inventory_adjustments => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("inventory_adjustments.number desc")
      else
        respond_to do |format|
          format.html { redirect_to inventory_adjustments_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @product_batch_number = ProductBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @inventory_product_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> DateTime.now().strftime("%Y%m")).where("product_id > 0").where("end_stock > 0")
    
      @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @material_batch_number = MaterialBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @inventory_material_batch_number = InventoryBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :periode=> DateTime.now().strftime("%Y%m")).where("material_id > 0").where("end_stock > 0")
    end
    
    def check_status      
      if @inventory_adjustment.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @inventory_adjustment.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @inventory_adjustment, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @inventory_adjustment }
          end
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def inventory_adjustment_params
      params.require(:inventory_adjustment).permit(:number, :company_profile_id, :date, :kind, :shop_floor_order_id, :created_by, :created_at, :updated_by, :updated_at)
    end

end
