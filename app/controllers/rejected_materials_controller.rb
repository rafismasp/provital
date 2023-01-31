class RejectedMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rejected_material, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /picking_slips
  # GET /picking_slips.json
  def index
    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d"))
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : DateTime.now().at_end_of_month().strftime("%Y-%m-%d"))
    rejected_materials = RejectedMaterial.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    #@rejected_materials = RejectedMaterial.all
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']] 
      @option_filter_records = rejected_materials

      if params[:filter_column].present?
       rejected_materials = rejected_materials.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    # filter select - end
  
    @material_outgoing_items = MaterialOutgoingItem.where(:material_outgoing_id=> params[:material_outgoing_id], :status=>'active') if params[:material_outgoing_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @rejected_materials = pagy(rejected_materials, page: params[:page], items: pagy_items)
  end

  # GET /picking_slips/1
  # GET /picking_slips/1.json
  def show
  end

  # GET /picking_slips/new
  def new
    @rejected_material = RejectedMaterial.new
  end

  # GET /picking_slips/1/edit
  def edit
  end

  # POST /picking_slips
  # POST /picking_slips.json
  def create
    params[:rejected_material]["created_by"] = current_user.id
    params[:rejected_material]["created_at"] = DateTime.now()
    params[:rejected_material]["number"] = document_number(controller_name, DateTime.now(), nil, nil, nil)
    @rejected_material = RejectedMaterial.new(rejected_material_params)

    respond_to do |format|
      if @rejected_material.save
        params[:new_record_item].each do |item|
          rejected_item = RejectedMaterialItem.create({
            :rejected_material_id=> @rejected_material.id,
            :material_outgoing_item_id=> item["material_outgoing_item_id"],
            :ng_supplier => item["ng_supplier"],
            :production_process=> item["production_process"], 
            :documentation=> item["documentation"], 
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?

        format.html { redirect_to @rejected_material, notice: 'Rejected material was successfully created.' }
        format.json { render :show, status: :created, location: @rejected_material }
      else
        format.html { render :new }
        format.json { render json: @rejected_material.errors, status: :unprocessable_entity }
      end
      logger.info @rejected_material.errors
    end
  end

  # PATCH/PUT /picking_slips/1
  # PATCH/PUT /picking_slips/1.json
  def update
    params[:rejected_material]["updated_by"] = current_user.id
    params[:rejected_material]["updated_at"] = DateTime.now()
    params[:rejected_material]["number"] = @rejected_material.number
    params[:rejected_material]["date"] = @rejected_material.date
    params[:rejected_material]["outgoing_id"] = @rejected_material.material_outgoing_id
    respond_to do |format|
      if @rejected_material.update(rejected_material_params)
        params[:record_item].each do |item|
          rejected_item = RejectedMaterialItem.find_by(:id=> item["id"])
          rejected_item.update_columns({
            :ng_supplier=> item["ng_supplier"],
            :production_process=> item["production_process"],
            :documentation=> item["documentation"],
            :updated_at=> DateTime.now(), :updated_by=> @rejected_material.created_by
          })
        end if params[:record_item].present?
        format.html { redirect_to @rejected_material, notice: 'Rejected material was successfully updated.' }
        format.json { render :show, status: :ok, location: @rejected_material }
      else
        format.html { render :edit }
        format.json { render json: @rejected_material.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve
    case params[:status]
    when 'approve1'
      @rejected_material.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @rejected_material.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @rejected_material.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @rejected_material.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()}) 
    when 'approve3'
      @rejected_material.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @rejected_material.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
    end
    respond_to do |format|
      format.html { redirect_to rejected_material_path(:id=> @rejected_material.id), notice: "Rejected material was successfully #{@rejected_material.status}." }
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
        record = @rejected_material
        items = @rejected_material_items
        user_reported_by = User.find_by(:id=>record.approved1_by)
        user_verified_by = User.find_by(:id=>record.approved2_by)
        user_approved_by = User.find_by(:id=>record.approved3_by)
        material_outgoing = MaterialOutgoing.find_by(:id=>record.material_outgoing_id)
        tbl_width = [20, 160,90, 80, 80, 60, 80]

        pdf.table([
          [{:image=> image_path, :scale=>0.04, :position=>:center, :padding=>[5,5,5,5], :vposition=>:center, :rowspan=>2}, {:content=> "REJECTED MATERIAL FORM", :align=>:center, :padding=>[15,5,5,5], :size=> 18, :rowspan=>2}, {:content=> "Material Issue No : #{material_outgoing.number}", :size=> 11}],
          [{:content=> "Product Batch No : #{material_outgoing.product_batch_number.number}", :size=> 11}]
        ], :column_widths => [140, 430, 220], :cell_style => {:border_color => "000000", :borders=>[:top, :right, :left, :bottom]})
        pdf.move_down 10
        pdf.table([
          [{:content=>"No.", :valign=>:center, :rowspan=>2}, {:content=>"Material Name", :valign=>:center, :rowspan=>2}, {:content=>"Batch No", :valign=>:center, :rowspan=>2}, {:content=>"Reason For Rejected (Pcs)", :colspan=>3}],
          [{:content=>"NG Supplier"}, {:content=>"Production Process"}, {:content=>"Documentation"}]
        ], :column_widths => [25, 365, 100, 100, 100, 100], :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :height=>20})
        c = 1
        items.each do |item|
          pdf.table([[
              {:content=> c.to_s, :align=>:center}, 
              {:content=>item.material_outgoing_item.material.name},
              {:content=>item.material_outgoing_item.material_batch_number.number, :align=>:center, },
              {:content=>item.ng_supplier.to_s, :align=>:center, },
              {:content=>item.production_process.to_s, :align=>:center, },
              {:content=>item.documentation.to_s, :align=>:center, }
              ]], :column_widths => [25, 365, 100, 100, 100, 100], :cell_style => {:padding => [2, 2, 2, 2], :border_color=>"000000", :valign=>:center, :height=>30})
          c +=1
        end  
        pdf.bounding_box([0,465.7], :width =>790) do
          10.times do pdf.table([[
            {:content=> ""}, 
            {:content=> ""}, 
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
            {:content=> ""}
            ]], :column_widths => [25, 365, 100, 100, 100, 100], :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :height=>30})
          end
          pdf.move_down 20
          pdf.table([[
            {:content=> ""},
            {:content=> "Reported By :"},
            {:content=> "Verified By :"},
            {:content=> "Approved By :"},
          ]], :column_widths=>[490, 100, 100, 100], :cell_style=>{:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"ffffff"})
          pdf.table([[
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
            {:content=> ""},
          ]], :column_widths=>[490, 100, 100, 100], :cell_style=>{:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"ffffff", :height=>70})
          pdf.table([[
            {:content=> ""},
            {:content=> "(#{user_reported_by.first_name.camelize if user_reported_by.present?})"},
            {:content=> "(#{user_verified_by.first_name.camelize if user_verified_by.present?})"},
            {:content=> "(#{user_approved_by.first_name.camelize if user_approved_by.present?})"},
          ]], :column_widths=>[490, 100, 100, 100], :cell_style=>{:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"ffffff"})
        end

        pdf.page_count.times do |i| 
          pdf.bounding_box([0, 50], :width => 790, :height => 70) {
            pdf.go_to_page i+1
            pdf.move_down 30
            pdf.stroke_horizontal_rule
            pdf.draw_text "SOP-03C-001", :at =>[0,25]       
            pdf.draw_text "F-03C-003-Rev 03", :at =>[705,25]       
          }

        end

        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end

  # def export
  #   template_report(controller_name, current_user.id, nil)
  # end

  # def destroy
  #   @rejected_material.destroy
  #   respond_to do |format|
  #     format.html { redirect_to rejected_materials_url, notice: 'Rejected Material was successfully destroyed.' }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rejected_material
      @rejected_material = RejectedMaterial.find_by(:id=> params[:id])
      @rejected_material_items = RejectedMaterialItem.where(:rejected_material_id=> params[:id], :status=> 'active')
    end

    def set_instance_variable      
      @material_outgoings = MaterialOutgoing.where(:status=> 'approved3')
      @customers = Customer.where(:status=> 'active')
    end

    def check_status
      if @rejected_material.status == 'approved1'
        respond_to do |format|
          format.html { redirect_to @rejected_material, notice: 'Cannot be edited because it has been approved' }
          format.json { render :show, status: :created, location: @rejected_material }
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rejected_material_params
      params.require(:rejected_material).permit(:number, :material_outgoing_id, :remarks, :date, :status, :created_by, :created_at, :updated_by, :updated_at, )
    end
end
