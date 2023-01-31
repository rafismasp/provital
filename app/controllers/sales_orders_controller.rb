class SalesOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sales_order, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /sales_orders
  # GET /sales_orders.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id).where("sales_orders.date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:customer, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3)

    # filter select - begin
      @option_filters = [['SO Number','number'],['PO Customer','po_number'], ['Customer Name', 'customer_id'], ['Status', 'status']] 
      @option_filter_records = sales_orders
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'customer_id'
          @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        end

        sales_orders = sales_orders.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    if params[:service_type_str] == "true"
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').only_sterilization
    else
      # 20200828 - aden: product selain str menampilkan seluruh produk (non elektromedik steril dan lainnya)
      # karena produk yg butuh sterilisiasi internal dan external menggunakan risk ketegory non eketromedik steril
      # sfo berdasarkan SO selain str
      # jika sfo non elektromedik steril maka proses nya ke semi finish good sterilisasi dan SOF Sterilisasi internal
      # jika sfo bukan non eletromedik steril maka proses langsung ke finish good receiving note
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active') #.is_not_sterilization
    end
    @products = @products.includes(:product_type, :unit)

    case params[:view_kind]
    when 'item'
      sales_orders = SalesOrderItem.where(:status=> 'active')
      .includes(product: [:product_type, :unit])
      .includes(sales_order: [:customer, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3]).where(:sales_orders => {:company_profile_id => current_user.company_profile_id }).where("sales_orders.date between ? and ?", session[:date_begin], session[:date_end]).order("sales_orders.number desc")      
    else
      sales_orders = sales_orders.order("number desc")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @sales_orders = pagy(sales_orders, page: params[:page], items: pagy_items) 
  end

  # GET /sales_orders/1
  # GET /sales_orders/1.json
  def show
  end

  # GET /sales_orders/new
  def new
    @sales_order = SalesOrder.new
    @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
  end

  # GET /sales_orders/1/edit
  def edit
  end

  # POST /sales_orders
  # POST /sales_orders.json
  def create
    params[:sales_order]["outstanding"] = 0
    params[:sales_order]["month_delivery"] = "#{params[:sales_order]["month_delivery_yyyy"]}#{params[:sales_order]["month_delivery_mm"]}"
    params[:sales_order]["company_profile_id"] = current_user.company_profile_id
    params[:sales_order]["created_by"] = current_user.id
    params[:sales_order]["created_at"] = DateTime.now()
    params[:sales_order]["number"] = document_number(controller_name, params[:sales_order]["date"].to_date, nil, nil, nil)
    @sales_order = SalesOrder.new(sales_order_params.except(:updated_at, :updated_by))

    respond_to do |format|
      if @sales_order.save
        sum_outstanding = 0
        params[:new_record_item].each do |item|
          sales_order_item = SalesOrderItem.create({
            :sales_order_id=> @sales_order.id,
            :product_id=> item["product_id"],
            :unit_price=> item["unit_price"],
            :quantity=> item["quantity"].to_f,
            :outstanding=> item["quantity"].to_f,
            :discount=> item["discount"],
            :due_date=> item["due_date"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          sum_outstanding += item["quantity"].to_f
        end if params[:new_record_item].present?
        @sales_order.update_columns(:outstanding=> sum_outstanding)

        if params[:file].present?
          params["file"].each do |many_files|
            if many_files[:attachment].present?
              content =  many_files[:attachment].read
              hash = Digest::MD5.hexdigest(content)
              fid = SalesOrderFile.where(:sales_order_id=>@sales_order.id)
              pf = fid.find_by(:file_hash=>hash)
              if pf.blank?
                filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
                ext=File.extname(filename_original)
                filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
                dir = "public/uploads/sales_order/"
                FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
                path = File.join(dir, "#{hash}#{ext}")
                tmp_path_filename=File.join('/tmp', filename)
                File.open(path, 'wb') do |file|
                  file.write(content)
                  upload_file = SalesOrderFile.new({
                    :sales_order_id=> @sales_order.id,
                    :filename_original=>filename_original,
                    :file_hash=> hash ,
                    :filename=> filename,
                    :path=> path,
                    :ext=> ext,
                    :created_at=> DateTime.now,
                    :created_by=> current_user.id
                  })  
                  upload_file.save!           
                end
              end
            end
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end

        format.html { redirect_to sales_order_path(:id=> @sales_order.id), notice: "#{@sales_order.number} was successfully created." }
        format.json { render :show, status: :created, location: @sales_order }
      else
        format.html { render :new }
        format.json { render json: @sales_order.errors, status: :unprocessable_entity }
      end
      logger.info @sales_order.errors
    end
  end

  # PATCH/PUT /sales_orders/1
  # PATCH/PUT /sales_orders/1.json
  def update
    respond_to do |format|
      params[:sales_order]["updated_by"] = current_user.id
      params[:sales_order]["updated_at"] = DateTime.now()
      params[:sales_order]["number"] = @sales_order.number
      params[:sales_order]["date"] = @sales_order.date
      if @sales_order.update(sales_order_params.except(:created_at, :created_by))

        params[:new_record_item].each do |item|
          sales_order_item = SalesOrderItem.create({
            :sales_order_id=> @sales_order.id,
            :product_id=> item["product_id"],
            :unit_price=> item["unit_price"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :discount=> item["discount"],
            :due_date=> item["due_date"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?
        alert = nil
        params[:record_file].each do |item|
          check_file = SalesOrderFile.find_by(:id=> item['id'])
          if check_file.present?
            check_file.update_columns(:status=> item['status']) if item['status'] != check_file.status
          end
        end if params[:record_file].present?
        params[:sales_order_item].each do |item|
          sales_order_item = SalesOrderItem.find_by(:id=> item["id"])
          if sales_order_item.present?
            min_quantity = (sales_order_item.quantity.to_f - sales_order_item.outstanding.to_f)
            if sales_order_item.quantity.to_f > sales_order_item.outstanding.to_f and item["quantity"].to_f < min_quantity
              alert = "Product #{sales_order_item.product.part_id} tidak boleh dari qty outstanding!"
            else
              case item["status"]
              when 'deleted'
                if sales_order_item.quantity.to_f > sales_order_item.outstanding.to_f
                  alert = "Product #{sales_order_item.product.part_id} masih outstanding tidak bisa dihapus!"
                else
                  sales_order_item.update_columns({
                    :status=> item["status"],
                    :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
                  })
                end
              else
                sales_order_item.update_columns({
                  :product_id=> item["product_id"],
                  :unit_price=> item["unit_price"],
                  :quantity=> item["quantity"].to_f,
                  :outstanding=> ((sales_order_item.outstanding.to_f-sales_order_item.quantity.to_f)+item["quantity"].to_f),
                  :discount=> item["discount"],
                  :due_date=> item["due_date"],
                  :remarks=> item["remarks"],
                  :status=> item["status"],
                  :updated_at=> DateTime.now(), :updated_by=> current_user.id
                })
              end
            end
          end
        end if params[:sales_order_item].present?
        puts alert
        if alert.present?
          format.html { redirect_to @sales_order, alert: "#{alert}" }
        else
          sales_order_items = SalesOrderItem.where(:status=> 'active', :sales_order_id=> @sales_order.id)
          @sales_order.update_columns(:outstanding=> sales_order_items.sum(:outstanding)) if sales_order_items.present?

          if params[:file].present?
            params["file"].each do |many_files|
              if many_files[:attachment].present?
                content =  many_files[:attachment].read
                hash = Digest::MD5.hexdigest(content)
                fid = SalesOrderFile.where(:sales_order_id=>@sales_order.id)
                pf = fid.find_by(:file_hash=>hash)
                if pf.blank?
                  filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
                  ext=File.extname(filename_original)
                  filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
                  dir = "public/uploads/sales_order/"
                  FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
                  path = File.join(dir, "#{hash}#{ext}")
                  tmp_path_filename=File.join('/tmp', filename)
                  File.open(path, 'wb') do |file|
                    file.write(content)
                    upload_file = SalesOrderFile.new({
                      :sales_order_id=> @sales_order.id,
                      :filename_original=>filename_original,
                      :file_hash=> hash ,
                      :filename=> filename,
                      :path=> path,
                      :ext=> ext,
                      :created_at=> DateTime.now,
                      :created_by=> current_user.id
                    })    
                    upload_file.save!         
                  end
                end
              end
            end  
          else
           flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
          end

          format.html { redirect_to @sales_order, notice: 'Sales order was successfully updated.' }
        end
        format.json { render :show, status: :ok, location: @sales_order }
      else
        format.html { render :edit }
        format.json { render json: @sales_order.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve
    alert = nil
    case params[:status]
    when 'approve1'
      @sales_order.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @sales_order.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @sales_order.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @sales_order.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @sales_order.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
      production_order = ProductionOrder.find_by(:sales_order_id=> @sales_order.id)
      if production_order.blank?
        production_order = ProductionOrder.create(
          {
            :company_profile_id=> @sales_order.company_profile_id, 
            :sales_order_id=> @sales_order.id,
            :date=> @sales_order.date, :number=> document_number("production_orders", @sales_order.date.to_date, nil, nil, nil),
            :remarks=> "Otomatis by Sales Order",
            :created_at=> DateTime.now(), :created_by=> current_user.id,
            :status=> 'new'
          }
        )
      end
      if production_order.present?
        @sales_order_items.each do |item|
          production_order_item = ProductionOrderItem.find_by(:sales_order_item_id=> item.id)
          if production_order_item.present?
            production_order_item.update_columns({
              :production_order_id=> production_order.id,
              :sales_order_item_id=> item.id,
              :product_id=> item.product_id,
              :quantity=> item.quantity,
              :remarks=> "",
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            ProductionOrderItem.create({
              :production_order_id=> production_order.id,
              :sales_order_item_id=> item.id,
              :product_id=> item.product_id,
              :quantity=> item.quantity,
              :remarks=> "",
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if @sales_order_items.present?

        notice = "Sales Order was successfully #{@sales_order.status} and #{production_order.number} was successfully created."
      end
    when 'cancel_approve3'
      production_order = ProductionOrder.find_by(:sales_order_id=> @sales_order.id)
      if production_order.present? 
        if production_order.status == 'approved3'
          alert = "cannot be canceled because #{production_order.number} has been approved3!"          
        else
          @sales_order.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
        end
      else
        @sales_order.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
      end
    end
    if notice.blank?
      notice = "Sales Order was successfully #{@sales_order.status}."
    end

    if alert.present?
      respond_to do |format|
        format.html { redirect_to sales_order_path(:id=> @sales_order.id), alert: alert }
        format.json { render :show, status: :created, location: @sales_order }
      end
    else
      respond_to do |format|
        format.html { redirect_to @sales_order, notice: notice }
        format.json { head :no_content }
      end
    end
  end

  def print
    if @sales_order.status == 'approved3'
      company    = "PT. PROVITAL PERDANA"
      company_address = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      respond_to do |format|
        format.html do
          info = {
            Title: "Print Sales Order",
            Author: "#{current_user.first_name}",
            Subject: "#{@sales_order.number}",
            Creator: 'erp.tri-saudara.com',
            Producer: 'Prawn',
            CreationDate: Time.now
          }

          pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10, :info => info) 
          pdf.font "Times-Roman"
          pdf.font_size 11
          record = @sales_order
          items = @sales_order_items
          tbl_width = [20, 160,90, 80, 80, 60, 80]
          pdf.table([
            [{:content=>company, :font_style=> :bold},"", " "],
            [company_address,"", ""]],
            :column_widths => [200, 200, 170], :cell_style => {:border_color => "ffffff", :padding=>1}) 
          pdf.table([
            ["",{:content=> "Sales Order", :align=> :center}, ""]],
            :column_widths => [200,170, 200], :cell_style => {:size=> 17, :border_color => "ffffff", :padding=>1})

          select_year = record.month_delivery.first(4)
          select_month = record.month_delivery.last(2)
          month_delivery = Date::MONTHNAMES[select_month.to_i]

          pdf.table([["Customer",":","#{record.customer.name}", "Tgl.Input",":", record.created_at.strftime("%d-%m-%Y")]], :column_widths=> [100,20, 230,100,20, 100], :cell_style => {:border_color => "000000", :padding => [5,1,1,1], :borders=>[:top], :border_width=> 1}, :header => true) 
          pdf.table([["No.Dokumen",":",record.number.to_s, "Tgl.Sales",":", record.date.strftime("%d-%m-%Y")]], :column_widths=> [100,20, 230,100,20, 100], :cell_style => {:border_color => "000000", :padding => [1, 1, 5, 1], :border_width=> 0}, :header => true) 
          pdf.table([["Tgl. Est. Delivery",":", "#{Date::MONTHNAMES[select_month.to_i]} #{select_year}"]], :column_widths=> [100,20, 100], :cell_style => {:border_color => "000000", :padding => [1, 1, 5, 1], :border_width=> 0}, :header => true) 
          
          pdf.move_down 5
          pdf.table([ ["No.","Part Name","Part ID", "Part Model", "Quantity", "Unit", "Remarks"]], 
            :column_widths => tbl_width, :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :border_width=> 0})
          c = 1
          pdf.move_down 2
          items.each do |item|
            pdf.table( [ [{ :content=> c.to_s, :align=>:center}, 
                {:content=>(item.product.name if item.product.present?)},
                {:content=>(item.product.part_id if item.product.present?), :align=>:center},
                {:content=>(item.product.part_model if item.product.present?), :align=>:center},
                {:content=>item.quantity.to_s, :align=>:right},
                {:content=>(item.product.unit.name if item.product.present? and item.product.unit.present?), :align=>:center},\
                {:content=>item.remarks}
              ] ], 
                :column_widths => [20, 160,90, 80, 80, 60, 80], 
                :cell_style => {:padding => [4, 5, 0, 4],

                # ,:borders=>[:left, :right]
                :border_color=>"ffffff"
              })
            c +=1
          end  

          pdf.page_count.times do |i|
            den_row = 0
            tbl_top_position = 685
            
            tbl_width.each do |i|
              # puts den_row
              den_row += i
              pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 550) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
            end

            pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 16) do
              pdf.stroke_color '000000'
              pdf.stroke_bounds
            end
            # footer
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => 100) {
              pdf.go_to_page i+1
              pdf.text "F-07A-003 Rev 03", :align => :right, :size => 8 
            }
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{@sales_order.number}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @sales_order, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @sales_order }
      end
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /sales_orders/1
  # DELETE /sales_orders/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to sales_orders_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sales_order
      @sales_order = SalesOrder.find_by(:id=> params[:id])
      if @sales_order.present?
        @sales_order_items = SalesOrderItem.where(:status=> 'active')
        .includes(
          :sales_order, 
          product: [:product_type, :unit],
          delivery_order_items: [:delivery_order, :product_batch_number, product: [:product_type, :unit]],
          production_order_items: [
            production_order_used_prves: [
              purchase_request_item: [
                material: [:unit], product: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit],
                purchase_order_supplier_items: [ 
                  product_receiving_items: [
                    :product_receiving, :purchase_order_supplier_item
                  ], material_receiving_items: [
                    :material_receiving, :purchase_order_supplier_item
                  ], general_receiving_items: [
                    :general_receiving, :purchase_order_supplier_item
                  ], consumable_receiving_items: [
                    :consumable_receiving, :purchase_order_supplier_item
                  ], equipment_receiving_items: [
                    :equipment_receiving, :purchase_order_supplier_item
                  ], purchase_order_supplier: [:currency, :purchase_order_supplier_items]]]]]
                )
        .where(:sales_orders => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("sales_orders.number desc")      
        
        @record_files = SalesOrderFile.where(:sales_order_id=> params[:id], :status=> 'active')


      else                
        respond_to do |format|
          format.html { redirect_to sales_orders_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @term_of_payments = TermOfPayment.all
      @taxes = Tax.where(:status=> "active")
    end
    def check_status  
      if @sales_order.status == 'approved3'   
        if params[:status] == "cancel_approve3"
        else   
          puts "-------------------------------"
          puts  @sales_order.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @sales_order, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @sales_order }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sales_order_params
      params.require(:sales_order).except(:month_delivery_mm, :month_delivery_yyyy).permit(:company_profile_id, :tax_id, :number, :customer_id, :date, :po_number, :quotation_number, :service_type_ddv, :service_type_lab, :service_type_mfg, :service_type_str, :service_type_oth, :term_of_payment_id, :top_day, :outstanding, :remarks, :po_received, :month_delivery, :created_by, :created_at, :updated_by, :updated_at)
    end
end
