class DeliveryOrderSuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_delivery_order_supplier, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /delivery_order_suppliers
  # GET /delivery_order_suppliers.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    delivery_order_suppliers = DeliveryOrderSupplier.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    @delivery_order_supplier_items = DeliveryOrderSupplierItem.where(:status=> 'active', :delivery_order_supplier_id=> params[:id])

    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Supplier Name', 'supplier_id'], ['Currency', 'currency_id']] 
      @option_filter_records = delivery_order_suppliers
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        end

        delivery_order_suppliers = delivery_order_suppliers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      delivery_order_suppliers = DeliveryOrderSupplierItem.where(:status=> 'active').includes(:delivery_order_supplier).where(:delivery_order_suppliers => {:company_profile_id => current_user.company_profile_id }).order("delivery_order_suppliers.number desc")      
    else
      delivery_order_suppliers = delivery_order_suppliers.order("number desc")
    end
    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @delivery_order_suppliers = pagy(delivery_order_suppliers, page: params[:page], items: pagy_items) 
  end

  # GET /delivery_order_suppliers/1
  # GET /delivery_order_suppliers/1.json
  def show
  end

  # GET /delivery_order_suppliers/new
  def new
    @delivery_order_supplier = DeliveryOrderSupplier.new
  end
  # GET /delivery_order_suppliers/1/edit
  def edit
    @purchase_requests = PurchaseRequest.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where("outstanding > 0")
    @pdms = Pdm.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where("outstanding > 0")
  end

  # POST /delivery_order_suppliers
  # POST /delivery_order_suppliers.json
  def create
    params[:delivery_order_supplier]["company_profile_id"] = current_user.company_profile_id
    params[:delivery_order_supplier]["created_by"] = current_user.id
    params[:delivery_order_supplier]["created_at"] = DateTime.now()
    params[:delivery_order_supplier]["number"] = document_number(controller_name, params[:delivery_order_supplier]['date'].to_date, nil, nil, nil)
    @delivery_order_supplier = DeliveryOrderSupplier.new(delivery_order_supplier_params)

    respond_to do |format|

      params[:new_record_item].each do |item|
        @delivery_order_supplier.delivery_order_supplier_items.build({
          :material_batch_number_id=> item["material_batch_number_id"],
          :material_id=> item["material_id"],
          :quantity=> item["quantity"],
          :remarks=> item["remarks"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })
      end if params[:new_record_item].present?

      if @delivery_order_supplier.save
        format.html { redirect_to delivery_order_supplier_path(:id=> @delivery_order_supplier.id), notice: "#{@delivery_order_supplier.number} supplier was successfully created." }
        format.json { render :show, status: :created, location: @delivery_order_supplier }
      else
        format.html { render :new }
        format.json { render json: @delivery_order_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /delivery_order_suppliers/1
  # PATCH/PUT /delivery_order_suppliers/1.json
  def update
    respond_to do |format|
      params[:delivery_order_supplier]["updated_by"] = current_user.id
      params[:delivery_order_supplier]["updated_at"] = DateTime.now()
      params[:delivery_order_supplier]["number"] = @delivery_order_supplier.number
      if @delivery_order_supplier.update(delivery_order_supplier_params)
        params[:new_record_item].each do |item|
          transfer_item = DeliveryOrderSupplierItem.create({
            :material_batch_number_id=> item["material_batch_number_id"],
            :material_id=> item["material_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?
        params[:record_item].each do |item|
          po_item = DeliveryOrderSupplierItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            po_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            po_item.update_columns({
              :material_batch_number_id=> item["material_batch_number_id"],
              :material_id=> item["material_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if po_item.present?
        end if params[:record_item].present?
        format.html { redirect_to delivery_order_supplier_path(), notice: 'Purchase order supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @delivery_order_supplier }
      else
        format.html { render :edit }
        format.json { render json: @delivery_order_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /delivery_order_suppliers/1
  # DELETE /delivery_order_suppliers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to delivery_order_suppliers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def approve
    periode = @delivery_order_supplier.date.strftime("%Y%m")
    prev_periode = (@delivery_order_supplier.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @delivery_order_supplier.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @delivery_order_supplier.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @delivery_order_supplier.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @delivery_order_supplier.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @delivery_order_supplier.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
      inventory(controller_name, @delivery_order_supplier.id, periode, prev_periode, 'approved')
    when 'cancel_approve3'
      @delivery_order_supplier.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
      inventory(controller_name, @delivery_order_supplier.id, periode, prev_periode, 'canceled')
    end
    notice_info = "#{@delivery_order_supplier.number} was successfully #{@delivery_order_supplier.status}."
 
    respond_to do |format|
      format.html { redirect_to delivery_order_supplier_path(:id=> @delivery_order_supplier.id), notice: notice_info }
      format.json { head :no_content }
    end
  end

  def print
    if @delivery_order_supplier.status == 'approved3'  
      
      sop_number      = "SOP-03C-004"
      form_number     = "F-03C-025-Rev 00"
      image_path      = "app/assets/images/logo-bw.png"  
      image_path2     = "app/assets/images/iso_13485_2016.jpeg"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @delivery_order_supplier
      items  = @delivery_order_supplier_items
      order_number = ""

      supplier_name  = (header.supplier.present? ? header.supplier.name : '')
      supplier_code  = (header.supplier.present? ? header.supplier.number : '')
      supplier_address = (header.supplier.present? ? header.supplier.address : '')

      summary_qty_do = number_with_precision(items.sum(:quantity), precision: 0, delimiter: ".", separator: ",")

      document_name = "MATERIAL DELIVERY NOTE"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 160
          tbl_width = [30, 74, 220, 80, 60, 50, 80]
          c = 1
          pdf.move_down 2
          items.each do |item|
            # (1..30).each do 
              y = pdf.y
              pdf.start_new_page if y < 550
              pdf.move_down 160 if y < 550
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center}, 
                  {:content=>(item.material.part_id if item.material.present?), :align=>:center},
                  {:content=>(item.material.name if item.material.present?)},
                  {:content=> (item.material_batch_number.present? ? item.material_batch_number.number : ""), :align=>:center},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right},
                  {:content=>(item.material.unit_name if item.material.present?), :align=>:center},
                  {:content=>item.remarks}
                ]], :column_widths => tbl_width, :cell_style => {:padding => [3, 5, 0, 4], :border_color=>"ffffff"})
              c +=1
            # end
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1

                # pdf.bounding_box([0, 822], :width => 595) do
                #   pdf.text "________________________", :align => :center
                # end

                pdf.bounding_box([1, 740], :width => 324, :height => 35) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([480, 835], :width => 324, :height => 40) do
                  pdf.image image_path2, :height=> 40
                end
                pdf.bounding_box([450, 790], :width => 324, :height => 40) do
                  pdf.text "with coverage of ISO 11135:2014", :size=> 9
                end

                pdf.bounding_box([424, 750], :width => 70, :height => 15) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([494, 750], :width => 100, :height => 15) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end

                # delivery date
                pdf.bounding_box([424, 735], :width => 70, :height => 15) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end

                pdf.bounding_box([494, 735], :width => 100, :height => 15) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end

                pdf.bounding_box([424, 720], :width => 70, :height => 15) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([494, 720], :width => 100, :height => 15) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              }

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.table([
                    [
                      {:image => image_path, :image_width => 120}, 
                      "", 
                      {:content=>document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>19},
                      "", 
                      ""
                    ]
                  ], :column_widths => [130, 10, 294, 10, 150], :cell_style => {:border_color => "ffffff", :border_width=> 0, :padding=>1}) 
                pdf.move_down 10
                pdf.table([
                  [{:content=>company_name, :font_style => :bold, :size=>12}, "", "", "", ""]
                  ], :column_widths => [150, 20, 254, 20, 150], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 

                pdf.table([
                  [{:content=>company_address1, :size=>10, :height=>15}, "", {:content=>"", :size=>10, :rowspan=> 2}, ""],
                  [{:content=>company_address2, :size=>10, :height=>15}, ""],
                  [{:content=>"", :size=>10, :height=>15}, "", {:content=>"Delivery No.", :size=>10 }, {:content=>"#{header.number}", :size=>10}],
                  [{:content=>"Ship to : #{supplier_name}", :size=>10, :height=>15}, "", {:content=>"Delivery Date", :size=>10}, {:content=>"#{header.date}", :size=>10}],
                  [{:content=>"#{supplier_address}", :size=>10, :height=>15}, {:content=>"", :size=>10, :height=>15}, {:content=>"Supplier ID", :size=>10, :rowspan=> 2}, {:content=>"#{supplier_code}", :size=>10, :rowspan=> 2}],
                  
                  
                  ], :column_widths => [324, 100, 70, 100], :cell_style => {:border_width => 0, :border_color => "000000", :padding=> [4, 5, 0, 4] }) 
                pdf.move_down 5
                
                pdf.table([ ["No.","Material Code","Material Name", "Batch No.","Qty", "Unit", "Remarks"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 678
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 130) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              den_row = 0
              [404, 60, 50, 80].each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position-130], :width => den_row, :height => 20) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              pdf.bounding_box([330, tbl_top_position-135], :width => 100) do
                pdf.text "Grand Total"
              end
              pdf.bounding_box([360, tbl_top_position-135], :width => 100) do
                pdf.text "#{summary_qty_do}", :align=> :right
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 510
                pdf.table([
                  [
                    {:content=> "Issued By", :align=> :center},
                    {:content=> "Checked By", :align=> :center},
                    {:content=> "Received By", :align=> :center}
                  ]
                  ], :column_widths => [197, 197, 197], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})  
                pdf.move_down 40
                pdf.table([
                  [
                    {:content=> "(                             )", :align=> :center},
                    {:content=> "(                             )", :align=> :center},
                    {:content=> "(                             )", :align=> :center}
                  ]
                  ], :column_widths => [197, 197, 197], :cell_style => {:size=> 11, :border_color => "ffffff", :padding=>1})  
                pdf.move_down 10
                pdf.table([
                  ["#{sop_number}", {:content=> "#{form_number}", :align=> :right}]
                  ], :column_widths => [297, 297], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  

              }

              # pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @delivery_order_supplier, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @delivery_order_supplier }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_delivery_order_supplier
      @delivery_order_supplier = DeliveryOrderSupplier.find_by(:id=> params[:id])
      if @delivery_order_supplier.present?
        @delivery_order_supplier_items = DeliveryOrderSupplierItem.where(:status=> 'active').includes(:delivery_order_supplier)
        .where(:delivery_order_suppliers => {:id=> params[:id], :company_profile_id => current_user.company_profile_id })
        .order("delivery_order_suppliers.number desc")      
      else
        respond_to do |format|
          format.html { redirect_to delivery_order_suppliers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @material_batch_number = MaterialBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      @taxes = Tax.where(:status=> 'active')
      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
    end

    def check_status     
      if @delivery_order_supplier.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @delivery_order_supplier.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @delivery_order_supplier, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @delivery_order_supplier }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def delivery_order_supplier_params
      params.require(:delivery_order_supplier).permit(:transforter_name, :vehicle_number, :vehicle_driver_name, :company_profile_id, :number, :outstanding, :supplier_id, :date, :tax_id, :term_of_payment_id, :top_day, :currency_id, :remarks, :purchase_request_id, :pdm_id, :created_by, :created_at, :updated_at, :updated_by)
    end
end
