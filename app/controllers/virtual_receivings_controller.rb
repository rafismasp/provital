class VirtualReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_virtual_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
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
  
  # GET /virtual_receivings
  # GET /virtual_receivings.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    virtual_receivings = VirtualReceiving.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("number desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['PO Number','purchase_order_supplier_id'],['Supplier Name','supplier_id']]
      @option_filter_records = virtual_receivings 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'purchase_order_supplier_id'
          @option_filter_records = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').order("number asc")
        end
        
        virtual_receivings = virtual_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    @purchase_order_suppliers = @purchase_order_suppliers.where("outstanding > 0").where(:supplier_id=> params[:supplier_id]) if params[:supplier_id].present?
    @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> params[:purchase_order_supplier_id], :status=> 'active').where("outstanding > 0").includes(purchase_request_item: [:purchase_request, :product, :material, :general, :equipment, :consumable], pdm_item: [:pdm, :material]) if params[:purchase_order_supplier_id].present?

    case params[:view_kind]
    when 'item'
      virtual_receiving_items = VirtualReceivingItem.where(:virtual_receiving_id=> virtual_receivings, :status=> 'active')
      @virtual_receivings    = virtual_receiving_items 
    else
      @virtual_receivings    = virtual_receivings
    end
    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?
  end

  # GET /virtual_receivings/1
  # GET /virtual_receivings/1.json
  def show
  end

  # GET /virtual_receivings/new
  def new
    @virtual_receiving = VirtualReceiving.new
  end

  # GET /virtual_receivings/1/edit
  def edit
  end

  # POST /virtual_receivings
  # POST /virtual_receivings.json
  def create    
    params[:virtual_receiving]["company_profile_id"] = current_user.company_profile_id
    params[:virtual_receiving]["created_by"] = current_user.id
    params[:virtual_receiving]["created_at"] = DateTime.now()
    params[:virtual_receiving]["number"] = document_number(controller_name, params[:virtual_receiving]["date"].to_date, nil, nil, nil)
    @virtual_receiving = VirtualReceiving.new(virtual_receiving_params)
    periode = params[:virtual_receiving]["date"]
    respond_to do |format|
      if @virtual_receiving.save!
        params[:new_record_item].each do |item|
          transfer_item = VirtualReceivingItem.find_by(
            :virtual_receiving_id=> @virtual_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"]
          )

          if transfer_item.present?
            transfer_item.update_columns({
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            transfer_item = VirtualReceivingItem.new({
              :virtual_receiving_id=> @virtual_receiving.id,
              :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
              :product_id=> item["product_id"],
              :material_id=> item["material_id"],
              :general_id=> item["general_id"],
              :consumable_id=> item["consumable_id"],
              :equipment_id=> item["equipment_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            transfer_item.save!
          end
        end if params[:new_record_item].present?

        format.html { redirect_to virtual_receiving_path(:id=> @virtual_receiving.id), notice: "#{@virtual_receiving.number} was successfully created" }
        format.json { render :show, status: :created, location: @virtual_receiving }
      else
        format.html { render :new }
        format.json { render json: @virtual_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /virtual_receivings/1
  # PATCH/PUT /virtual_receivings/1.json
  def update
    respond_to do |format|
      params[:virtual_receiving]["updated_by"] = current_user.id
      params[:virtual_receiving]["updated_at"] = DateTime.now()
      params[:virtual_receiving]["date"]   = @virtual_receiving.date
      params[:virtual_receiving]["number"] = @virtual_receiving.number
      periode = params[:virtual_receiving]["date"]

      if @virtual_receiving.update(virtual_receiving_params)                
        params[:new_record_item].each do |item|
          transfer_item = VirtualReceivingItem.find_by(
            :virtual_receiving_id=> @virtual_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"]
          )

          if transfer_item.present?
            transfer_item.update_columns({
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            transfer_item = VirtualReceivingItem.new({
              :virtual_receiving_id=> @virtual_receiving.id,
              :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
              :product_id=> item["product_id"],
              :material_id=> item["material_id"],
              :general_id=> item["general_id"],
              :consumable_id=> item["consumable_id"],
              :equipment_id=> item["equipment_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            transfer_item.save!
          end
        end if params[:new_record_item].present?
        
        params[:virtual_receiving_item].each do |item|
          transfer_item = VirtualReceivingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            transfer_item.update_columns({
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:virtual_receiving_item].present?

        format.html { redirect_to virtual_receivings_path(), notice: 'SFO was successfully updated.' }
        format.json { render :show, status: :ok, location: @virtual_receiving }      
      else
        format.html { render :edit }
        format.json { render json: @virtual_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    notice_msg = "SFO was successfully #{params[:status]}."
    periode = @virtual_receiving.date.strftime("%Y%m")
    prev_periode = (@virtual_receiving.date.to_date-1.month()).strftime("%Y%m")
    case params[:status]
    when 'approve1'
      @virtual_receiving.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @virtual_receiving.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @virtual_receiving.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @virtual_receiving.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @virtual_receiving.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
      @virtual_receiving_items.each do |item|
        item.purchase_order_supplier_item.update_columns(:outstanding=> item.purchase_order_supplier_item.outstanding.to_f- item.quantity.to_f)
      end

      # 20210927 - Aden: request dari pak johnny otomatis bikin PRF yg baru
      if @virtual_receiving.prf_create_status.upcase == 'Y' 
        case @virtual_receiving.purchase_order_supplier.kind
        when 'product','material','consumable','equipment','general'
          if @virtual_receiving.purchase_request.present?
            prf_record = @virtual_receiving.purchase_request
          else
            prf_record = PurchaseRequest.new({
              :company_profile_id=> @virtual_receiving.company_profile_id,
              :request_kind=> @virtual_receiving.purchase_order_supplier.kind,
              :automatic_calculation=> 0,
              :department_id=> @virtual_receiving.department_id, #4, # Material Management
              :employee_section_id=> @virtual_receiving.employee_section_id, #10, # Purchasing
              :number=> document_number("purchase_requests", DateTime.now(), @virtual_receiving.employee_section_id, nil, nil),
              :date=> DateTime.now(),
              :remarks=> "Create from Virtual Receiving",
              :outstanding=> 0, 
              :status=> 'approved3',
              :created_at=> DateTime.now(), :created_by=> @virtual_receiving.approved3_by,
              :approved1_at=> DateTime.now(), :approved1_by=> @virtual_receiving.approved3_by,
              :approved2_at=> DateTime.now(), :approved2_by=> @virtual_receiving.approved3_by,
              :approved3_at=> DateTime.now(), :approved3_by=> @virtual_receiving.approved3_by
            })
            prf_record.save!
            @virtual_receiving.update(:purchase_request_id=> prf_record.id)
          end

          @virtual_receiving.virtual_receiving_items.each do |item|
            po_item = PurchaseOrderSupplierItem.find_by(:id=> item["purchase_order_supplier_item_id"])
            if po_item.present? and po_item.purchase_request_item.present?
              prf_item_old = po_item.purchase_request_item
              puts "create prf"
              # 2022-03-09: aden: tidak ada cek berdasarkan qty, karena dibeberapa kasus quantitynya sama
              # prf_item = PurchaseRequestItem.find_by(
              #     :purchase_request_id=> prf_record.id, 
              #     :product_id=> prf_item_old.product_id,
              #     :material_id=> prf_item_old.material_id,
              #     :consumable_id=> prf_item_old.consumable_id,
              #     :equipment_id=> prf_item_old.equipment_id,
              #     :general_id=> prf_item_old.general_id,
              #     :quantity=> prf_item_old.quantity
              #   )
              # if prf_item.present?
              #   puts "new prf item updated!"
              #   prf_item.update(:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> @virtual_receiving.approved3_by)
              # else
                puts "new prf item created!"
                prf_item = PurchaseRequestItem.new(
                  :expected_date=> prf_item_old.expected_date,
                  :purchase_request_id=> prf_record.id, 
                  :product_id=> prf_item_old.product_id,
                  :material_id=> prf_item_old.material_id,
                  :consumable_id=> prf_item_old.consumable_id,
                  :equipment_id=> prf_item_old.equipment_id,
                  :general_id=> prf_item_old.general_id,
                  :quantity=> item.quantity, :outstanding=> item.quantity,
                  :summary_production_order=> prf_item_old.summary_production_order,
                  :moq_quantity=> 0, :pdm_quantity=> 0,
                  :specification=> prf_item_old.specification,
                  :justification_of_purchase=> prf_item_old.justification_of_purchase,
                  :status=> prf_item_old.status,
                  :created_at=> DateTime.now(), :created_by=> @virtual_receiving.approved3_by
                  )
                prf_item.save!
              # end

              ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item_old.id, :status=> 'active').each do |spp_detail|
                # puts spp_detail.as_json
                new_spp_detail = ProductionOrderUsedPrf.find_by(:company_profile_id=> spp_detail.company_profile_id, 
                  :production_order_detail_material_id=> spp_detail.production_order_detail_material_id, 
                  :production_order_item_id=> spp_detail.production_order_item_id, 
                  :purchase_request_item_id=> prf_item.id )
                if new_spp_detail.present?
                  new_spp_detail.update(:status=> 'active', :updated_at=> DateTime.now(), :updated_by=> @virtual_receiving.approved3_by)
                else
                  new_spp_detail = ProductionOrderUsedPrf.new(
                    :company_profile_id=> spp_detail.company_profile_id, 
                    :production_order_detail_material_id=> spp_detail.production_order_detail_material_id, 
                    :production_order_item_id=> spp_detail.production_order_item_id, 
                    :purchase_request_item_id=> prf_item.id,
                    :prf_date=> spp_detail.prf_date,
                    :note=> "Create from Virutal Receiving",
                    :status=> 'active',
                    :created_at=> DateTime.now(), :created_by=> @virtual_receiving.approved3_by
                    )
                  new_spp_detail.save!
                end
              end
            end
            if po_item.present? and po_item.pdm_item.present?
              puts "create pdm"
            end
          end

          update_prf = PurchaseRequest.find_by(:id=> prf_record.id)
          update_prf.update(:outstanding=> update_prf.purchase_request_items.where(:status=> 'active').sum(:outstanding)) if update_prf.present?
        end
      else
        puts "selain PO 'product','material','consumable','equipment','general' tidak bisa dibuatin PRF otomatis dari Virtual Receiving!"
      end
      @virtual_receiving.purchase_order_supplier.update(:outstanding=> 0)
    when 'cancel_approve3'
      if @virtual_receiving.purchase_request.present?
        # jika mesti cancel approve 3 VRN karena udin salah pilih PO atau lain nya
        # vrn bisa di cancel asalkan PRF yg baru belum digunakan,
        # PRF yg baru di ubah statusnya deleted
        notice_msg = "Tidak bisa dicancel, karena sudah dibuat PRF!"
        # 20210612 barusan gw buat dadakan
        # @virtual_receiving.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
        # @virtual_receiving_items.each do |item|
        #   item.purchase_order_supplier_item.update_columns(:outstanding=> item.purchase_order_supplier_item.outstanding.to_f+ item.quantity.to_f)
        # end
        # @virtual_receiving.purchase_request.update({:status=> 'deleted'})
        # @virtual_receiving.purchase_request.purchase_request_items.each do |prf_item|
        #   if prf_item.status == 'active'
        #     ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item.id, :status=> 'active').each do |spp_detail|
        #       spp_detail.update(:status=> 'suspend')
        #     end
        #   end
        # end
      else
        @virtual_receiving.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
        @virtual_receiving_items.each do |item|
          item.purchase_order_supplier_item.update_columns(:outstanding=> item.purchase_order_supplier_item.outstanding.to_f+ item.quantity.to_f)
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to virtual_receiving_path(:id=> @virtual_receiving.id), notice: notice_msg }
      format.json { head :no_content }
    end
  end

  def print
    if @virtual_receiving.status == 'approved3'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT.PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @virtual_receiving
      items  = @virtual_receiving_items
      order_number = (header.purchase_order_supplier.present? ? header.purchase_order_supplier.number : "")

      document_name = "PRODUCT RECEIPT NOTE"
      checkbox_icon = "app/assets/images/checkbox.png"  

      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 20,
            :bottom_margin => 20, 
            :left_margin=> 40, 
            :right_margin=> 20) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          items.group(:virtual_id).each do |item|
            summary_quantity = items.where(:virtual_id=> item.virtual_id).sum(:quantity)

            # (1..3).each do 
              
              pdf.table([
                      [
                  {:image => image_path, :image_width => 90}, 
                  {:content=> document_name, :font_style => :bold, :align=>:center, :valign=>:center, :size=>15}
                ]],
                :column_widths => [150, 370], :cell_style => {:background_color => "f0f0f0", :border_color=> "f0f0f0", :padding=>1}) 
              
              pdf.move_down 10
              pdf.table([
                [
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Raw Virtual", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Packaging Virtual", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Lab Testing Virtual", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Other", :valign=>:center, :size=>10}
                ]],
                :column_widths => [25, 80, 25, 100, 25, 100, 25, 80], :cell_style => {:border_width => 0, :border_color => "ffffff", :padding=>1, :borders=>[:top]}) 
              
              pdf.bounding_box([410, 760], :width => 100) do
                pdf.text "______________"
              end

              pdf.move_down 30
              pdf.table([
                  [
                    {:content=>"Virtual Name", :size=>10}, ":", {:content=>"#{item.virtual.name if item.virtual.present?}", :size=>10}
                  ],[
                    {:content=>"Batch Number", :size=>10}, ":", {:content=>"", :size=>10}
                  ],[
                    {:content=>"PO # / AWB #", :size=>10}, ":", {:content=>"#{header.purchase_order_supplier.number if header.purchase_order_supplier.present?}", :size=>10}
                  ],[
                    {:content=>"DO #", :size=>10}, ":", {:content=>"#{header.sj_number}", :size=>10}
                  ],[
                    {:content=>"Received Date", :size=>10}, ":", {:content=>"#{header.sj_date.to_date.strftime("%d/%m/%Y") if header.sj_date.present?}", :size=>10}
                  ]
                ], :column_widths => [130, 10, 390], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1, :borders=>[:top]}) 
              
              pdf.move_down 30
              pdf.table([
                  [{:content=>"No.", :size=>10, :valign=> :center, :align=> :center}, {:content=>"virtual Identity", :size=>10, :valign=> :center, :align=> :center},  {:content=>"Result", :size=>10, :valign=> :center, :align=> :center},  {:content=>"Suitable/ Not Suitable", :size=>10, :valign=> :center, :align=> :center},  {:content=>"Record", :size=>10, :valign=> :center, :align=> :center}], 
                  [{:content=>"1", :size=>10, :align=> :center}, {:content=>"Virtual Quantity", :size=>10},  {:content=> "#{number_with_precision(summary_quantity.to_f, precision: 0, delimiter: ".", separator: ",")}", :size=>10, :align=> :right},  {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                  [{:content=>"2", :size=>10, :align=> :center}, {:content=>"Batch/ Serial Number Vendor", :size=>10},  {:content=>"#{item.supplier_batch_number}", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                  [{:content=>"3", :size=>10, :align=> :center}, {:content=>"Expired date (> 6 months)", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                  [{:content=>"4", :size=>10, :align=> :center}, {:content=>"Outside physical condition", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                ], :column_widths => [30, 150, 100, 80, 150], :cell_style => {:border_width => 0.1, :border_color => "000000", :padding=> [1, 5, 5, 5]}) 
              pdf.move_down 5
              pdf.text "* Inspection of items based on PO and content list/packing list", :size=>8

              pdf.move_down 60
              pdf.table([
                [
                  {:content=>"Done by", :size=>10, :width=> 80}, ":", "_______________", {:content=>"", :size=>10, :width=> 80}, {:content=>"Verified by", :size=>10, :width=> 80}, ":", "_______________"
                ],[
                  {:content=>"", :size=>10, :width=> 80}, "", 
                  {:content=>"(Sign & Date)", :size=>9, :align=> :center, :valign=> :top}, 
                  {:content=>"", :size=>10, :width=> 80}, 
                  {:content=>"", :size=>10, :width=> 80}, "", 
                  {:content=>"(Sign & Date)", :size=>9, :align=> :center, :valign=> :top}
                ]
              ], :cell_style => {:border_width => 0} )
              pdf.move_down 30
              pdf.table([
                  [
                    {:content=>"Testing", :size=>10, :valign=> :center, :align=> :center}, 
                    {:content=>"Done by", :size=>10, :valign=> :center, :align=> :center},  
                    {:content=>"Verified by", :size=>10, :valign=> :center, :align=> :center}
                  ]
                ], :column_widths => [310, 100, 100], :cell_style => {:border_width => 0.1, :border_color => "000000", :padding=> [1, 5, 5, 5]}) 
              
              pdf.table([
                  [{:content=>"1", :size=>10, :align=> :center}, {:content=>"Sampling", :size=>10},  
                    {:content=>"", :size=>10, :background_color=> "f0f0f0"},  
                    {:content=>"", :size=>10},  {:content=>"", :size=>10}],
                  [{:content=>"2", :size=>10, :align=> :center}, {:content=>"Quantity of Samples**", :size=>10},  
                    {:content=>"", :size=>10},  
                    {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                  [{:content=>"2", :size=>10, :align=> :center}, {:content=>"Result of inspection/sample verification**", :size=>10},  
                    {:content=>"", :size=>10},  
                    {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                  
                ], :column_widths => [30, 180, 100, 100, 100, 100], :cell_style => {:border_width => 0.1, :border_color => "000000", :padding=> [1, 5, 5, 5]}) 
              pdf.move_down 5
              pdf.text "** Attach on inspection Checklist Sheet & Inspection Result Sheet", :size=>8
              pdf.move_down 10
              pdf.text "Conclusion :", :size=>10

              pdf.move_down 10
              pdf.table([
                [
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Released", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Rejected", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Hold", :valign=>:center, :size=>10},
                ]],
                :column_widths => [25, 220, 25, 160, 25, 80], :cell_style => {:border_width => 0, :border_color => "ffffff", :padding=>1, :borders=>[:top]}) 
              pdf.move_down 10
              # remarks by QC
              pdf.text "remarks :", :size=>10
              pdf.move_down 15
              pdf.stroke_horizontal_rule
              pdf.move_down 15
              pdf.stroke_horizontal_rule
              pdf.move_down 15
              pdf.stroke_horizontal_rule

              pdf.move_down 30
              pdf.table([
                [
                  {:content=>" Prepared by", :align=>:center, :size=>10},
                  {:content=>" Approved by", :align=>:center, :size=>10}
                ], [
                  {:content=>"", :align=>:center, :height=> 40},
                  {:content=>"", :align=>:center, :height=> 40}
                ]],
                :column_widths => [260, 260], :cell_style => {:border_width => 0.1, :border_color => "000000", :padding=>2}) 
              

              pdf.move_down 30
              pdf.text "F-03C-002-Rev 02", :align=> :right, :size=>10

              pdf.start_new_page
            # end
          end
          


          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @virtual_receiving, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @virtual_receiving }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /virtual_receivings/1
  # DELETE /virtual_receivings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to virtual_receivings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_virtual_receiving
      @virtual_receiving = VirtualReceiving.find_by(:id=> params[:id])
      if @virtual_receiving.present?
        @virtual_receiving_items = VirtualReceivingItem.where(:status=> 'active').includes(:virtual_receiving, :product, :material, :general, :consumable, :equipment, :purchase_order_supplier_item).where(:virtual_receivings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("virtual_receivings.number desc") 
        
        my_array = {}
        @virtual_receiving_items.each do |item|
          if item.material.present?
            item_group(my_array, 'material', item)
          end
          if item.product.present?
            item_group(my_array, 'product', item)
          end
          if item.consumable.present?
            item_group(my_array, 'consumable', item)
          end
          if item.equipment.present?
            item_group(my_array, 'equipment', item)
          end
          if item.general.present?
            item_group(my_array, 'general', item)
          end
        end

        @item_group = my_array
      else                
        respond_to do |format|
          format.html { redirect_to virtual_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      # hanya menampilkan virtual berkategory Sterilization
      @purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
      @department = Department.all
      @sections = EmployeeSection.where(:status=> 'active')
    end
    def check_status   
      if @virtual_receiving.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @virtual_receiving.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to virtual_receiving_path(:id=> @virtual_receiving.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @virtual_receiving }
          end
        end
      end
    end

    def item_group(my_array, kind, item)
      id = item.try("#{kind}")&.id
      part_code = item.try("#{kind}")&.part_id
      part_name = item.try("#{kind}")&.name
      unit_name = item.try("#{kind}").try("unit")&.name
      puts unit_name

      my_array["#{kind}"] ||={}
      my_array["#{kind}"]["#{id}"] ||= {}
      if my_array["#{kind}"]["#{id}"].present?
        my_array["#{kind}"]["#{id}"][:po_item_id] = item.purchase_order_supplier_item_id
        my_array["#{kind}"]["#{id}"][:prf_item_id] = item.purchase_order_supplier_item.purchase_request_item_id
        my_array["#{kind}"]["#{id}"][:part_code] = part_code
        my_array["#{kind}"]["#{id}"][:part_name] = part_name
        my_array["#{kind}"]["#{id}"][:unit_name] = unit_name
        my_array["#{kind}"]["#{id}"][:quantity] += item.quantity.to_f
        my_array["#{kind}"]["#{id}"][:remarks] += item.remarks.present? ? ", #{item.remarks}" : ""
      else
        my_array["#{kind}"]["#{id}"][:po_item_id] = item.purchase_order_supplier_item_id
        my_array["#{kind}"]["#{id}"][:prf_item_id] = item.purchase_order_supplier_item.purchase_request_item_id
        my_array["#{kind}"]["#{id}"][:part_code] = part_code
        my_array["#{kind}"]["#{id}"][:part_name] = part_name
        my_array["#{kind}"]["#{id}"][:unit_name] = unit_name
        my_array["#{kind}"]["#{id}"][:quantity] = item.quantity.to_f
        my_array["#{kind}"]["#{id}"][:remarks] = item.remarks
      end
      puts "#{kind}_id: #{id}"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def virtual_receiving_params
      params.require(:virtual_receiving).permit(:department_id, :employee_section_id, :prf_create_status, :sj_number, :sj_date, :supplier_id, :purchase_order_supplier_id, :company_profile_id, :number, :date, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end

end
