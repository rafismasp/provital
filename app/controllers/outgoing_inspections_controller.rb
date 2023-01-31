class OutgoingInspectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_outgoing_inspection, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  def index
    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d"))
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : DateTime.now().at_end_of_month().strftime("%Y-%m-%d"))
    outgoing_inspections = OutgoingInspection.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:customer, :picking_slip, :created, :updated, :approved1, :canceled1)
    #@outgoing_inspections = OutgoingInspection.all
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']] 
      @option_filter_records = outgoing_inspections

      if params[:filter_column].present?
        outgoing_inspections = outgoing_inspections.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    # filter select - end

    @products    = Product.all
    if params[:picking_slip_id].present?
      @products    = Product.where(:id=> PickingSlipItem.where(:picking_slip_id=> params[:picking_slip_id], :status=> 'active').select(:product_id))
    end
  
    @picking_slips = PickingSlip.where(:status=> 'approved3', :customer_id=> params[:customer_id], :outgoing_inspection_id=>nil) if params[:customer_id].present?
    
    if params[:picking_slip_id].present?
      @picking_slip_items = PickingSlipItem.where(:picking_slip_id=> params[:picking_slip_id])
      @outgoing_inspection_items = OutgoingInspectionItem.where(:outgoing_inspection_id=> params[:outgoing_inspection_id], :status=> 'active')
    end


    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    
    case params[:view_kind]
    when "item"
      # contoh eager load
      outgoing_inspections = OutgoingInspectionItem.where(:status=>'active')
      .includes(:picking_slip_item, :product, :product_batch_number)
      .includes(outgoing_inspection: [:customer, :picking_slip, :created, :updated, :approved1, :canceled1]).where(:outgoing_inspections => {:company_profile_id => current_user.company_profile_id }).where("outgoing_inspections.date between ? and ?", session[:date_begin], session[:date_end])
      .order("outgoing_inspections.number desc")      
    else
      outgoing_inspections = outgoing_inspections.order("date desc")
    end

    @pagy, @outgoing_inspections = pagy(outgoing_inspections, page: params[:page], items: pagy_items)
  end

  def show
  end

  def new
    @outgoing_inspection = OutgoingInspection.new
  end

  def edit
    @picking_slips = PickingSlip.where(:id=> @outgoing_inspection.picking_slip_id)
  end

  def create
    params[:outgoing_inspection]["created_by"] = current_user.id
    params[:outgoing_inspection]["created_at"] = DateTime.now()
    params[:outgoing_inspection]["status"] = "new"
    params[:outgoing_inspection]["number"] = document_number(controller_name, params[:outgoing_inspection]["date"].to_date, nil, nil, nil)
    @outgoing_inspection = OutgoingInspection.new(outgoing_inspection_params)

    respond_to do |format|
      if @outgoing_inspection.save
        picking_slip_id = PickingSlip.find_by(:id=>@outgoing_inspection.picking_slip_id)
        picking_slip_id.update({
          :outgoing_inspection_id=>@outgoing_inspection.id
        })

        params[:new_record_item].each do |item|
          inspection_item = OutgoingInspectionItem.create({
            :outgoing_inspection_id=> @outgoing_inspection.id,
            :picking_slip_item_id=> item["picking_slip_item_id"],
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :inspection_name=> item["inspection_name"], 
            :inspection_type=> item["inspection_name"], 
            :inspection_batch=> item["inspection_batch"], 
            :inspection_qty=> item["inspection_qty"], 
            :inspection_expired=> item["inspection_expired"], 
            :inspection_physical=> item["inspection_physical"], 
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?

        format.html { redirect_to @outgoing_inspection, notice: 'Outgoing Inspection was successfully created.' }
        format.json { render :show, status: :created, location: @outgoing_inspection }
      else
        format.html { render :new }
        format.json { render json: @outgoing_inspection.errors, status: :unprocessable_entity }
      end
      logger.info @outgoing_inspection.errors
    end
  end


  def update
    params[:outgoing_inspection]["updated_by"] = current_user.id
    params[:outgoing_inspection]["updated_at"] = DateTime.now()
    params[:outgoing_inspection]["customer_id"] = @outgoing_inspection.customer_id
    params[:outgoing_inspection]["number"] = @outgoing_inspection.number
    params[:outgoing_inspection]["picking_slip_id"] = @outgoing_inspection.picking_slip_id
    params[:outgoing_inspection]["date"] = @outgoing_inspection.date

    respond_to do |format|
      if @outgoing_inspection.update(outgoing_inspection_params)
        # delete row
        params[:delete_record_item].each do |item|
          inspection_item = OutgoingInspectionItem.find_by(:id=> item["id"])
          inspection_item.update_columns({
            :status=> 'deleted',
            :updated_at=> DateTime.now(), :updated_by=> @outgoing_inspection.created_by
          }) if inspection_item.present?
        end if params[:delete_record_item].present?
        # update row
        params[:record_item].each do |item|
          inspection_item = OutgoingInspectionItem.find_by(:id=> item["id"])
          inspection_item.update_columns({
            :inspection_name=> item["inspection_name"],
            :inspection_type=> item["inspection_type"],
            :inspection_batch=> item["inspection_batch"],
            :inspection_qty=> item["inspection_qty"],
            :inspection_expired=> item["inspection_expired"],
            :inspection_physical=> item["inspection_physical"],
            :updated_at=> DateTime.now(), :updated_by=> @outgoing_inspection.created_by
          }) if inspection_item.present?
        end if params[:record_item].present?
        # insert new row
        params[:new_record_item].each do |item|
          inspection_item = OutgoingInspectionItem.create({
            :outgoing_inspection_id=> @outgoing_inspection.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :picking_slip_item_id=> item["picking_slip_item_id"],
            :product_id=> item["product_id"],
            :inspection_name=> item["inspection_name"], 
            :inspection_type=> item["inspection_name"], 
            :inspection_batch=> item["inspection_batch"], 
            :inspection_qty=> item["inspection_qty"], 
            :inspection_expired=> item["inspection_expired"], 
            :inspection_physical=> item["inspection_physical"], 
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?
        format.html { redirect_to @outgoing_inspection, notice: 'Outgoing Inspection was successfully updated.' }
        format.json { render :show, status: :ok, location: @outgoing_inspection }
      else
        format.html { render :edit }
        format.json { render json: @outgoing_inspection.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve
    case params[:status]
    when 'approve1'
      @outgoing_inspection.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @outgoing_inspection.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    end
    respond_to do |format|
      format.html { redirect_to outgoing_inspection_path(:id=> @outgoing_inspection.id), notice: "Outgoing inspection was successfully #{@outgoing_inspection.status}." }
      format.json { head :no_content }
    end
  end

  def print
    company         = "PT. PROVITAL PERDANA"
    company_address = "Jl. Kranji Blok F15 No.1C, Delta Silicon 2, Lippo Cikarang 
    Cibatu, Cikarang Selatan, Bekasi 17530"
    image_path      = "app/assets/images/logo.png"
    respond_to do |format|
      format.html do
        pdf = Prawn::Document.new(:page_size=> "A4", :page_layout => :landscape, :top_margin => 25,:bottom_margin => 10, :left_margin=>25, :right_margin=>25) 
        pdf.font "Times-Roman"
        pdf.font_size 11
        record = @outgoing_inspection
        items = @outgoing_inspection_items
        customer = CustomerAddress.find_by(:customer_id=>record.customer_id)
        so = SalesOrder.find_by(:id=>record.picking_slip.sales_order_id)
        tbl_width = [20, 160,90, 80, 80, 60, 80]

        pdf.table([[
          {:image=> image_path, :scale=>0.03, :position=> :left, :padding=>[5,5,5,5]},
          {:content=> "OUTGOING INSPECTION", :align=>:right, :padding=>[8,5,5,5]},        
        ]], :column_widths => [120, 670], :cell_style => {:size=> 17, :border_color => "000000", :borders=>[:top, :right, :left, :bottom]})
        pdf.move_down 20
        pdf.table([[
          {:content=> company, :align=> :left, :size=>14},
          {:content=> "Inspection Date", :align=> :center, :size=> 11},
          {:content=> ":", :align=>:center, :size=> 11},
          {:content=> "#{record.date}", :align=> :center, :size=> 11}
        ]], :column_widths => [600, 100,20,70], :cell_style => {:border_color => "000000", :borders=>[:top, :right, :left], :padding=>[5,1,1,5]})
        pdf.table([[
          {:content=> company_address, :align=> :left, :size=>11, :padding=>[0,1,1,5]},
          {:content=> "Delivery Date", :align=> :center, :size=> 11, :padding=>[2,1,1,5]},
          {:content=> ":", :align=>:center, :size=> 11, :padding=>[2,1,1,5]},
          {:content=> "#{record.delivery_date}", :align=> :center, :size=> 11, :padding=>[2,1,1,5]}
        ]], :column_widths => [600, 100,20,70], :cell_style => {:border_color => "000000", :borders=>[:right, :left, :bottom]})
        pdf.move_down 20
        pdf.table([[
          {:content=> "SHIP TO :", :align=> :center},
          {:content=> "ADDRESS :", :align=> :center},
          {:content=> "ORDER DATE :", :align=> :center},
          {:content=> "ORDER NO :", :align=> :center},
          {:content=> "PURCHASE ORDER NO :", :align=> :center},
        ]], :column_widths => [200,250,100,100,140], :cell_style => {:size=> 11, :border_color => "000000", :padding=>5})        
        pdf.table([[
          {:content=> record.customer.name, :align=> :center},
          {:content=> customer.office, :align=> :center},
          {:content=> (so.date.to_s if so.present?), :align=> :center},
          {:content=> (so.number if so.present?), :align=> :center},
          {:content=> (so.po_number if so.present?), :align=> :center},
        ]], :column_widths => [200,250,100,100,140], :cell_style => {:size=> 11, :border_color => "000000", :padding=>5})        
        pdf.move_down 5
        pdf.table([["No.","Product Code","Product Name","Product Type", "Batch No", "Qty", "Expired Date", "Physical Condition"]], 
         :column_widths => [20, 110, 110, 110, 110, 110, 110, 110], :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000"})
        c = 1
        items.each do |item|
          pdf.table([[
              {:content=> c.to_s, :align=>:center}, 
              {:content=>item.product.part_id},
              {:content=>item.inspection_name},
              {:content=>item.inspection_type},
              {:content=>item.inspection_batch},
              {:content=>item.inspection_qty},
              {:content=>item.inspection_expired},
              {:content=>item.inspection_physical}
              ]], :column_widths => [20, 110, 110, 110, 110, 110, 110, 110], :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :height=>15})
        c +=1
        end   
        pdf.bounding_box([0,362], :width =>790) do
          10.times do pdf.table([[
            {:content=> ""}, 
            {:content=> ""}, 
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
            ]], :column_widths => [20, 110, 110, 110, 110, 110, 110, 110], :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :height=>15})
          end

          pdf.move_down 15
          pdf.table([[
            {:content=>"Conclusion"},
            {:content=>":"},
            {:content=> record.conclusion}
          ]], :column_widths=>[60, 10, 720], :cell_style=>{:padding=>2, :border_color=>"ffffff"})
          pdf.move_down 10
          pdf.table([["Reason for hold/Notes :"]], :column_widths=>790, :cell_style=>{:align=>:left, :padding => [2, 2, 2, 2], :border_color=>"ffffff"})
          pdf.table([[record.reason_hold]], :column_widths=>790, :cell_style=>{:align=>:left, :padding => [2, 2, 2, 2], :border_color=>"ffffff", :height=>30})
          pdf.move_down 20
          pdf.table([[
            {:content=> "Inspected By :"},
            {:content=> "Verified By :"},
          ]], :column_widths=>[200, 590], :cell_style=>{:align=>:left, :padding => [2, 2, 2, 2], :border_color=>"ffffff"})
        end

        pdf.page_count.times do |i| 
          pdf.bounding_box([0, 50], :width => 790, :height => 70) {
            pdf.go_to_page i+1
            pdf.move_down 30
            pdf.stroke_horizontal_rule
            pdf.draw_text "F-03C-009-Rev 01", :at =>[705,25]       
          }
          pdf.bounding_box([0, 140], :width => 790, :height => 70) {
            pdf.go_to_page i+1
            pdf.stroke_horizontal_rule
            pdf.move_down 12
            pdf.stroke_horizontal_rule
          }

        end

        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  # def destroy
  #   @outgoing_inspection.destroy
  #   respond_to do |format|
  #     format.html { redirect_to outgoing_inspections_url, notice: 'Outgoing inspection was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_outgoing_inspection
      @outgoing_inspection = OutgoingInspection.find(params[:id])
      @outgoing_inspection_items = OutgoingInspectionItem.where(:outgoing_inspection_id=> params[:id], :status=> 'active')
    end

    def set_instance_variable      
      @picking_slips = PickingSlip.where(:status=> 'approved3', :outgoing_inspection_id=>nil)
      @products    = Product.all
      @customers = Customer.all
    end

    def check_status
      if @outgoing_inspection.status == 'approved1'
        respond_to do |format|
          format.html { redirect_to @outgoing_inspection, notice: 'Cannot be edited because it has been approved' }
          format.json { render :show, status: :created, location: @outgoing_inspection }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def outgoing_inspection_params
      params.require(:outgoing_inspection).permit(:number, :customer_id, :date, :picking_slip_id, :conclusion, :reason_hold, :delivery_date, :remarks, :status, :created_by, :created_at, :updated_by, :updated_at)
    end
end
