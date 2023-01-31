class SterilizationProductReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sterilization_product_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
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
  
  # GET /sterilization_product_receivings
  # GET /sterilization_product_receivings.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    sterilization_product_receivings = SterilizationProductReceiving.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin]..session[:date_end])
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, sales_order: [:customer])
    .order("sterilization_product_receivings.number desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['Customer Name','customer_id'],['PO Number','po_number']]
      case params[:filter_column]
      when 'po_number'
        @option_filter_records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
      when 'customer_id'
        @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      else
        @option_filter_records = sterilization_product_receivings 
      end

      if params[:filter_column].present?
        case params[:filter_column]
        when 'po_number', 'customer_id'
          sterilization_product_receivings = sterilization_product_receivings.where(:sales_orders=> {"#{params[:filter_column]}".to_sym=> params[:filter_value]})
        else
          sterilization_product_receivings = sterilization_product_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
        end
      end
    # filter select - end
    if params[:customer_id].present?
      @sales_orders = @sales_orders.where(:customer_id=> params[:customer_id]).order("date desc")
    end

    if params[:sales_order_id].present?
      # @products    = @products.where(:id=> SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]).select(:product_id))

      @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :customer_id=> params[:customer_id]).where("outstanding > 0") if params[:customer_id].present?
      @sales_order_items = SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]) if params[:sales_order_id].present?
      # @sales_order_items = SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]).where("outstanding > 0") if params[:sales_order_id].present?
    
    end


    case params[:view_kind]
    when 'item'
      sterilization_product_receiving_items = SterilizationProductReceivingItem.where(:sterilization_product_receiving_id=> sterilization_product_receivings, :status=> 'active')
      sterilization_product_receivings    = sterilization_product_receiving_items 
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @sterilization_product_receivings = pagy(sterilization_product_receivings, page: params[:page], items: pagy_items)
  end

  # GET /sterilization_product_receivings/1
  # GET /sterilization_product_receivings/1.json
  def show
  end

  # GET /sterilization_product_receivings/new
  def new
    @sterilization_product_receiving = SterilizationProductReceiving.new
  end

  # GET /sterilization_product_receivings/1/edit
  def edit
    @sales_orders = @sales_orders.where(:customer_id=> @sterilization_product_receiving.sales_order.customer_id)
  end

  # POST /sterilization_product_receivings
  # POST /sterilization_product_receivings.json
  def create    
    params[:sterilization_product_receiving]["company_profile_id"] = current_user.company_profile_id
    params[:sterilization_product_receiving]["created_by"] = current_user.id
    params[:sterilization_product_receiving]["created_at"] = DateTime.now()
    params[:sterilization_product_receiving]["number"] = document_number(controller_name, params[:sterilization_product_receiving]["date"].to_date, nil, nil, nil)
    @sterilization_product_receiving = SterilizationProductReceiving.new(sterilization_product_receiving_params)
    periode = params[:sterilization_product_receiving]["date"]
    respond_to do |format|
      if @sterilization_product_receiving.save
        params[:new_record_item].each do |item|
          product = Product.find_by(:id=> item["product_id"])
          outstanding_sterilization = 0
          outstanding_sterilization_out = 0
          if product.present? and product.sterilization
            outstanding_sterilization = item["quantity"]
            outstanding_sterilization_out = item["quantity"]
          end
          transfer_item = SterilizationProductReceivingItem.create({
            :sterilization_product_receiving_id=> @sterilization_product_receiving.id,
            :sales_order_item_id=> item["sales_order_item_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> transfer_item.id, :product_id=> item["product_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
          if product_batch_number.blank?
            ProductBatchNumber.create(
              :sterilization_product_receiving_item_id=> transfer_item.id, 
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

        SterilizationProductReceivingItem.where(:sterilization_product_receiving_id=> @sterilization_product_receiving.id, :status=> 'active').each do |item|
          product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> item.id)
          item.update({:product_batch_number_id=> product_batch_number.id}) if product_batch_number.present?
          puts item.errors.full_messages
        end
        format.html { redirect_to sterilization_product_receiving_path(:id=> @sterilization_product_receiving.id), notice: "#{@sterilization_product_receiving.number} was successfully created" }
        format.json { render :show, status: :created, location: @sterilization_product_receiving }
      else
        format.html { render :new }
        format.json { render json: @sterilization_product_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sterilization_product_receivings/1
  # PATCH/PUT /sterilization_product_receivings/1.json
  def update
    respond_to do |format|
      params[:sterilization_product_receiving]["updated_by"] = current_user.id
      params[:sterilization_product_receiving]["updated_at"] = DateTime.now()
      params[:sterilization_product_receiving]["date"] = @sterilization_product_receiving.date
      params[:sterilization_product_receiving]["number"] = @sterilization_product_receiving.number
      periode = params[:sterilization_product_receiving]["date"]

      if @sterilization_product_receiving.update(sterilization_product_receiving_params)                
        params[:new_record_item].each do |item|
          product = Product.find_by(:id=> item["product_id"])
          outstanding_sterilization = 0
          outstanding_sterilization_out = 0
          if product.present? and product.sterilization
            outstanding_sterilization = item["quantity"]
            outstanding_sterilization_out = item["quantity"]
          end
          transfer_item = SterilizationProductReceivingItem.find_by({
            :sterilization_product_receiving_id=> @sterilization_product_receiving.id,
            :sales_order_item_id=> item["sales_order_item_id"]
          })
          if transfer_item.blank?
            transfer_item = SterilizationProductReceivingItem.create({
              :sterilization_product_receiving_id=> @sterilization_product_receiving.id,
              :sales_order_item_id=> item["sales_order_item_id"],
              :product_id=> item["product_id"],
              :quantity=> item["quantity"],
              :outstanding=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> transfer_item.id, :product_id=> item["product_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
            if product_batch_number.blank?
              ProductBatchNumber.create(
                :sterilization_product_receiving_item_id=> transfer_item.id, 
                :product_id=> item["product_id"], 
                :number=>  gen_product_batch_number(item["product_id"], periode),
                :outstanding=> item["quantity"],
                :outstanding_sterilization=> outstanding_sterilization,
                :outstanding_sterilization_out=> outstanding_sterilization_out,
                :outstanding_direct_labor=> item["quantity"],
                :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
                )
            end 
          else
            if transfer_item.quantity == transfer_item.outstanding
              # jika tidak ada perubahan quantity
              transfer_item.update({
                :quantity=> item["quantity"],
                :outstanding=> item["quantity"],
                :remarks=> item["remarks"],
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
              product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> transfer_item.id)
              if product_batch_number.present?
                product_batch_number.update({
                  :status=> 'active',
                  :outstanding=> item["quantity"],
                  :outstanding_sterilization=> outstanding_sterilization,
                  :outstanding_sterilization_out=> outstanding_sterilization_out,
                  :outstanding_direct_labor=> item["quantity"]
                })
              end
            end
          end  
        end if params[:new_record_item].present?

        params[:sterilization_product_receiving_item].each do |item|
          transfer_item = SterilizationProductReceivingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
            product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> transfer_item.id, :status=> 'active')
            product_batch_number.update({:status=> 'suspend'}) if product_batch_number.present?
          else
            if transfer_item.quantity == transfer_item.outstanding
              outstanding_sterilization = 0
              outstanding_sterilization_out = 0
              if transfer_item.product.present? and transfer_item.product.sterilization
                outstanding_sterilization = item["quantity"]
                outstanding_sterilization_out = item["quantity"]
              end
              transfer_item.update({
                :product_id=> item["product_id"],
                :quantity=> item["quantity"],
                :outstanding=> item["quantity"],
                :remarks=> item["remarks"],
                :status=> item["status"],
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
              product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> transfer_item.id)
              if product_batch_number.present?
                product_batch_number.update({
                  :status=> 'active',
                  :outstanding=> item["quantity"],
                  :outstanding_sterilization=> outstanding_sterilization,
                  :outstanding_sterilization_out=> outstanding_sterilization_out,
                  :outstanding_direct_labor=> item["quantity"]
                })
              end
            end
          end if transfer_item.present?
        end if params[:sterilization_product_receiving_item].present?

        SterilizationProductReceivingItem.where(:sterilization_product_receiving_id=> @sterilization_product_receiving.id, :status=> 'active').each do |item|
          product_batch_number = ProductBatchNumber.find_by(:sterilization_product_receiving_item_id=> item.id)
          item.update({:product_batch_number_id=> product_batch_number.id}) if product_batch_number.present?
          puts item.errors.full_messages
        end
        format.html { redirect_to sterilization_product_receivings_path(), notice: 'SFO was successfully updated.' }
        format.json { render :show, status: :ok, location: @sterilization_product_receiving }      
      else
        format.html { render :edit }
        format.json { render json: @sterilization_product_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @sterilization_product_receiving.date.strftime("%Y%m")
    prev_periode = (@sterilization_product_receiving.date.to_date-1.month()).strftime("%Y%m")
    case params[:status]
    when 'approve1'
      @sterilization_product_receiving.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @sterilization_product_receiving.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @sterilization_product_receiving.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @sterilization_product_receiving.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @sterilization_product_receiving.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
      inventory(controller_name, @sterilization_product_receiving.id, periode, prev_periode, 'approved')
    when 'cancel_approve3'

      # jika dokumen masuk gudang di cancel dan stok menjadi minus

        alert = nil
        # dokumen ini tidak nambah stok
        # @sterilization_product_receiving_items.each do |item|
        #   stock = nil
        #   part_id = nil
        #   if item.product.present?
        #     stock = Inventory.find_by(:periode=> periode, :product_id=> item.product_id)
        #     part_id = item.product.part_id
        #   end
        #   if stock.present? and (stock.end_stock.to_f - item.quantity.to_f) < 0
        #     alert = "#{part_id} Tidak boleh lebih dari stock!"
        #   end
        # end

      if alert.blank?
        @sterilization_product_receiving.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
        inventory(controller_name, @sterilization_product_receiving.id, periode, prev_periode, 'canceled')    
      end

    end
    if alert.present?
      notice_msg = alert
    else
      notice_msg = "SFO was successfully #{@sterilization_product_receiving.status}."
    end
    respond_to do |format|
      format.html { redirect_to sterilization_product_receiving_path(:id=> @sterilization_product_receiving.id), notice: notice_msg }
      format.json { head :no_content }
    end
  end

  def print
    if @sterilization_product_receiving.status == 'approved3'
      sop_number      = "SOP-03A-001"

      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @sterilization_product_receiving
      items  = @sterilization_product_receiving_items
      po_number = (header.sales_order.present? ? header.sales_order.po_number : "")
      
      form_number     = "F-03A-003 Rev 02"
      document_name = "Sterilization Product Receipt Note"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

            pdf.move_down 143

          tbl_width = [30, 70, 530, 80, 80, 50]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..20).each do 
              product_batch_number = ProductBatchNumber.where(:status=> 'active', :sterilization_product_receiving_item_id=> item.id).map { |e| e.number }.join(", ").to_s
              y = pdf.y
              pdf.start_new_page if y < 150

                pdf.move_down 143 if y < 150

              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                  {:content=>(item.product.name if item.product.present?)},
                  {:content=> product_batch_number},
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
                  :column_widths => [150,540, 150], :cell_style => {:size=> 17, :border_color => "f0f0f0", :background_color => "f0f0f0", :padding=>1})  
                
                  pdf.table([
                    ["Customer PO Number", ":", po_number, "", "", ""],
                    ["SPR Number", ":", header.number, "", "", ""]
                    ], :column_widths => [130, 20, 470, 100, 20, 100], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>5}) 
               
                pdf.move_down 5
                pdf.table([ ["No.","Product Code","Product Name", "Batch No.", "Quantity", "Unit"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
                den_row = 0
                tbl_top_position = 450
                bound_height = 330

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
                  ["","", "", "Prepared by,",""]
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
        format.html { redirect_to @sterilization_product_receiving, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @sterilization_product_receiving }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /sterilization_product_receivings/1
  # DELETE /sterilization_product_receivings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to sterilization_product_receivings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sterilization_product_receiving
      @sterilization_product_receiving = SterilizationProductReceiving.find_by(:id=> params[:id])
      if @sterilization_product_receiving.present?
        @sterilization_product_receiving_items = SterilizationProductReceivingItem.where(:status=> 'active').includes(:sterilization_product_receiving).where(:sterilization_product_receivings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("sterilization_product_receivings.number desc") 
      else                
        respond_to do |format|
          format.html { redirect_to sterilization_product_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      # hanya menampilkan product berkategory Sterilization
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').only_sterilization
      @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where(:service_type_str=> 1)
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
    end
    def check_status   
      if @sterilization_product_receiving.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @sterilization_product_receiving.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to sterilization_product_receiving_path(:id=> @sterilization_product_receiving.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @sterilization_product_receiving }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sterilization_product_receiving_params
      params.require(:sterilization_product_receiving).permit(:company_profile_id, :number, :sales_order_id, :date, :kind, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end

end
