class ShopFloorOrderSterilizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shop_floor_order_sterilization, only: [:show, :edit, :update, :destroy, :approve, :print]
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
  
  # GET /shop_floor_order_sterilizations
  # GET /shop_floor_order_sterilizations.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    shop_floor_order_sterilizations = ShopFloorOrderSterilization.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("number desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']]
      @option_filter_records = shop_floor_order_sterilizations 
      
      if params[:filter_column].present?
        shop_floor_order_sterilizations = shop_floor_order_sterilizations.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    if params[:sales_order_id].present?
      @products    = @products.where(:id=> SalesOrderItem.where(:sales_order_id=> params[:sales_order_id]).select(:product_id))
    end

    case params[:select_kind]
    when 'internal'
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).where("shop_floor_order_item_id > 0").includes(product: [:unit, :product_type])#.where("outstanding > 0")
    else
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).where("sterilization_product_receiving_item_id > 0").includes(product: [:unit, :product_type])#.where("outstanding_sterilization > 0")
    end
    if params[:product_batch_number_id].present?
      @sfo_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).find_by(:id=> params[:product_batch_number_id]) 
    end

    case params[:tbl_kind]
    when 'items'
      shop_floor_order_sterilizations = ShopFloorOrderSterilizationItem.where(:status=> 'active').includes(:shop_floor_order_sterilization).where(:shop_floor_order_sterilizations => { :company_profile_id => current_user.company_profile_id }).order("shop_floor_order_sterilizations.number desc")
    else
      case params[:view_kind]
      when 'item'
        shop_floor_order_sterilizations = ShopFloorOrderSterilizationItem.where(:status=> 'active').includes(:shop_floor_order_sterilization).where(:shop_floor_order_sterilizations => { :company_profile_id => current_user.company_profile_id }).order("shop_floor_order_sterilizations.number desc")
      else
        shop_floor_order_sterilizations = shop_floor_order_sterilizations.order("number asc")
      end
    end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @shop_floor_order_sterilizations = pagy(shop_floor_order_sterilizations, page: params[:page], items: pagy_items) 
  end

  # GET /shop_floor_order_sterilizations/1
  # GET /shop_floor_order_sterilizations/1.json
  def show
  end

  # GET /shop_floor_order_sterilizations/new
  def new
    @shop_floor_order_sterilization = ShopFloorOrderSterilization.new
  end

  # GET /shop_floor_order_sterilizations/1/edit
  def edit
  end

  # POST /shop_floor_order_sterilizations
  # POST /shop_floor_order_sterilizations.json
  def create    
    params[:shop_floor_order_sterilization]["company_profile_id"] = current_user.company_profile_id
    params[:shop_floor_order_sterilization]["created_by"] = current_user.id
    params[:shop_floor_order_sterilization]["created_at"] = DateTime.now()
    
    new_number = document_number(controller_name, params[:shop_floor_order_sterilization]["date"].to_date, nil, nil, nil)
    params[:shop_floor_order_sterilization]["number"] = new_number
    params[:shop_floor_order_sterilization]["sterilization_batch_number"] = "S"+new_number.gsub('/', '').gsub('SFOS', '')
    @shop_floor_order_sterilization = ShopFloorOrderSterilization.new(shop_floor_order_sterilization_params)
    periode = params[:shop_floor_order_sterilization]["date"]

    respond_to do |format|
      if @shop_floor_order_sterilization.save
        params[:new_record_item].each do |item|
          # product_batch_number ambil dari SFO Production (tidak buat Product Batch Number baru)
          transfer_item = ShopFloorOrderSterilizationItem.create({
            :shop_floor_order_sterilization_id=> @shop_floor_order_sterilization.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          }) 

        end if params[:new_record_item].present?
        format.html { redirect_to shop_floor_order_sterilizations_path(:id=> @shop_floor_order_sterilization.id), notice: "#{@shop_floor_order_sterilization.number} was successfully created." }
        format.json { render :show, status: :created, location: @shop_floor_order_sterilization }
      else
        format.html { render :new }
        format.json { render json: @shop_floor_order_sterilization.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shop_floor_order_sterilizations/1
  # PATCH/PUT /shop_floor_order_sterilizations/1.json
  def update
    respond_to do |format|
      params[:shop_floor_order_sterilization]["updated_by"] = current_user.id
      params[:shop_floor_order_sterilization]["updated_at"] = DateTime.now()
      params[:shop_floor_order_sterilization]["number"] = @shop_floor_order_sterilization.number
      periode = params[:shop_floor_order_sterilization]["date"]

      if @shop_floor_order_sterilization.update(shop_floor_order_sterilization_params)                
        params[:new_record_item].each do |item|
          transfer_item = ShopFloorOrderSterilizationItem.create({
            :shop_floor_order_sterilization_id=> @shop_floor_order_sterilization.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })   
        end if params[:new_record_item].present?
        params[:shop_floor_order_sterilization_item].each do |item|
          transfer_item = ShopFloorOrderSterilizationItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            transfer_item.update_columns({
              :product_id=> item["product_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:shop_floor_order_sterilization_item].present?

        format.html { redirect_to shop_floor_order_sterilizations_path(), notice: 'SFO was successfully updated.' }
        format.json { render :show, status: :ok, location: @shop_floor_order_sterilization }      
      else
        format.html { render :edit }
        format.json { render json: @shop_floor_order_sterilization.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @shop_floor_order_sterilization.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @shop_floor_order_sterilization.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @shop_floor_order_sterilization.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @shop_floor_order_sterilization.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @shop_floor_order_sterilization.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
    when 'cancel_approve3'
      @shop_floor_order_sterilization.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
    end
    respond_to do |format|
      format.html { redirect_to shop_floor_order_sterilization_path(:id=> @shop_floor_order_sterilization.id), notice: "SFO was successfully #{@shop_floor_order_sterilization.status}." }
      format.json { head :no_content }
    end
  end

  def print
    if @shop_floor_order_sterilization.status == 'approved3'
      sop_number      = "SOP-03A-001"

      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @shop_floor_order_sterilization
      items  = @shop_floor_order_sterilization_items
      po_number = (header.sales_order.present? ? header.sales_order.po_number : "")
      order_number = (header.present? ? header.number : "")   
      sterilization_batch_number = (header.present? ? header.sterilization_batch_number : "")   

      form_number     = "F-03A-005-Rev 03"

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

      document_name = "SHOP FLOOR ORDER FOR STERILIZATION"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 0,:bottom_margin => 0, :left_margin=> 1, :right_margin=> 0 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 145

          tbl_width = [30, 70, 450, 80, 80, 80, 50]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..20).each do 
              y = pdf.y
              pdf.start_new_page if y < 150
              pdf.move_down 145 if y < 150

              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                  {:content=>(item.product.name if item.product.present?)},
                  {:content=>(item.product.type_name if item.product.present?)},
                  {:content=>(item.product_batch_number.number if item.product_batch_number.present?)},
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
                  ["Sterilization Batch Number", ":", "#{sterilization_batch_number}", "", "", ""],
                  ["Order Number", ":", order_number, "", "", ""]
                  ], :column_widths => [130, 20, 470, 100, 20, 100], :cell_style => {:size=> 10, :border_color => "ffffff", :padding=>5}) 
              
                pdf.move_down 5
                pdf.table([ ["No.","Product Code","Product Name", "Type", "Batch No.", "Quantity", "Unit"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 450
              bound_height = 320

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
                  ["","", "", {:content=>"#{name_approved3_by.present? ? name_approved3_by : ('<i>(Sign Name)</i>')}", :align=>:center, :padding=>0}, ""]
                ], :column_widths => [30, 100, 530, 150, 30], :cell_style => {:size=> 11, :border_color => "ffffff", :inline_format=>true})

                pdf.move_down 20
                pdf.table([
                  ["",{:content=> "CONFIDENTIAL", :align=> :center}, {:content=> form_number, :align=> :right}]],
                  :column_widths => [250,340, 250], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})  
               
              }

              pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 25]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @shop_floor_order_sterilization, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @shop_floor_order_sterilization }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, params[:q])
  end
  # DELETE /shop_floor_order_sterilizations/1
  # DELETE /shop_floor_order_sterilizations/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to shop_floor_order_sterilizations_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shop_floor_order_sterilization
      @shop_floor_order_sterilization = ShopFloorOrderSterilization.find_by(:id=> params[:id])
      if @shop_floor_order_sterilization.present?
        @shop_floor_order_sterilization_items = ShopFloorOrderSterilizationItem.where(:status=> 'active').includes(:shop_floor_order_sterilization).where(:shop_floor_order_sterilizations => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("shop_floor_order_sterilizations.number desc")
      else        
        respond_to do |format|
          format.html { redirect_to shop_floor_order_sterilizations_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
    end
    def check_status   
      if @shop_floor_order_sterilization.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @shop_floor_order_sterilization.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to shop_floor_order_sterilization_path(:id=> @shop_floor_order_sterilization.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @shop_floor_order_sterilization }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shop_floor_order_sterilization_params
      params.require(:shop_floor_order_sterilization).permit(:company_profile_id, :sterilization_batch_number, :number, :kind, :sales_order_id, :date, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end

end
