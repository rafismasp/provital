class SemiFinishGoodOutgoingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_semi_finish_good_outgoing, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /semi_finish_good_outgoings
  # GET /semi_finish_good_outgoings.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    semi_finish_good_outgoings = SemiFinishGoodOutgoing.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']]
      @option_filter_records = semi_finish_good_outgoings 
      
      if params[:filter_column].present?
        semi_finish_good_outgoings = semi_finish_good_outgoings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    if params[:product_batch_number_id].present?
      @sfo_number = ProductBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').find_by(:id=> params[:product_batch_number_id]) 
      @sfos_number = ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> params[:product_batch_number_id], :status=> 'active').map { |e| e.shop_floor_order_sterilization.number }.join(", ")
    end

    case params[:view_kind]
    when 'item'
      semi_finish_good_outgoings = SemiFinishGoodOutgoingItem.where(:status=> 'active').includes(:semi_finish_good_outgoing).where(:semi_finish_good_outgoings => { :company_profile_id => current_user.company_profile_id }).order("semi_finish_good_outgoings.number desc")
    else
      semi_finish_good_outgoings = semi_finish_good_outgoings.order("number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @semi_finish_good_outgoings = pagy(semi_finish_good_outgoings, page: params[:page], items: pagy_items) 
  end

  # GET /semi_finish_good_outgoings/1
  # GET /semi_finish_good_outgoings/1.json
  def show
  end

  # GET /semi_finish_good_outgoings/new
  def new
    @semi_finish_good_outgoing = SemiFinishGoodOutgoing.new
  end

  # GET /semi_finish_good_outgoings/1/edit
  def edit
  end

  # POST /semi_finish_good_outgoings
  # POST /semi_finish_good_outgoings.json
  def create
    params[:semi_finish_good_outgoing]["company_profile_id"] = current_user.company_profile_id
    params[:semi_finish_good_outgoing]["created_by"] = current_user.id
    params[:semi_finish_good_outgoing]["created_at"] = DateTime.now()
    params[:semi_finish_good_outgoing]["number"] = document_number(controller_name, params[:semi_finish_good_outgoing]["date"].to_date, nil, nil, nil)
    @semi_finish_good_outgoing = SemiFinishGoodOutgoing.new(semi_finish_good_outgoing_params)

    respond_to do |format|
      if @semi_finish_good_outgoing.save
        params[:new_record_item].each do |item|
          transfer_item = SemiFinishGoodOutgoingItem.create({
            :semi_finish_good_outgoing_id=> @semi_finish_good_outgoing.id,
            :product_id=> item["product_id"],
            :product_batch_number_id=> item["product_batch_number_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?

        format.html { redirect_to semi_finish_good_outgoing_path(:id=> @semi_finish_good_outgoing.id), notice: "#{@semi_finish_good_outgoing.number} was successfully created." }
        format.json { render :show, status: :created, location: @semi_finish_good_outgoing }
      else
        format.html { render :new }
        format.json { render json: @semi_finish_good_outgoing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /semi_finish_good_outgoings/1
  # PATCH/PUT /semi_finish_good_outgoings/1.json
  def update
    respond_to do |format|
      params[:semi_finish_good_outgoing]["updated_by"] = current_user.id
      params[:semi_finish_good_outgoing]["updated_at"] = DateTime.now()
      params[:semi_finish_good_outgoing]["date"] = @semi_finish_good_outgoing.date
      params[:semi_finish_good_outgoing]["number"] = @semi_finish_good_outgoing.number
      if @semi_finish_good_outgoing.update(semi_finish_good_outgoing_params)                
        params[:new_record_item].each do |item|
          transfer_item = SemiFinishGoodOutgoingItem.create({
            :semi_finish_good_outgoing_id=> @semi_finish_good_outgoing.id,
            :product_id=> item["product_id"],
            :product_batch_number_id=> item["product_batch_number_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?
        params[:semi_finish_good_outgoing_item].each do |item|
          transfer_item = SemiFinishGoodOutgoingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            transfer_item.update_columns({
              :product_id=> item["product_id"],
              :product_batch_number_id=> item["product_batch_number_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:semi_finish_good_outgoing_item].present?

        format.html { redirect_to semi_finish_good_outgoings_path(:q=> params[:q], :q1=> params[:q1], :q2=> params[:q2]), notice: 'Internal transfer was successfully updated.' }
        format.json { render :show, status: :ok, location: @semi_finish_good_outgoing }      
      else
        format.html { render :edit }
        format.json { render json: @semi_finish_good_outgoing.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @semi_finish_good_outgoing.date.strftime("%Y%m")
    prev_periode = (@semi_finish_good_outgoing.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @semi_finish_good_outgoing.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @semi_finish_good_outgoing.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @semi_finish_good_outgoing.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @semi_finish_good_outgoing.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      alert = nil
      @semi_finish_good_outgoing_items.each do |item|
        if item.product_batch_number.present? 
          if (item.product_batch_number.outstanding_sterilization_out.to_f - item.quantity.to_f) < 0
            alert = "#{item.product_batch_number.number} outstanding FGRN #{item.product_batch_number.outstanding_sterilization_out}"
          end        
        end
      end

      if alert.blank?
        # 2022-12-19 aden: disable cek stok bn
        # check stock
        # alert = nil
        # if current_user.id.to_i == 1
        #   # tanpa cek stok
        # else
        #   @semi_finish_good_outgoing_items.each do |item|
        #     if item.product.present? and (item.product.current_stock_batch_number(current_user.company_profile_id, item.product_batch_number_id, periode).to_f - item.quantity.to_f) < 0
        #       alert = "#{item.product.part_id} Tidak boleh lebih dari stock!"
        #     end
        #   end
        # end

        if alert.blank?
          @semi_finish_good_outgoing.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})  
          inventory(controller_name, @semi_finish_good_outgoing.id, periode, prev_periode, 'approved')
          @semi_finish_good_outgoing_items.each do |item|
            product_bn = ProductBatchNumber.find_by(:id=> item.product_batch_number_id, :status=> 'active')
            if product_bn.present?
              product_bn.update({:outstanding_sterilization_out=> (product_bn.outstanding_sterilization_out.to_f - item.quantity.to_f)})
            end
          end
        end
      end
    when 'cancel_approve3'
      @semi_finish_good_outgoing.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
      inventory(controller_name, @semi_finish_good_outgoing.id, periode, prev_periode, 'canceled')
      @semi_finish_good_outgoing_items.each do |item|
        product_bn = ProductBatchNumber.find_by(:id=> item.product_batch_number_id, :status=> 'active')
        if product_bn.present?
          product_bn.update({:outstanding_sterilization_out=> (product_bn.outstanding_sterilization_out.to_f + item.quantity.to_f)})
        end
      end
    end

    respond_to do |format|
      if alert.present?
        format.html { redirect_to semi_finish_good_outgoing_path(:id=> @semi_finish_good_outgoing.id), alert: "#{alert}" }
      else
        format.html { redirect_to semi_finish_good_outgoing_path(:id=> @semi_finish_good_outgoing.id), notice: "Internal transfer was successfully #{@semi_finish_good_outgoing.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    if @semi_finish_good_outgoing.status == 'approved3'
      sop_number      = "SOP-03C-005"
      form_number     = "F-03C-021-Rev 00"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @semi_finish_good_outgoing
      items  = @semi_finish_good_outgoing_items
      order_number = nil

      document_name = "Semi Finished Goods for Sterilizations"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 120
          tbl_width = [30,100, 110, 70, 320, 80, 80, 50]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..20).each do 
              sfos_number = @shop_floor_order_sterilization_items.where(:product_batch_number_id=> item.product_batch_number_id, :status=> 'active' ).map { |e| e.shop_floor_order_sterilization.number }.join(", ")
              
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
                  {:content=> sfos_number, :align=>:center},
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
                  ["SFS Number", ":", header.number, "Date", ":", header.date]
                  # ["Order Number", ":", order_number, "", "", ""]
                  ], :column_widths => [130, 20, 470, 100, 20, 100], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>5}) 
                
                pdf.move_down 5
                pdf.table([ ["No.","Order Number","Sterilization","Product Code","Product Name", "Batch No.", "Quantity", "Unit"]], 
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
        format.html { redirect_to @semi_finish_good_outgoing, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @semi_finish_good_outgoing }
      end
    end
  end


  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /semi_finish_good_outgoings/1
  # DELETE /semi_finish_good_outgoings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to semi_finish_good_outgoings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_semi_finish_good_outgoing
      @semi_finish_good_outgoing = SemiFinishGoodOutgoing.find_by(:id=> params[:id])
      if @semi_finish_good_outgoing.present?
        @semi_finish_good_outgoing_items = SemiFinishGoodOutgoingItem.where(:status=> 'active').includes(:semi_finish_good_outgoing).where(:semi_finish_good_outgoings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("semi_finish_good_outgoings.number desc")      
      else
        respond_to do |format|
          format.html { redirect_to semi_finish_good_outgoings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active', :product_item_category_id=> 3)
      @shop_floor_order_sterilizations = ShopFloorOrderSterilization.where(:company_profile_id=> current_user.company_profile_id)
      @shop_floor_order_sterilization_items = ShopFloorOrderSterilizationItem.where(:shop_floor_order_sterilization_id=> @shop_floor_order_sterilizations, :status=> 'active')
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :id=> @shop_floor_order_sterilization_items.where("outstanding > 0").select(:product_batch_number_id)).where("outstanding_sterilization_out > 0").includes(product: [:unit, :product_type])
    end
    def check_status      
      if @semi_finish_good_outgoing.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @semi_finish_good_outgoing.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @semi_finish_good_outgoing, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @semi_finish_good_outgoing }
          end
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def semi_finish_good_outgoing_params
      params.require(:semi_finish_good_outgoing).permit(:company_profile_id, :number, :date, :created_by, :created_at, :updated_by, :updated_at)
    end

end
