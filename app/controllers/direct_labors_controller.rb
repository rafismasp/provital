class DirectLaborsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_direct_labor, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /direct_labors
  # GET /direct_labors.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = (params[:date_end].to_date-2.weeks).to_date.strftime("%Y-%m-%d")
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = (DateTime.now()-2.weeks).to_date.strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().strftime("%Y-%m-%d")
    end

    direct_labors = DirectLabor.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'], ['Supplier Name', 'supplier_id'], ['Currency', 'currency_id']] 
      @option_filter_records = direct_labors
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        end

        direct_labors = direct_labors.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:view_kind]
    when 'item'
      direct_labors = DirectLaborItem.where(:status=> 'active').includes(:direct_labor).where(:direct_labors => {:company_profile_id => current_user.company_profile_id }).order("direct_labors.number desc")      
    else
      select_product_batch_number_id = DirectLaborItem.where(:status=> 'active').includes(:direct_labor).where(:direct_labors => {:company_profile_id => current_user.company_profile_id }).order("direct_labors.number desc").group("direct_labor_items.product_batch_number_id").select("direct_labor_items.product_batch_number_id")
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :id=> select_product_batch_number_id) if params[:view_kind] == 'batch_number'
      direct_labors = direct_labors.order("number desc")
      @direct_labor_price = @direct_labor_prices.find_by(:product_id=> params[:product_id])
      if @direct_labor_price.present?
        @direct_labor_price_details = DirectLaborPriceDetail.where(:direct_labor_price_id=> @direct_labor_price.id, :status=> 'active') 
      else
        @direct_labor_price_details = nil 
      end
      if params[:partial] == 'change_activity_labor'
        direct_labor_outstanding = DirectLaborOutstanding.find_by(:product_batch_number_id=> params[:product_batch_number_id], :direct_labor_price_detail_id=> params[:direct_labor_price_detail_id])
        product_batch_number = @product_batch_number.find_by(:id=> params[:product_batch_number_id]) if params[:product_batch_number_id].present?
        @outstanding_direct_labor = (direct_labor_outstanding.present? ? direct_labor_outstanding.outstanding : nil)
        @outstanding_direct_labor = (product_batch_number.present? ? product_batch_number.outstanding_direct_labor : 0) if @outstanding_direct_labor.blank?
        
        permission_base = PermissionBase.find_by(:link=> "/#{controller_name}")
        user_permission = UserPermission.find_by(:company_profile_id=> current_user.company_profile_id, :user_id=> current_user.id, :permission_base_id=> permission_base.id, "access_approve3".to_sym => 1) if permission_base.present?
        if user_permission.blank?
          params[:edit_price_disabled] = true
        end
      end
    end

    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @direct_labors = pagy(direct_labors, page: params[:page], items: pagy_items) 
  end

  # GET /direct_labors/1
  # GET /direct_labors/1.json
  def show
  end

  # GET /direct_labors/new
  def new
    @direct_labor = DirectLabor.new
  end
  # GET /direct_labors/1/edit
  def edit
  end

  # POST /direct_labors
  # POST /direct_labors.json
  def create
    params[:direct_labor]["company_profile_id"] = current_user.company_profile_id
    params[:direct_labor]["created_by"] = current_user.id
    params[:direct_labor]["created_at"] = DateTime.now()
    params[:direct_labor]["number"] = document_number(controller_name, params[:direct_labor]['date'].to_date, nil, nil, nil)
    @direct_labor = DirectLabor.new(direct_labor_params)

    respond_to do |format|
      if @direct_labor.save
        params[:new_record_item].each do |item|
          check_product_bn = ProductBatchNumber.find_by(:id=> item["product_batch_number_id"])

          direct_labor_item = DirectLaborItem.new({
            :direct_labor_id=> @direct_labor.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :direct_labor_price_id=> item["direct_labor_price_id"],
            :unit_price=> item["unit_price"],

            :activity_h1=> item["activity_h1"],
            :quantity_h1=> item["quantity_h1"],
            :price_h1=> item["price_h1"],
            :total_h1=> item["total_h1"],

            :activity_h2=> item["activity_h2"],
            :quantity_h2=> item["quantity_h2"],
            :price_h2=> item["price_h2"],
            :total_h2=> item["total_h2"],

            :activity_h3=> item["activity_h3"],
            :quantity_h3=> item["quantity_h3"],
            :price_h3=> item["price_h3"],
            :total_h3=> item["total_h3"],

            :activity_h4=> item["activity_h4"],
            :quantity_h4=> item["quantity_h4"],
            :price_h4=> item["price_h4"],
            :total_h4=> item["total_h4"],

            :activity_h5=> item["activity_h5"],
            :quantity_h5=> item["quantity_h5"],
            :price_h5=> item["price_h5"],
            :total_h5=> item["total_h5"],

            :activity_h6=> item["activity_h6"],
            :quantity_h6=> item["quantity_h6"],
            :price_h6=> item["price_h6"],
            :total_h6=> item["total_h6"],

            :activity_h7=> item["activity_h7"],
            :quantity_h7=> item["quantity_h7"],
            :price_h7=> item["price_h7"],
            :total_h7=> item["total_h7"],

            :activity_h8=> item["activity_h8"],
            :quantity_h8=> item["quantity_h8"],
            :price_h8=> item["price_h8"],
            :total_h8=> item["total_h8"],

            :activity_h9=> item["activity_h9"],
            :quantity_h9=> item["quantity_h9"],
            :price_h9=> item["price_h9"],
            :total_h9=> item["total_h9"],

            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          if direct_labor_item.save
            max_quantity = (check_product_bn.present? ? check_product_bn.outstanding_direct_labor : 0)
            (1..9).each do |c|
              if item["activity_h#{c}"].present?
                direct_labor_outstanding = DirectLaborOutstanding.find_by(:product_batch_number_id=> item["product_batch_number_id"], :direct_labor_price_detail_id=> item["activity_h#{c}"] )
                if direct_labor_outstanding.present?
                  if direct_labor_outstanding.outstanding == 0
                    direct_labor_item.update_columns("quantity_h#{c}".to_sym=> 0, "total_h#{c}".to_sym=> 0)
                  else
                    direct_labor_outstanding.update_columns({
                      :outstanding=> direct_labor_outstanding.outstanding.to_f-item["quantity_h#{c}"].to_f,
                      :quantity=> direct_labor_outstanding.quantity.to_f+item["quantity_h#{c}"].to_f, 
                      :price=> item["price_h#{c}"], :total=> direct_labor_outstanding.total.to_f+item["total_h#{c}"].to_f,
                      :remarks=> item["remarks"], :status=> 'active',
                      :updated_at=> DateTime.now(), :updated_by=> current_user.id
                    })
                  end
                else
                  DirectLaborOutstanding.create({
                    :direct_labor_id=> @direct_labor.id,
                    :product_batch_number_id=> item["product_batch_number_id"],
                    :product_id=> item["product_id"],
                    :direct_labor_price_detail_id=> item["activity_h#{c}"], :max_quantity=> max_quantity, :outstanding=> max_quantity.to_f-item["quantity_h#{c}"].to_f,
                    :quantity=> item["quantity_h#{c}"], :price=> item["price_h#{c}"], :total=> item["total_h#{c}"],
                    :remarks=> item["remarks"], :status=> 'active',
                    :created_at=> DateTime.now(), :created_by=> current_user.id
                  })
                end
              else
                puts "activity_h#{c} tidak ada!"
              end
            end
          end

        end if params[:new_record_item].present?
        
        format.html { redirect_to direct_labor_path(:id=> @direct_labor.id), notice: "#{@direct_labor.number} supplier was successfully created." }
        format.json { render :show, status: :created, location: @direct_labor }
      else
        format.html { render :new }
        format.json { render json: @direct_labor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /direct_labors/1
  # PATCH/PUT /direct_labors/1.json
  def update
    respond_to do |format|
      params[:direct_labor]["updated_by"] = current_user.id
      params[:direct_labor]["updated_at"] = DateTime.now()
      params[:direct_labor]["number"] = @direct_labor.number
      if @direct_labor.update(direct_labor_params)
        
        params[:new_record_item].each do |item|
          check_product_bn = ProductBatchNumber.find_by(:id=> item["product_batch_number_id"])

          direct_labor_item = DirectLaborItem.new({
            :direct_labor_id=> @direct_labor.id,
            :product_batch_number_id=> item["product_batch_number_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :direct_labor_price_id=> item["direct_labor_price_id"],
            :unit_price=> item["unit_price"],

            :activity_h1=> item["activity_h1"],
            :quantity_h1=> item["quantity_h1"],
            :price_h1=> item["price_h1"],
            :total_h1=> item["total_h1"],

            :activity_h2=> item["activity_h2"],
            :quantity_h2=> item["quantity_h2"],
            :price_h2=> item["price_h2"],
            :total_h2=> item["total_h2"],

            :activity_h3=> item["activity_h3"],
            :quantity_h3=> item["quantity_h3"],
            :price_h3=> item["price_h3"],
            :total_h3=> item["total_h3"],

            :activity_h4=> item["activity_h4"],
            :quantity_h4=> item["quantity_h4"],
            :price_h4=> item["price_h4"],
            :total_h4=> item["total_h4"],

            :activity_h5=> item["activity_h5"],
            :quantity_h5=> item["quantity_h5"],
            :price_h5=> item["price_h5"],
            :total_h5=> item["total_h5"],

            :activity_h6=> item["activity_h6"],
            :quantity_h6=> item["quantity_h6"],
            :price_h6=> item["price_h6"],
            :total_h6=> item["total_h6"],

            :activity_h7=> item["activity_h7"],
            :quantity_h7=> item["quantity_h7"],
            :price_h7=> item["price_h7"],
            :total_h7=> item["total_h7"],

            :activity_h8=> item["activity_h8"],
            :quantity_h8=> item["quantity_h8"],
            :price_h8=> item["price_h8"],
            :total_h8=> item["total_h8"],

            :activity_h9=> item["activity_h9"],
            :quantity_h9=> item["quantity_h9"],
            :price_h9=> item["price_h9"],
            :total_h9=> item["total_h9"],

            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          if direct_labor_item.save
            max_quantity = (check_product_bn.present? ? check_product_bn.outstanding_direct_labor : 0)
            (1..9).each do |c|
              if item["activity_h#{c}"].present?
                direct_labor_outstanding = DirectLaborOutstanding.find_by(:product_batch_number_id=> item["product_batch_number_id"], :direct_labor_price_detail_id=> item["activity_h#{c}"] )
                if direct_labor_outstanding.present?
                  direct_labor_outstanding.update_columns({
                    :outstanding=> direct_labor_outstanding.outstanding.to_f-item["quantity_h#{c}"].to_f,
                    :quantity=> direct_labor_outstanding.quantity.to_f+item["quantity_h#{c}"].to_f, 
                    :price=> item["price_h#{c}"], :total=> direct_labor_outstanding.total.to_f+item["total_h#{c}"].to_f,
                    :remarks=> item["remarks"], :status=> 'active',
                    :updated_at=> DateTime.now(), :updated_by=> current_user.id
                  })
                else
                  DirectLaborOutstanding.create({
                    :direct_labor_id=> @direct_labor.id,
                    :product_batch_number_id=> item["product_batch_number_id"],
                    :product_id=> item["product_id"],
                    :direct_labor_price_detail_id=> item["activity_h#{c}"], :max_quantity=> max_quantity, :outstanding=> max_quantity.to_f-item["quantity_h#{c}"].to_f,
                    :quantity=> item["quantity_h#{c}"], :price=> item["price_h#{c}"], :total=> item["total_h#{c}"],
                    :remarks=> item["remarks"], :status=> 'active',
                    :created_at=> DateTime.now(), :created_by=> current_user.id
                  })
                end
              else
                puts "activity_h#{c} tidak ada!"
              end
            end
          end

        end if params[:new_record_item].present?

        params[:record_item].each do |item|
          record_item = DirectLaborItem.find_by(:id=> item["id"])
          if record_item.present?
            old_quantity = record_item.quantity 
            
            check_product_bn = ProductBatchNumber.find_by(:id=> record_item.product_batch_number_id)
            case item["status"]
            when 'deleted'
              record_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })
              # check_product_bn.update_columns(:outstanding_direct_labor=> (old_quantity.to_f+check_product_bn.outstanding_direct_labor.to_f))
        
            else
              # master_price = DirectLaborPrice.find_by(:id=> item["direct_labor_price_id"])
              record_item.update_columns({
                :quantity=> item["quantity"].to_f,
                :unit_price=> item["unit_price"].to_f,

                :activity_h1=> item["activity_h1"].to_i,
                :quantity_h1=> item["quantity_h1"].to_f,
                :price_h1=> item["price_h1"].to_f,
                :total_h1=> item["total_h1"].to_f,

                :activity_h2=> item["activity_h2"].to_i,
                :quantity_h2=> item["quantity_h2"].to_f,
                :price_h2=> item["price_h2"].to_f,
                :total_h2=> item["total_h2"].to_f,

                :activity_h3=> item["activity_h3"].to_i,
                :quantity_h3=> item["quantity_h3"].to_f,
                :price_h3=> item["price_h3"].to_f,
                :total_h3=> item["total_h3"].to_f,

                :activity_h4=> item["activity_h4"].to_i,
                :quantity_h4=> item["quantity_h4"].to_f,
                :price_h4=> item["price_h4"].to_f,
                :total_h4=> item["total_h4"].to_f,

                :activity_h5=> item["activity_h5"].to_i,
                :quantity_h5=> item["quantity_h5"].to_f,
                :price_h5=> item["price_h5"].to_f,
                :total_h5=> item["total_h5"].to_f,

                :activity_h6=> item["activity_h6"].to_i,
                :quantity_h6=> item["quantity_h6"].to_f,
                :price_h6=> item["price_h6"].to_f,
                :total_h6=> item["total_h6"].to_f,

                :activity_h7=> item["activity_h7"].to_i,
                :quantity_h7=> item["quantity_h7"].to_f,
                :price_h7=> item["price_h7"].to_f,
                :total_h7=> item["total_h7"].to_f,

                :activity_h8=> item["activity_h8"].to_i,
                :quantity_h8=> item["quantity_h8"].to_f,
                :price_h8=> item["price_h8"].to_f,
                :total_h8=> item["total_h8"].to_f,

                :activity_h9=> item["activity_h9"].to_i,
                :quantity_h9=> item["quantity_h9"].to_f,
                :price_h9=> item["price_h9"].to_f,
                :total_h9=> item["total_h9"].to_f,
                :remarks=> item["remarks"],
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
              # check_product_bn.update_columns(:outstanding_direct_labor=> (old_quantity.to_f+check_product_bn.outstanding_direct_labor.to_f)- item["quantity"].to_f)
        
            end
          end
        end if params[:record_item].present?

        format.html { redirect_to @direct_labor, notice: 'Purchase order supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @direct_labor }
      else
        format.html { render :edit }
        format.json { render json: @direct_labor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /direct_labors/1
  # DELETE /direct_labors/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to direct_labors_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def approve
    case params[:status]
    when 'approve1'
      @direct_labor.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @direct_labor.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @direct_labor.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @direct_labor.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @direct_labor.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @direct_labor.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    respond_to do |format|
      format.html { redirect_to direct_labor_path(:id=> @direct_labor.id), notice: "DirectLabor was successfully #{@direct_labor.status}." }
      format.json { head :no_content }
    end
  end

  def print
    if @direct_labor.status == 'approved3'  
      sop_number      = ""
      form_number     = "F-03B-002-Rev 04"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. Provital Perdana"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @direct_labor
      items  = @direct_labor_items
      order_number = ""

      term_of_payment = (header.term_of_payment.present? ? header.term_of_payment.name : '')
      supplier_name  = (header.supplier.present? ? header.supplier.name : '')
      supplier_code  = (header.supplier.present? ? header.supplier.number : '')
      supplier_address  = (header.supplier.present? ? header.supplier.address : '')
      supplier_phone  = (header.supplier.present? ? header.supplier.telephone : '')
      supplier_email  = (header.supplier.present? ? header.supplier.email : '')

      sub_total = 0
      document_name = "P U R C H A S E  O R D E R"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 220
          tbl_width = [30, 324, 80, 80, 80]
          c = 1
          pdf.move_down 2
          items.each do |item|          
            if item.purchase_request_item.product.present?
              part = item.purchase_request_item.product
            elsif item.purchase_request_item.material.present?
              part = item.purchase_request_item.material
            elsif item.purchase_request_item.consumable.present?
              part = item.purchase_request_item.consumable
            elsif item.purchase_request_item.equipment.present?
              part = item.purchase_request_item.equipment
            elsif item.purchase_request_item.general.present?
              part = item.purchase_request_item.general
            end
            # (1..30).each do 
              y = pdf.y
              pdf.start_new_page if y < 430
              pdf.move_down 220 if y < 430
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center, :size=> 10}, 
                  {:content=>(part.name if part.present?)},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right, :size=> 11},
                  {:content=>number_with_precision(item.unit_price, precision: 0, delimiter: ".", separator: ","), :align=>:right, :size=> 11},
                  {:content=>number_with_precision((item.unit_price.to_f*item.quantity.to_f), precision: 0, delimiter: ".", separator: ","), :align=>:right, :size=> 11}
                ]], :column_widths => tbl_width, :cell_style => {:padding => [4, 5, 0, 4], :border_color=>"ffffff"})
              c +=1
              sub_total += (item.unit_price.to_f*item.quantity.to_f)
            # end
          end

          if header.tax.present? and header.tax.value.present?
            # ppn 10%
            ppn_total = (sub_total.to_f * header.tax.value)
            grand_total = sub_total.to_f + ppn_total.to_f
          else
            grand_total = sub_total
          end
   
          pdf.page_count.times do |i|
            # header begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1

                # pdf.bounding_box([0, 822], :width => 595) do
                #   pdf.text "________________________", :align => :center
                # end

                # pdf.bounding_box([1, 720], :width => 324, :height => 60) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end

                pdf.bounding_box([315, 800], :width => 145, :height => 50) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([460, 800], :width => 130, :height => 50) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end

                pdf.bounding_box([315, 730], :width => 275, :height => 70) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([0, 730], :width => 315, :height => 70) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([0, 730], :width => 30, :height => 70) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([460, 730], :width => 130, :height => 35) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([460, 695], :width => 130, :height => 35) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                # pdf.bounding_box([424, 750], :width => 70, :height => 30) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end
                # pdf.bounding_box([494, 750], :width => 100, :height => 30) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end
                # pdf.bounding_box([424, 720], :width => 70, :height => 30) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end
                # pdf.bounding_box([494, 720], :width => 100, :height => 30) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end
                # pdf.bounding_box([424, 690], :width => 70, :height => 30) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end
                # pdf.bounding_box([494, 690], :width => 100, :height => 30) do
                #   pdf.stroke_color '000000'
                #   pdf.stroke_bounds
                # end
              }

              pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.table([
                  [ 
                    {:content=>company_name.upcase, :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", "",
                    {:image => image_path, :image_width => 100}
                  ]],
                  :column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 4
                # pdf.table([
                #   [{:content=> "Plant", :size=> 10, :font_style => :bold}, {:content=> "Office", :size=> 10, :font_style => :bold}, "", "","", "", ""],
                #   [{:content=> "Jl. Kranji Blok F15 No. 1C,", :size=> 9}, {:content=> "Gading Bukit Indah Blok SB No. 23,", :size=> 9}, "", "","", "", "", "", ""],
                #   [{:content=> "Delta Silicon 2, Lippo Cikarang,", :size=> 9}, {:content=> "Kelapa Gading, Jakarta 14240", :size=> 9}, "", {:content=> "PRF No.", :size=> 9}, ":", {:content=> "#{header.purchase_request.present? ? header.purchase_request.number : nil}", :size=> 9}, {:content=> "Delivery", :size=> 9}, "", ""],
                #   [{:content=> "Bekasi 17530", :size=> 9}, {:content=> "", :size=> 9}, "", {:content=> "PO No.", :size=> 9}, ":", {:content=> "#{header.present? ? header.number : nil}", :size=> 9}, {:content=> "Date", :size=> 9}, ":", {:content=> "", :size=> 9}],
                #   [{:content=> "", :size=> 9}, {:content=> "", :size=> 9}, "", {:content=> "Date", :size=> 9}, ":", {:content=> "#{header.present? ? header.date : nil}", :size=> 9}, {:content=> "Day", :size=> 9}, ":", {:content=> "", :size=> 9}]                
                #   ],
                #   :column_widths => [148, 160, 8, 40, 8, 100, 40, 8, 80], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 
                
                pdf.table([
                  [{:content=> "Office & Plant :", :size=> 10, :font_style => :bold}, "", "", "","", "", "", "", ""],
                  [{:content=> "#{company_address1}", :size=> 9}, "", "", {:content=> "PRF No.", :size=> 9, :font_style => :bold}, ":", {:content=> "#{header.purchase_request.present? ? header.purchase_request.number : nil}", :size=> 9}, {:content=> "Delivery", :size=> 9, :font_style => :bold}, "", ""],
                  [{:content=> "#{company_address2}", :size=> 9}, "", "", {:content=> "PO No.", :size=> 9, :font_style => :bold}, ":", {:content=> "#{header.present? ? header.number : nil}", :size=> 9}, {:content=> "Date", :size=> 9}, ":", {:content=> "", :size=> 9}],
                  [{:content=> "", :size=> 9}, {:content=> "", :size=> 9}, "", {:content=> "Date", :size=> 9, :font_style => :bold}, ":", {:content=> "#{header.present? ? header.date : nil}", :size=> 9}, {:content=> "Day", :size=> 9}, ":", {:content=> "", :size=> 9}]
                  ],
                  :column_widths => [300, 8, 8, 40, 8, 100, 40, 8, 80], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 

                pdf.table([
                  [ 
                    {:content=>document_name, :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", "", ""
                  ]],
                  :column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 5

                pdf.table([
                  [{:content=>"TO", :font_style => :bold, :size=>9, :align=>:center}, "", {:content=>"Supplier", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_name}", :size=>9}, {:content=>"Ship to", :size=>9, :align=> :center, :font_style => :bold},":", {:content=>"#{company_name}", :size=>9}, "", {:content=>"Category :", :size=>9, :font_style => :bold}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Address", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_address.to_s[0..90]}", :size=>9, :height=> 22}, {:content=>"#{company_address1}", :size=>9, :colspan=> 3},  "", {:content=>"#{header.asset_kind.humanize}", :size=>9}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Phone", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_phone}", :size=>9}, {:content=>"", :size=>9},"", "", "", {:content=>"Cost Center :", :size=>9, :font_style => :bold}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Email", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_email}", :size=>9}, {:content=>"", :size=>9},"", "", "", {:content=>"", :size=>9}]
                  ], :column_widths => [30, 5, 45, 10, 225, 35, 10, 100, 5, 125], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                
                pdf.move_down 5
                pdf.table([
                  [ 
                    {:content=>"Please supply the following items / materials :", :size=>9}
                  ]],
                  :column_widths => [200], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 

                pdf.move_down 5          

                pdf.table([ ["No.","DESCRIPTIONS", "QTY", "UNIT PRICE", "TOTAL"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 620
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 200) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
              end
              den_row = 0
              # [80, 80, 80, 194, 80, 80].each do |i|
              #   # puts den_row
              #   den_row += i
              #   pdf.bounding_box([0, tbl_top_position-200], :width => den_row, :height => 20) do
              #     pdf.stroke_color '000000'
              #     pdf.stroke_bounds
              #   end
              # end

              pdf.bounding_box([0, tbl_top_position-200], :width => 80, :height => 60) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([10, tbl_top_position-205], :width => 80) do
                pdf.text "Prepared by,", :size=> 10
              end

              pdf.bounding_box([80, tbl_top_position-200], :width => 80, :height => 60) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([90, tbl_top_position-205], :width => 80) do
                pdf.text "Reviewed by,", :size=> 10
              end

              pdf.bounding_box([160, tbl_top_position-200], :width => 80, :height => 60) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([170, tbl_top_position-205], :width => 80) do
                pdf.text "Approved by,", :size=> 10
              end

              pdf.bounding_box([240, tbl_top_position-200], :width => 194, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([240, tbl_top_position-230], :width => 194, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([245, tbl_top_position-205], :width => 160) do
                pdf.text "Payment Terms : #{header.top_day} #{term_of_payment}", :size=> 10
              end

              pdf.bounding_box([245, tbl_top_position-235], :width => 80) do
                pdf.text "Remarks : #{header.remarks}", :size=> 10
              end

              pdf.bounding_box([434, tbl_top_position-200], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, tbl_top_position-205], :width => 80) do
                pdf.text "SUB TOTAL", :size=> 10
              end
              pdf.bounding_box([434, tbl_top_position-215], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, tbl_top_position-220], :width => 80) do
                pdf.text "PPN", :size=> 10
              end
              pdf.bounding_box([514, tbl_top_position-220], :width => 79) do
                pdf.text number_with_precision(ppn_total, precision: 0, delimiter: ".", separator: ","), :align=> :right , :size=> 10
              end

              pdf.bounding_box([514, tbl_top_position-200], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([514, tbl_top_position-205], :width => 79) do
                pdf.text number_with_precision(sub_total, precision: 0, delimiter: ".", separator: ","), :align=> :right, :size=> 10
              end
              pdf.bounding_box([514, tbl_top_position-215], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end

              pdf.bounding_box([434, tbl_top_position-230], :width => 80, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([434, tbl_top_position-230], :width => 160, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, tbl_top_position-235], :width => 80) do
                pdf.text "TOTAL", :size=> 10
              end
              pdf.bounding_box([514, tbl_top_position-235], :width => 79) do
                pdf.text number_with_precision(grand_total, precision: 0, delimiter: ".", separator: ","), :align=> :right , :size=> 10
              end

              pdf.bounding_box([1, tbl_top_position-265], :width => 549) do
                pdf.text "Note : PO must be attached at the time of billing. If there is a specification and/or quality change, the supplier must inform the Purchasing Section of 
                PT. Provital Perdana", :size=> 7, :style=> :bold
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                pdf.move_up 330
                
                pdf.table([
                  [
                    "White : Finance", "Red : Purchasing", {:content=> "Yellow : Warehouse", :align=> :right}, {:content=> "#{form_number}", :align=> :right}
                  ]
                  ], :column_widths => [147, 147, 147, 147], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  

              }

              pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @direct_labor, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @direct_labor }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
    puts "ini"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_direct_labor
      @direct_labor = DirectLabor.find_by(:id=> params[:id])
      if @direct_labor.present?
        @direct_labor_items = DirectLaborItem.where(:status=> 'active').includes(:direct_labor).where(:direct_labors => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("direct_labors.number desc")      
      else
        respond_to do |format|
          format.html { redirect_to direct_labors_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id).where("outstanding_direct_labor > 0")
      @direct_labor_workers = DirectLaborWorker.where(:status=> 'active')
      @direct_labor_prices = DirectLaborPrice.where(:status=> 'approved3')
      @direct_labor_price_details = DirectLaborPriceDetail.where(:status=> 'active')
      
    end

    def check_status     
      if @direct_labor.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @direct_labor.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @direct_labor, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @direct_labor }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def direct_labor_params
      params.require(:direct_labor).permit(:company_profile_id, :direct_labor_worker_id, :number, :date, :remarks, :purchase_request_id, :created_by, :created_at, :updated_at, :updated_by)
    end
end
