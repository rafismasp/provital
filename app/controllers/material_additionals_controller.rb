class MaterialAdditionalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material_additional, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /material_additionals
  # GET /material_additionals.json
  def index     
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    material_additionals = MaterialAdditional.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['Product Batch Number','product_batch_number_id']]
      @option_filter_records = material_additionals 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'product_batch_number_id'
          @option_filter_records = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).order("number asc")
        end

        material_additionals = material_additionals.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    if params[:material_return_id].present?
      @material_return_items = MaterialReturnItem.where(:status=> 'active', :material_return_id=> params[:material_return_id]).where("outstanding > 0").includes(:material_batch_number, :product_batch_number, material: [:unit], product: [:unit])
      puts "ini"
    end

    case params[:view_kind]
    when 'item'
      material_additionals = MaterialAdditionalItem.where(:status=> 'active').includes(:material_additional).where(:material_additionals => { :company_profile_id => current_user.company_profile_id }).order("material_additionals.number desc")
    else
      material_additionals = material_additionals.order("number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @material_additionals = pagy(material_additionals, page: params[:page], items: pagy_items)

  end

  # GET /material_additionals/1
  # GET /material_additionals/1.json
  def show
  end

  # GET /material_additionals/new
  def new
    @material_additional = MaterialAdditional.new
  end

  # GET /material_additionals/1/edit
  def edit   
  end

  # POST /material_additionals
  # POST /material_additionals.json
  def create
    params[:material_additional]["company_profile_id"] = current_user.company_profile_id
    params[:material_additional]["created_by"] = current_user.id
    params[:material_additional]["created_at"] = DateTime.now()
    params[:material_additional]["status"] = 'new'
    params[:material_additional]["number"] = document_number(controller_name, params[:material_additional]["date"].to_date, nil, nil, nil)
    @material_additional = MaterialAdditional.new(material_additional_params)

    respond_to do |format|
      if @material_additional.save
        params[:new_record_item].each do |item|
          transfer_item = MaterialAdditionalItem.new({
            :material_additional_id=> @material_additional.id,
            :material_return_item_id=> item['material_return_item_id'],
            :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
            :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
            :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
            :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          if transfer_item.save
            transfer_item.material_return_item.update_columns(:outstanding=> transfer_item.material_return_item.outstanding.to_f - item["quantity"].to_f)
          end
          puts transfer_item.errors.full_messages
        end if params[:new_record_item].present?
        
        format.html { redirect_to material_additional_path(:id=> @material_additional.id), notice: "#{@material_additional.number} was successfully Created" }
        format.json { render :show, status: :created, location: @material_additional }
      else
        format.html { render :new }
        format.json { render json: @material_additional.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /material_additionals/1
  # PATCH/PUT /material_additionals/1.json
  def update
    params[:material_additional]["updated_by"] = current_user.id
    params[:material_additional]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @material_additional.update(material_additional_params) 
        MaterialAdditionalItem.where(:material_additional_id=> @material_additional.id).each do |item|
          item.update_columns(:status=> 'deleted')
        end               
        params[:new_record_item].each do |item|
          transfer_item = MaterialAdditionalItem.find_by({
            :material_additional_id=> @material_additional.id,
            :material_return_item_id=> item['material_return_item_id'],
            :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
            :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
            :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
            :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
            :quantity=> item["quantity"]
          })
          if transfer_item.present?
            old_qty = transfer_item.quantity
            transfer_item.update_columns({:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> current_user.id})
            transfer_item.material_return_item.update_columns(:outstanding=> (transfer_item.material_return_item.outstanding.to_f + old_qty.to_f ) - item["quantity"].to_f)
          else
            transfer_item = MaterialAdditionalItem.new({
              :material_additional_id=> @material_additional.id,
              :material_return_item_id=> item['material_return_item_id'],
              :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
              :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
              :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
              :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            if transfer_item.save
              transfer_item.material_return_item.update_columns(:outstanding=> transfer_item.material_return_item.outstanding.to_f - item["quantity"].to_f)
            end
          end
        end if params[:new_record_item].present?

        params[:material_additional_item].each do |item|
          transfer_item = MaterialAdditionalItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
            transfer_item.material_return_item.update_columns(:outstanding=> transfer_item.material_return_item.outstanding.to_f + item["quantity"].to_f)
          else
            old_qty = transfer_item.quantity
            transfer_item.update_columns({
              :material_id=> (item["material_id"].present? ? item["material_id"] : nil),
              :material_return_item_id=> item['material_return_item_id'],
              :material_batch_number_id=> (item["material_batch_number_id"].present? ? item["material_batch_number_id"] : nil),
              :product_id=> (item["product_id"].present? ? item["product_id"] : nil),
              :product_batch_number_id=> (item["product_batch_number_id"].present? ? item["product_batch_number_id"] : nil),
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
            transfer_item.material_return_item.update_columns(:outstanding=> (transfer_item.material_return_item.outstanding.to_f + old_qty.to_f ) - item["quantity"].to_f)
          
          end if transfer_item.present?
        end if params[:material_additional_item].present?

        format.html { redirect_to material_additional_path(:id=> @material_additional.id), notice: "#{@material_additional.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @material_additional }     
      else
        format.html { render :edit }
        format.json { render json: @material_additional.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @material_additional.date.strftime("%Y%m")
    prev_periode = (@material_additional.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @material_additional.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @material_additional.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @material_additional.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @material_additional.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @material_additional.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=>current_user.signature})  
      inventory(controller_name, @material_additional.id, periode, prev_periode, 'approved')  
    when 'cancel_approve3'
      @material_additional.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=>nil}) 
      inventory(controller_name, @material_additional.id, periode, prev_periode, 'canceled')    
    end

    respond_to do |format|
      if alert.present?
        format.html { redirect_to material_additional_path(:id=> @material_additional.id), alert: "#{alert}" }
      else
        format.html { redirect_to material_additional_path(:id=> @material_additional.id), notice: "Material Issue was successfully #{@material_additional.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    case @material_additional.status 
    when 'approved1', 'canceled2'
      # 2022-07-22 Dipta request dikembalikan lagi menjadi print setelah approve1
      # when 'approved3'
      # request dipta, print tampil saat approve 3
      # when 'approved1', 'canceled2'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @material_additional
      items  = @material_additional_items
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
        format.html { redirect_to @material_additional, alert: 'Cannot be displayed, status must be Approve 1' }
        format.json { render :show, status: :ok, location: @material_additional }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /material_additionals/1
  # DELETE /material_additionals/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to material_additionals_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_additional
      @material_additional = MaterialAdditional.find_by(:id=> params[:id])
      if @material_additional.present?
        @material_additional_items = MaterialAdditionalItem.where(:status=> 'active').includes(:material_additional).where(:material_additionals => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("material_additionals.number desc")
        
        @material_return_items = MaterialReturnItem.where(:status=> 'active', :material_return_id=> @material_additional.material_return_id).includes(:material_batch_number, :product_batch_number, material: [:unit], product: [:unit])
        @product_sterilization = false
        product_batch_number = ProductBatchNumber.find_by(:id=> @material_additional.product_batch_number_id)
        if product_batch_number.present?
          @sfo_quantity = product_batch_number.shop_floor_order_item.quantity
          @product_sterilization = product_batch_number.product.sterilization
        else
          @sfo_quantity = 0
        end
        @fg_items = FinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> @material_additional.product_batch_number_id).includes(:finish_good_receiving, :product_batch_number)
        @sfg_items = SemiFinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> @material_additional.product_batch_number_id).includes(:semi_finish_good_receiving, :product_batch_number)
        @material_additional_approved = MaterialAdditional.where(:status=> 'approved3', :product_batch_number_id=> @material_additional.product_batch_number_id).where.not(:id=> params[:id]).includes(:product_batch_number)
        
      else
        respond_to do |format|
          format.html { redirect_to material_additionals_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      @material_returns = MaterialReturn.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:material_return_items, :shop_floor_order, product_batch_number: [:product]).where(:material_return_items=> {:status=> 'active'}).where("material_return_items.outstanding > 0").order("material_returns.date desc")
    end
    def check_status      
      if @material_additional.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @material_additional.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @material_additional, notice: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @material_additional }
          end
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def material_additional_params
      params.require(:material_additional).permit(:company_profile_id, :number, :date, :material_return_id, :material_outgoing_id, :shop_floor_order_id, :product_batch_number_id, :remarks, :status, :created_by, :created_at, :updated_by, :updated_at)
    end

end
