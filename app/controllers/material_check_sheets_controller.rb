class MaterialCheckSheetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material_check_sheet, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit, :approve]
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

  # GET /material_check_sheets
  # GET /material_check_sheets.json
  def index    
    material_check_sheets = MaterialCheckSheet.where(:company_profile_id=> current_user.company_profile_id).where("material_check_sheets.date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier)
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['Supplier Name','supplier_id']]
      @option_filter_records = material_check_sheets 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        end

        material_check_sheets = material_check_sheets.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    material_check_sheets = material_check_sheets.order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void'])

    @pagy, @material_check_sheets = pagy(material_check_sheets, page: params[:page], items: pagy_items)
  end

  # GET /material_check_sheets/1
  # GET /material_check_sheets/1.json
  def show
  end

  # GET /material_check_sheets/new
  def new
    @material_check_sheet = MaterialCheckSheet.new
  end

  # GET /material_check_sheets/1/edit
  def edit
  end

  # POST /material_check_sheets
  # POST /material_check_sheets.json
  def create
    params[:material_check_sheet]["created_by"] = current_user.id
    params[:material_check_sheet]["img_created_signature"] = current_user.signature
    params[:material_check_sheet]["created_at"] = DateTime.now()
    params[:material_check_sheet]["number"] = document_number(controller_name, params[:material_check_sheet]["date"].to_date, nil, nil, nil)
    periode = params[:material_check_sheet]["date"]
    @material_check_sheet = MaterialCheckSheet.new(material_check_sheet_params)

    respond_to do |format|
      if @material_check_sheet.save
        format.html { redirect_to material_check_sheet_path(:id=> @material_check_sheet.id), notice: "#{@material_check_sheet.number} was successfully created" }
        format.json { render :show, status: :created, location: @material_check_sheet }
      else
        format.html { render :new }
        format.json { render json: @material_check_sheet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /material_check_sheets/1
  # PATCH/PUT /material_check_sheets/1.json
  def update
    params[:material_check_sheet]["updated_by"] = current_user.id
    params[:material_check_sheet]["updated_at"] = DateTime.now()
    periode = params[:material_check_sheet]["date"]
    respond_to do |format|
      if @material_check_sheet.update(material_check_sheet_params) 
        
        format.html { redirect_to material_check_sheets_path(:q=> params[:q], :q1=> params[:q1], :q2=> params[:q2]), notice: 'Good Receipt Note was successfully updated.' }
        format.json { render :show, status: :ok, location: @material_check_sheet }      
      else
        format.html { render :edit }
        format.json { render json: @material_check_sheet.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @material_check_sheet.date.strftime("%Y%m")
    prev_periode = (@material_check_sheet.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @material_check_sheet.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now(), :img_approved1_signature=> current_user.signature}) 
    when 'cancel_approve1'
      @material_check_sheet.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now(), :img_approved1_signature=> nil}) 
    when 'approve2'
      @material_check_sheet.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now(), :img_approved2_signature=> current_user.signature}) 
    when 'cancel_approve2'
      @material_check_sheet.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now(), :img_approved2_signature=> nil})
    when 'approve3'
      @material_check_sheet.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature})  

    when 'cancel_approve3'
      @material_check_sheet.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil}) 
    end

    respond_to do |format|
      format.html { redirect_to material_check_sheet_path(:id=> @material_check_sheet.id), notice: "Good Receipt Note was successfully #{@material_check_sheet.status}." }
      format.json { head :no_content }
    end
  end

  
  def print
    case @material_check_sheet.status 
    when 'approved3'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT.PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @material_check_sheet
      items  = @material_check_sheet_items
      order_number = nil

      document_name = "MATERIAL CHECK SHEET"
      checkbox_icon = "app/assets/images/checkbox.png"  

      user_prepared_by  = header.created
      user_approved1_by = header.approved1 if header.img_approved1_signature.present?
      user_approved2_by = header.approved2 if header.img_approved2_signature.present?
      user_approved3_by = header.approved3 if header.img_approved3_signature.present?

      name_prepared_by  = (user_prepared_by.present? ? user_prepared_by.first_name : nil)
      name_approved1_by = (user_approved1_by.present? ? user_approved1_by.first_name : nil)
      name_approved2_by = (user_approved2_by.present? ? user_approved2_by.first_name : nil)
      name_approved3_by = (user_approved3_by.present? ? user_approved3_by.first_name : nil) 
      
      if user_prepared_by.present? and header.img_created_signature.present?
        img_prepared_by = "public/uploads/signature/#{user_prepared_by.id}/#{header.img_created_signature}"
        if FileTest.exist?("#{img_prepared_by}")
          puts "File Exist"
          puts img_prepared_by
        else
          puts "File not found"
          img_prepared_by = nil
        end
      else
        img_prepared_by = nil
      end     

      if user_approved1_by.present? and header.img_approved1_signature.present?
        img_approved1_by = "public/uploads/signature/#{user_approved1_by.id}/#{header.img_approved1_signature}"
        if FileTest.exist?("#{img_approved1_by}")
          puts "File Exist"
          puts img_approved1_by
        else
          puts "File not found"
          img_approved1_by = nil
        end
      else
        img_approved1_by = nil
      end

      if user_approved2_by.present? and header.img_approved2_signature.present?
        img_approved2_by = "public/uploads/signature/#{user_approved2_by.id}/#{header.img_approved2_signature}"
        if FileTest.exist?("#{img_approved2_by}")
          puts "File Exist"
          puts img_approved2_by
        else
          puts "File not found"
          img_approved2_by = nil
        end
      else
        img_approved2_by = nil
      end

      if user_approved3_by.present? and header.img_approved3_signature.present?
        img_approved3_by = "public/uploads/signature/#{user_approved3_by.id}/#{header.img_approved3_signature}"
        if FileTest.exist?("#{img_approved3_by}")
          puts "File Exist"
          puts img_approved3_by
        else
          puts "File not found"
          img_approved3_by = nil
        end
      else
        img_approved3_by = nil
      end 

      respond_to do |format|
        format.html do

          pdf = Prawn::Document.new(:page_size=> "A5", :page_layout => :landscape,
            :top_margin => 20,
            :bottom_margin => 20, 
            :left_margin=> 40, 
            :right_margin=> 20) 

          # pdf = Prawn::Document.new(:page_size=> "A4",
          #   :top_margin => 20,
          #   :bottom_margin => 20, 
          #   :left_margin=> 40, 
          #   :right_margin=> 20) 
         
          pdf.table([
                  [
              {:image => image_path, :image_width => 90}, 
              {:content=> document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>15}
            ]],
            :column_widths => [150, 370], :cell_style => {:background_color => "f0f0f0", :border_color=> "f0f0f0", :padding=>1}) 
          
          pdf.move_down 10
          pdf.table([
              [
                {:content=>"Doc. Number", :size=>10}, ":", {:content=>"#{header.number if header.present?}", :size=>10}
              ],
              [
                {:content=>"Supplier Name", :size=>10}, ":", {:content=>"#{header.supplier.name if header.present?}", :size=>10}
              ],
              [
                {:content=>"Material Name", :size=>10}, ":", {:content=>"#{header.material.name if header.material.present?}", :size=>10}
              ],[
                {:content=>"Batch Number", :size=>10}, ":", {:content=>"#{header.material_batch_number.number if header.material_batch_number.present?}", :size=>10}
              ],[
                {:content=>"PO # / AWB #", :size=>10}, ":", {:content=>"#{header.material_receiving.purchase_order_supplier.number if header.material_receiving.purchase_order_supplier.present?}", :size=>10}
              ],[
                {:content=>"Quantity", :size=>10}, ":", {:content=>"#{header.quantity}", :size=>10}
              ],[
                {:content=>"EXP Date", :size=>10}, ":", {:content=>"#{header.material_receiving_item.supplier_expired_date}", :size=>10}
              ],[
                {:content=>"DO #", :size=>10}, ":", {:content=>"#{header.material_receiving.sj_number}", :size=>10}
              ],[
                {:content=>"Received Date", :size=>10}, ":", {:content=>"#{header.material_receiving.sj_date.to_date.strftime("%d/%m/%Y") if header.material_receiving.present?}", :size=>10}
              ]
            ], :column_widths => [130, 10, 390], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1, :borders=>[:top]}) 
          
          pdf.move_down 10
          pdf.table([
              [
                {:content=>"No.", :size=>10, :valign=> :center, :align=> :center}, 
                {:content=>"Testing", :size=>10, :valign=> :center, :align=> :center},
                {:content=>"Result", :size=>10, :valign=> :center, :align=> :center}, 
                {:content=>"UoM", :size=>10, :valign=> :center, :align=> :center}
              ], 
              [
                {:content=>"1", :size=>10, :align=> :center}, 
                {:content=>"Quantity of samples**", :size=>10},
                {:content=> "#{number_with_precision(header.quantity.to_f, precision: 0, delimiter: ".", separator: ",")}", :size=>10, :align=> :right}, 
                {:content=>"#{header.unit.name if header.unit.present?}", :size=>10, :align=> :center}
              ], 
              [
                {:content=>"2", :size=>10, :align=> :center}, 
                {:content=>"Result of inspection/sample verification**", :size=>10}, 
                {:content=>"#{header.inspection_status}", :size=>10, :colspan=> 2, :align=> :center}
              ]
            ], :column_widths => [30, 250, 120, 100], :cell_style => {:border_width => 0.1, :border_color => "000000", :padding=> [1, 5, 5, 5]}) 
          pdf.move_down 5
          pdf.text "** Attach of Inspection Checklist Sheet & Inspection Result Sheet", :size=>8
          pdf.move_down 7
          pdf.text "Conclusion: #{header.qc_conclusion}", :size=> 10, :font_style=> :bold
          pdf.move_down 5
          pdf.text "Remarks: #{header.remarks}", :size=> 10, :font_style=> :bold
          pdf.move_down 7
          pdf.stroke_horizontal_rule

          pdf.move_down 40
          pdf.table([
            [
              {:content=>"Prepared by", :size=>10, :width=> 80}, ":", "_______________", {:content=>"", :size=>10, :width=> 80}, 
              {:content=>"Approved by", :size=>10, :width=> 80}, ":", "_______________"
            ],[
              {:content=>"", :size=>10, :width=> 80}, "", 
              {:content=>"#{name_prepared_by.present? ? name_prepared_by : ('<i>Sign Name</i>')}", :size=>9, :align=> :center, :valign=> :top}, 
              {:content=>"", :size=>10, :width=> 80}, 
              {:content=>"", :size=>10, :width=> 80}, "", 
              {:content=>"#{header.img_approved3_signature.present? ? name_approved3_by : '(<i>Sign Name</i>'}", :size=>9, :align=> :center, :valign=> :top}
            ]
          ], :cell_style => {:border_width => 0, :inline_format=>true} )
          pdf.move_down 30

          date_prepared = header.created_at.present? ? header.created_at.strftime('%d-%m-%Y') : ''
          date_approve3 = header.approved3_at.present? ? header.approved3_at.strftime('%d-%m-%Y') : ''
          
          pdf.bounding_box([80, 85], :width => 410) do
            pdf.table([
              [(img_prepared_by.present? ? {:image=>img_prepared_by, :position=>:center, :scale=>0.23, :vposition=>:center, :height=>60, :rowspan=>2, :padding=>0} : {:content=>'', :height=>60, :rowspan=>2}), {:content=>"", :align=>:center}],
              [{:content=>"#{date_prepared}", :padding=>[6,6,6,0]}]
            ], :column_widths => [100,50], :cell_style => {:border_color => "00000", :border_width=>0, :size=>8})
          end

          pdf.bounding_box([360, 85], :width => 410) do
            pdf.table([
              [(img_approved3_by.present? ? {:image=>(img_approved3_by), :position=>:center, :scale=>0.23, :vposition=>:center, :height=>60, :rowspan=>2, :padding=>0} : {:content=>'', :height=>60, :rowspan=>2}), {:content=>"", :align=>:center}],
              [{:content=>"#{date_approve3}", :padding=>[6,6,6,0]}]
            ], :column_widths => [100,50], :cell_style => {:border_color => "000000", :border_width=>0, :size=>8})
          end

          # footer
          pdf.page_count.times do |i|
            pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => 100) {
              pdf.go_to_page i+1
              pdf.text "F-03C-002-Rev 03", :align => :right, :size => 8 
            }
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
          header.update_columns({
            :printed_by=> current_user.id,
            :printed_at=> DateTime.now()
          })
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @material_check_sheet, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @material_check_sheet }
      end
    end
  end
  # DELETE /material_check_sheets/1
  # DELETE /material_check_sheets/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to material_check_sheets_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_check_sheet
      @material_check_sheet = MaterialCheckSheet.find_by(:id=> params[:id])
      if @material_check_sheet.present?
      else
        respond_to do |format|
          format.html { redirect_to material_check_sheets_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end
    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @suppliers    = Supplier.where(:status=> 'active').order("name asc")
      @materials    = Material.all
      @units        = Unit.all.order("name asc")
      @material_batch_number  = MaterialBatchNumber.where(:status=> 'active').includes(:material_receiving_items, material_receiving_item: [material_receiving: [:supplier, :purchase_order_supplier]], material: [:unit])
    end

    def check_status     
      noitce_msg = nil 
      if @material_check_sheet.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          noitce_msg = 'Cannot be edited because it has been approved'
        end
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @material_check_sheet.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @material_check_sheet, alert: noitce_msg }
          format.json { render :show, status: :created, location: @material_check_sheet }
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def material_check_sheet_params
      params.require(:material_check_sheet).permit(:company_profile_id, :number, :date, :supplier_id, :material_id, :material_receiving_id, :material_receiving_item_id, :remarks, :material_batch_number_id, :quantity, :unit_id, :inspection_status, :qc_conclusion, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end

end
