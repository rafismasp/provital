class PdmsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pdm, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /pdms
  # GET /pdms.json
  def index

    pdms = Pdm.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Supplier Name', 'supplier_id'], ['Currency', 'currency_id']] 
      @option_filter_records = pdms
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        end

        pdms = pdms.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      pdms = PdmItem.where(:status=> 'active').includes(:pdm).where(:pdms => {:company_profile_id => current_user.company_profile_id }).order("pdms.number desc")      
    else
      select_product_batch_number_id = PdmItem.where(:status=> 'active').includes(:pdm).where(:pdms => {:company_profile_id => current_user.company_profile_id }).order("pdms.number desc").group("pdm_items.product_batch_number_id").select("pdm_items.product_batch_number_id")
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :id=> select_product_batch_number_id) if params[:view_kind] == 'batch_number'
      pdms = pdms.order("number desc")
    end

    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @pdms = pagy(pdms, page: params[:page], items: pagy_items) 
  end

  # GET /pdms/1
  # GET /pdms/1.json
  def show
  end

  # GET /pdms/new
  def new
    @pdm = Pdm.new
  end
  # GET /pdms/1/edit
  def edit
  end

  # POST /pdms
  # POST /pdms.json
  def create
    params[:pdm]["outstanding"] = 0
    params[:pdm]["company_profile_id"] = current_user.company_profile_id
    params[:pdm]["created_by"] = current_user.id
    params[:pdm]["img_created_signature"] = current_user.signature
    params[:pdm]["created_at"] = DateTime.now()
    params[:pdm]["number"] = document_number(controller_name, params[:pdm]['date'].to_date, nil, nil, nil)
    @pdm = Pdm.new(pdm_params)

    respond_to do |format|
      sum_outstanding = 0
      params[:new_record_item].each do |item|
        @pdm.pdm_items.build({
          :material_id=> item["material_id"],
          :quantity=> item["quantity"],
          :outstanding_prf=> item["quantity"],
          :outstanding=> item["quantity"],
          :remarks=> item["remarks"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })
        sum_outstanding += item["outstanding"].to_f
      end if params[:new_record_item].present?

      if @pdm.save
        @pdm.update_columns(:outstanding=> sum_outstanding)
        format.html { redirect_to pdm_path(:id=> @pdm.id), notice: "#{@pdm.number} supplier was successfully created." }
        format.json { render :show, status: :created, location: @pdm }
      else
        format.html { render :new }
        format.json { render json: @pdm.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pdms/1
  # PATCH/PUT /pdms/1.json
  def update
    respond_to do |format|
      params[:pdm]["updated_by"] = current_user.id
      params[:pdm]["updated_at"] = DateTime.now()
      params[:pdm]["number"] = @pdm.number
      if @pdm.update(pdm_params)
        params[:new_record_item].each do |item|
          if @pdm.automatic_calculation.to_i == 0
            record_item = PdmItem.new({
              :pdm_id=> @pdm.id,
              :material_id=> item["material_id"],
              :quantity=> item["quantity"],
              :outstanding_prf=> item["quantity"],
              :outstanding=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            record_item.save 
          end
        end if params[:new_record_item].present?

        params[:record_item].each do |item|
          record_item = PdmItem.find_by(:id=> item["id"])
          if record_item.present?
            case item["status"]
            when 'deleted'
              record_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })        
            else
              prf_quantity = (record_item.quantity.to_f - record_item.outstanding_prf.to_f)
              po_quantity  = (record_item.quantity.to_f - record_item.outstanding.to_f)
              if record_item.quantity.to_f != item["quantity"].to_f
                outstanding_prf = (item["quantity"].to_f-prf_quantity.to_f)
                outstanding_po  = (item["quantity"].to_f-po_quantity.to_f)
              else
                outstanding_prf = record_item.outstanding_prf
                outstanding_po  = record_item.outstanding
              end
              pdm_quantity = (item["quantity"].present? ? item["quantity"].to_f : record_item.quantity)

              record_item.update_columns({
                :quantity=> pdm_quantity,
                :outstanding_prf=> outstanding_prf,
                :outstanding=> outstanding_po,
                :remarks=> item["remarks"],
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            end
          end
        end if params[:record_item].present?

        @pdm.update_columns(:outstanding=> @pdm_items.sum(:outstanding))
        format.html { redirect_to @pdm, notice: 'Purchase order supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @pdm }
      else
        format.html { render :edit }
        format.json { render json: @pdm.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pdms/1
  # DELETE /pdms/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to pdms_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @pdm.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @pdm.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @pdm.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @pdm.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @pdm.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature, :outstanding=> @pdm_items.sum(:outstanding) }) 
    when 'cancel_approve3'
      @pdm.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
    end
    respond_to do |format|
      format.html { redirect_to pdm_path(:id=> @pdm.id), notice: "Purchase Order was successfully #{@pdm.status}." }
      format.json { head :no_content }
    end
  end

  def print
    if @pdm.status == 'approved3'  
      sop_number      = ""
      form_number     = "F-03B-002-Rev 04"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. Provital Perdana"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @pdm
      items  = @pdm_items

      name_prepared_by = account_name(header.created_by) 
      name_approved_by = account_name(header.approved3_by)
      
      user_prepared_by = User.find_by(:id=> header.created_by)
      
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

      if header.status == 'approved3' and header.img_approved3_signature.present?
        user_approved_by = User.find_by(:id=> header.approved3_by)
        if user_approved_by.present?
          img_approved_by = "public/uploads/signature/#{user_approved_by.id}/#{header.img_approved3_signature}"
          if FileTest.exist?("#{img_approved_by}")
            puts "File Exist"
            puts img_approved_by
          else
            puts "File not found: #{img_approved_by}"
            img_approved_by = nil
          end
        else
          img_approved_by = nil
        end
      else
        img_approved_by = nil
      end  

      subtotal = 0

      document_name = "PEMBELIAN DIMUKA"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 75
          tbl_width = [30, 300, 75, 45, 143]
          c = 1
          pdf.move_down 2
          items.each do |item|          
            if item.material.present?
              part = item.material
            end
            # (1..30).each do 
              y = pdf.y
              pdf.start_new_page if y < 600
              pdf.move_down 75 if y < 600
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center, :size=> 10}, 
                  {:content=>(part.name if part.present?), :size=> 10},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                  {:content=> "#{(part.present? ? part.unit_name : nil)}", :align=>:center, :size=> 10},
                  {:content=> "#{item.remarks}", :align=>:center, :size=> 10}
                  
                ]], :column_widths => tbl_width, :cell_style => {:padding => [4, 5, 0, 4], :border_color=>"ffffff"})
              c +=1
              subtotal += item.quantity.to_f
            # end
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1

              }

              pdf.bounding_box([0, 840], :width => 594, :height => 380) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.table([
                  [ 
                    "", 
                    {:content=>document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>12}, "",
                    {:image => image_path, :image_width => 100}
                  ]],:column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.stroke_horizontal_rule
                # pdf.table([
                #   [ 
                #     "Tanggal : #{header.date}", 
                #     {:content=> "No. #{header.number}", :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", ""
                #   ] ],:column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 1, :border_color => "000000", :padding=>1}) 
                pdf.table([
                  [ 
                    {:content=> "Tanggal : #{header.date}", :size=>10}, "", 
                    {:content=> "PDM NO: #{header.number}", :size=>10, :align=> :right}
                  ] ],:column_widths => [200, 194, 200], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>5}) 
                
                # pdf.move_down 5
                pdf.stroke_horizontal_rule
                pdf.move_down 5
                       

                pdf.table([ [
                  {:content=>"No.", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Description", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Jumlah", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Unit", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Remarks", :height=> 25, :valign=> :center, :align=> :center}]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
                pdf.move_down 215
                pdf.table([
                  [
                    "", {:content=> "Disetujui oleh:", :align=> :center},"", {:content=> "Diminta oleh:", :align=> :center}, ""
                  ]
                  ], :column_widths => [47, 147, 200, 147, 47], :cell_style => {:border_width => 0, :size=> 9, :border_color => "000000", :padding=>1})  

                pdf.image "#{img_prepared_by}", :at => [425,535], :width => 100 if img_prepared_by.present?
                pdf.image "#{img_approved_by}", :at => [80,535], :width => 100 if img_approved_by.present?  

                pdf.move_down 55
                pdf.table([
                  [
                    "", {:content=> " #{name_approved_by} ", :align=> :center}, "", {:content=> " #{name_prepared_by} ", :align=> :center}, ""
                  ]
                  ], :column_widths => [47, 147, 200, 147, 47], :cell_style => {:border_width => 0, :size=> 9, :border_color => "000000", :padding=>1})  
                

                pdf.move_down 10
                pdf.table([
                  [
                    "", "","", "", {:content=> "#{form_number}", :align=> :right}
                  ]
                  ], :column_widths => [47, 147, 200, 47, 147], :cell_style => {:border_width => 0, :size=> 9, :border_color => "000000", :padding=>1})  

              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 763
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 200) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              pdf.move_down 5
              pdf.stroke_horizontal_rule

            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                # pdf.move_up 330
                
                # pdf.table([
                #   [
                #     "White : Finance", "Red : Purchasing", {:content=> "Yellow : Warehouse", :align=> :right}, {:content=> "#{form_number}", :align=> :right}
                #   ]
                #   ], :column_widths => [147, 147, 147, 147], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  

              }

              # pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @pdm, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @pdm }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
    puts "ini"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pdm
      @pdm = Pdm.find_by(:id=> params[:id])
      if @pdm.present?
        @pdm_items = PdmItem.where(:status=> 'active').includes(:pdm).where(:pdms => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("pdms.number desc")      
      else
        respond_to do |format|
          format.html { redirect_to pdms_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin].to_date.strftime("%Y-%m-%d")
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().to_date.strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().strftime("%Y-%m-%d")
      end
      @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    end

    def check_status     
      if @pdm.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @pdm.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @pdm, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @pdm }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pdm_params
      params.require(:pdm).permit(:company_profile_id, :pdm_pic_id, :number, :date, :remarks, :purchase_request_id, :created_by, :created_at, :updated_at, :updated_by, :img_created_signature)
    end
end
