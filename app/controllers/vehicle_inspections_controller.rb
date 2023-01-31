class VehicleInspectionsController < ApplicationController
  before_action :set_vehicle_inspection, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable
  before_action :authenticate_user!
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  def index
    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d"))
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : DateTime.now().at_end_of_month().strftime("%Y-%m-%d"))
    vehicle_inspections = VehicleInspection.where("date between ? and ?", session[:date_begin], session[:date_end]).order("number desc")

  	#@vehicle_inspections = VehicleInspection.all
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']]
      @option_filter_records = vehicle_inspections 
      
      if params[:filter_column].present?
        vehicle_inspections = vehicle_inspections.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @vehicle_inspections = pagy(vehicle_inspections, page: params[:page], items: pagy_items) 
  end
  
  def show
  end
  
  def new
  	@vehicle_inspection = VehicleInspection.new
  end
  
  def edit
  end
  
  def create
    params[:vehicle_inspection]["created_by"] = current_user.id
    params[:vehicle_inspection]["created_at"] = DateTime.now()
    params[:vehicle_inspection]["number"] = document_number(controller_name, DateTime.now(), nil, nil, nil)
  	@vehicle_inspection = VehicleInspection.new(vehicle_inspection_params)

  	respond_to do |format|
      if @vehicle_inspection.save
        do_id = DeliveryOrder.find_by(:id=>@vehicle_inspection.delivery_order_id)
        do_id.update({
          :vehicle_inspection_id=>@vehicle_inspection.id
        })

        params[:record_item].each do |item|
          transfer_item = VehicleInspectionItem.create({
            :vehicle_inspection_id=> @vehicle_inspection.id,
            :kind_doc=> item["kind_doc"],
            :condition=> item["condition"],
            :description=> item["description"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> @vehicle_inspection.created_by
          })
        end if params[:record_item].present?

        format.html { redirect_to @vehicle_inspection, notice: 'Vehicle inspection selection was successfully created.' }
        format.json { render :show, status: :created, location: @vehicle_inspection }
      else
        format.html { render :new }
        format.json { render json: @vehicle_inspection.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
  	respond_to do |format|
      params[:vehicle_inspection]["created_by"] = current_user.id
      params[:vehicle_inspection]["created_at"] = DateTime.now()
      params[:vehicle_inspection]["number"] = @vehicle_inspection.number
      params[:vehicle_inspection]["delivery_order_id"] = @vehicle_inspection.delivery_order_id
      if @vehicle_inspection.update(vehicle_inspection_params)
        params[:record_item].each do |item|
          vehicle_item = VehicleInspectionItem.find_by(:id=> item["id"])
          vehicle_item.update_columns({
            :condition=> item["condition"],
            :description=> item["description"],
            :updated_at=> DateTime.now(), :updated_by=> @vehicle_inspection.created_by
          })
        end if params[:record_item].present?
        format.html { redirect_to @vehicle_inspection, notice: 'Vehicle Inspection was successfully updated.' }
        format.json { render :show, status: :ok, location: @vehicle_inspection }
      else
        format.html { render :edit }
        format.json { render json: @vehicle_inspection.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @vehicle_inspection.date.strftime("%Y%m")
    prev_periode = (@vehicle_inspection.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @vehicle_inspection.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @vehicle_inspection.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    end
    respond_to do |format|
      format.html { redirect_to vehicle_inspection_path(:id=> @vehicle_inspection.id), notice: "Vehicle inspection was successfully #{@vehicle_inspection.status}." }
      format.json { head :no_content }
    end
  end

  def print
    #company         = "PT. PRIBADI INTERNATIONAL"
    #company_address = "Kawasan Delta Silicon 3 
    #Jl.Pinang Blok F 17 No.3 
    #Lippo Cikarang Bekasi"
    image_path      = "app/assets/images/logo.png"
    respond_to do |format|
      format.html do
        pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10) 
        pdf.font "Times-Roman"
        pdf.font_size 10
        record = @vehicle_inspection
        items = @vehicle_inspection_items
        user_inspection_by = User.find_by(:id=>record.created_by)
        user_verified_by = User.find_by(:id=>record.approved1_by)
        tbl_width = [20, 160,90, 80, 80, 60, 80]
        pdf.move_down 30
        pdf.table([
          [{:image=> image_path, :scale=>0.03, :position=> :center}]],
          :column_widths => [570], :cell_style => {:size=> 17, :border_color => "000000", :borders=>[:top, :right, :left], :padding=>[5,1,5,1]})
        pdf.table([
          [{:content=> "VEHICLE INSPECTION FORM", :align=> :center}]],
          :column_widths => [570], :cell_style => {:size=> 17, :border_color => "000000", :borders=>[:right, :bottom, :left], :padding=>[5,1,5,1]})  
        pdf.table([
          [{:content=> "", :align=> :center}]],
          :column_widths => [570], :cell_style => {:size=> 17, :border_color => "000000", :padding=>15})        
        pdf.move_down 15
        pdf.table([[
              {:content => "Tanggal", :borders=>[:left, :top], :padding=>[15,1,1,5]}, 
              {:content=> ":", :borders=>[:top], :padding=>[15,1,1,5]},
              {:content=> "#{record.date.strftime("%m-%d-%Y")}", :borders=>[:top, :right], :padding=>[15,1,1,5]},
            ]], :column_widths=> [100, 20, 450], :cell_style => {:border_color => "000000", :header => true})
        pdf.table([[
              {:content => "Jenis Kendaraan", :borders=>[:left], :border_color => "000000", :padding=>[5,1,1,5]}, 
              {:content=> ":", :borders=>[:top], :border_color => "ffffff", :padding=>[5,1,1,5]},
              {:content=> "#{record.vehicle_type}", :borders=>[:right], :border_color => "000000", :padding=>[5,1,1,5]},
            ]], :column_widths=> [100, 20, 450], :cell_style => {:header => true})
        pdf.table([[
              {:content => "Plat Nomor", :borders=>[:left], :border_color => "000000", :padding=>[5,1,1,5]}, 
              {:content=> ":", :borders=>[:top], :border_color => "ffffff", :padding=>[5,1,1,5]},
              {:content=> "#{record.vehicle_no}", :borders=>[:right], :border_color => "000000", :padding=>[5,1,1,5]},
            ]], :column_widths=> [100, 20, 450], :cell_style => {:header => true})
        pdf.table([[
              {:content => "No. Delivery", :borders=>[:left], :border_color => "000000", :padding=>[5,1,15,5]}, 
              {:content=> ":", :borders=>[:top], :border_color => "ffffff", :padding=>[5,1,15,5]},
              {:content=> "#{record.delivery_order.number}", :borders=>[:right], :border_color => "000000", :padding=>[5,1,15,5]},
            ]], :column_widths=> [100, 20, 450], :cell_style => {:header => true})
        pdf.table([["No.","Jenis Dokumen","Status","Keterangan"]], 
         :column_widths => [20, 170, 80, 300], :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000"})
        c = 1
        items.each do |item|
          pdf.table( [ [{ :content=> c.to_s, :align=>:center}, 
              {:content=>(item.kind_doc)},
              {:content=>(item.condition), :align=>:center},
              {:content=>(item.description if item.present?)}
              ]], 
              :column_widths => [20, 170, 80, 300], :cell_style => {:padding => [2, 2, 2, 2], :border_color=>"000000", :valign=>:center, :height=>40})
        c +=1
        end 
        pdf.move_down 10
        pdf.table([[
              {:content => "Diinspeksi oleh", :border_color => "000000", :padding=>[5,1,5,1]}, 
              {:content=> "Diverifikasi oleh", :border_color => "000000", :padding=>[5,1,5,1]},
            ]], :column_widths=> [285, 285], :cell_style => {:header => true, :align=>:center}) 
        pdf.table([[
              {:content => "", :border_color => "000000", :borders=>[:left,:top,:right], :padding=>[5,1,5,1]}, 
              {:content=> "", :border_color => "000000", :borders=>[:left,:top,:right], :padding=>[5,1,5,1]},
            ]], :column_widths=> [285, 285], :cell_style => {:header => true, :align=>:center, :height=>60})
        pdf.table([[
              {:content => "(#{user_inspection_by.first_name.camelize if user_inspection_by.present?})", :border_color => "000000", :borders=>[:right,:bottom,:left], :padding=>[5,1,5,1]}, 
              {:content=> "(#{user_verified_by.first_name.camelize if user_verified_by.present?})", :border_color => "000000", :borders=>[:right,:bottom,:left], :padding=>[5,1,5,1]},
            ]], :column_widths=> [285, 285], :cell_style => {:header => true, :align=>:center})
        pdf.page_count.times do |i| 
          pdf.bounding_box([0, 50], :width => 570, :height => 70) {
            pdf.go_to_page i+1
            pdf.move_down 30
            pdf.stroke_horizontal_rule
            pdf.draw_text "F-03C-009-Rev 01", :at =>[495,25]
                  
          }
        end
        #pdf.page_count.times do |i|
        #  den_row = 0
        #  tbl_top_position = 685
          
        #  tbl_width.each do |i|
        #    # puts den_row
        #    den_row += i
        #    pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 550) do
        #      pdf.stroke_color '000000'
        #      pdf.stroke_bounds
        #    end
        #  end

        #  pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 16) do
        #    pdf.stroke_color '000000'
        #    pdf.stroke_bounds
        #  end
        #end
        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_inspection
      @vehicle_inspection = VehicleInspection.find(params[:id])
      @vehicle_inspection_items = VehicleInspectionItem.where(:vehicle_inspection_id => @vehicle_inspection.id, :status=>'active')
    end

    def set_instance_variable
      # text = 'new','approved1','canceled1'
    	#@delivery_orders = DeliveryOrder.where(:status=>'approved3').where('id not in (select delivery_order_id from vehicle_inspections where status in ?)', text)
      @delivery_orders = DeliveryOrder.where(:status=>'approved3', :vehicle_inspection_id=>nil)
    end

    def check_status
      if @vehicle_inspection.status == 'approved1'
        respond_to do |format|
          format.html { redirect_to @vehicle_inspection, notice: 'Cannot be edited because it has been approved' }
          format.json { render :show, status: :created, location: @vehicle_inspection }
        end
      end
    end

    def vehicle_inspection_params
      params.require(:vehicle_inspection).permit(:delivery_order_id, :number, :date, :vehicle_type, :vehicle_no, :status, :created_by, :created_at, :updated_at, :updated_by, :approved_at, :approved_by)
    end
end
