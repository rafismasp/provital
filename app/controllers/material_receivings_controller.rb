class MaterialReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_material_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /material_receivings
  # GET /material_receivings.json
  def index    
    material_receivings = MaterialReceiving.where(:company_profile_id=> current_user.company_profile_id).where("material_receivings.date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier)
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['PO Number','purchase_order_supplier_id'],['Supplier Name','supplier_id']]
      @option_filter_records = material_receivings 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'purchase_order_supplier_id'
          @option_filter_records = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').order("number asc")
        end

        material_receivings = material_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    
    if params[:tbl_kind] == 'items' or params[:view_kind] == 'item'
      material_receiving_items = MaterialReceivingItem.where(:status=> 'active')
      .includes(:material_receiving).where(:material_receivings => { :company_profile_id => current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end] }).order("material_receivings.number desc")
      .includes(:material, :material_batch_number)

      @material_batch_number   = MaterialBatchNumber.where(:status=> 'active', :material_receiving_item_id=> material_receiving_items)
      material_receivings    = material_receiving_items 
    else
      material_receivings    = material_receivings.order("number desc")
    end

    @purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id).where(:status=> 'approved3', :kind=> 'material').where("outstanding > 0").where(:supplier_id=> params[:supplier_id]) if params[:supplier_id].present?
    @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> params[:purchase_order_supplier_id], :status=> 'active').where("outstanding > 0") if params[:purchase_order_supplier_id].present?
    
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @material_receivings = pagy(material_receivings, page: params[:page], items: pagy_items)
  end

  # GET /material_receivings/1
  # GET /material_receivings/1.json
  def show
  end

  # GET /material_receivings/new
  def new
    @material_receiving = MaterialReceiving.new
    purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id).where(:status=> 'approved3', :kind=> 'material').where("outstanding > 0").group(:supplier_id)
    @suppliers = @suppliers.where(:id=> purchase_order_suppliers.select(:supplier_id))
  end

  # GET /material_receivings/1/edit
  def edit
  end

  # POST /material_receivings
  # POST /material_receivings.json
  def create
    params[:material_receiving]["created_by"] = current_user.id
    params[:material_receiving]["img_created_signature"] = current_user.signature
    params[:material_receiving]["created_at"] = DateTime.now()
    params[:material_receiving]["number"] = document_number(controller_name, params[:material_receiving]["date"].to_date, nil, nil, nil)
    periode = params[:material_receiving]["date"]
    @material_receiving = MaterialReceiving.new(material_receiving_params)

    respond_to do |format|
      if @material_receiving.save
        params[:new_record_item].each do |item|
          transfer_item = MaterialReceivingItem.create({
            :material_receiving_id=> @material_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :material_id=> item["material_id"],
            :supplier_batch_number=> item["supplier_batch_number"],
            :supplier_expired_date=> item["supplier_expired_date"],
            :packaging_condition=> item["packaging_condition"],
            :quantity=> item["quantity"], :material_check_sheet_outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          # 20210223: samsudin request 1 Batch Number 1 Material yg sama dalam GRN yg sama
          material_batch_number = MaterialBatchNumber.find_by(
            :material_receiving_id=> transfer_item.material_receiving_id, 
            :material_id=> item["material_id"], 
            :periode_yyyy=> periode.to_date.strftime("%Y")
            )
          if material_batch_number.blank?
            material_batch_number = MaterialBatchNumber.create(
              :material_receiving_id=> transfer_item.material_receiving_id, 
              :material_receiving_item_id=> transfer_item.id, 
              :material_id=> item["material_id"], 
              :number=>  gen_material_batch_number(item["material_id"], periode),
              :periode_yyyy=> periode.to_date.strftime("%Y"),
              :periode_mm=> periode.to_date.strftime("%m"), :status=> 'active'
              )
          end 
          puts material_batch_number.errors.full_messages
        end if params[:new_record_item].present?

        MaterialReceivingItem.where(:material_receiving_id=> @material_receiving.id, :status=> 'active').each do |item|
          material_batch_number = MaterialBatchNumber.find_by(:material_receiving_id=> item.material_receiving_id, :material_id=> item.material_id, :status=> 'active')
          item.update_columns(:material_batch_number_id=> material_batch_number.id) if material_batch_number.present?
          puts item.errors.full_messages
        end

        format.html { redirect_to material_receiving_path(:id=> @material_receiving.id), notice: "#{@material_receiving.number} was successfully created" }
        format.json { render :show, status: :created, location: @material_receiving }
      else
        format.html { render :new }
        format.json { render json: @material_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /material_receivings/1
  # PATCH/PUT /material_receivings/1.json
  def update
    params[:material_receiving]["updated_by"] = current_user.id
    params[:material_receiving]["updated_at"] = DateTime.now()
    periode = params[:material_receiving]["date"]
    respond_to do |format|
      if @material_receiving.update(material_receiving_params) 
        MaterialReceivingItem.where(:material_receiving_id=> @material_receiving.id, :status=> 'active').each do |item|
          item.update({
            :status=> 'deleted'
          })
        end               
        params[:new_record_item].each do |item|
          transfer_item = MaterialReceivingItem.create({
            :material_receiving_id=> @material_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :material_id=> item["material_id"],
            :supplier_batch_number=> item["supplier_batch_number"],
            :supplier_expired_date=> item["supplier_expired_date"],
            :packaging_condition=> item["packaging_condition"],
            :quantity=> item["quantity"], :material_check_sheet_outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })

          material_batch_number = MaterialBatchNumber.find_by(
            :material_receiving_id=> transfer_item.material_receiving_id,
            :material_id=> item["material_id"], 
            :periode_yyyy=> periode.to_date.strftime("%Y"))
          if material_batch_number.blank?
            material_batch_number = MaterialBatchNumber.create(
              :material_receiving_id=> transfer_item.material_receiving_id,  
              :material_receiving_item_id=> transfer_item.id, 
              :material_id=> item["material_id"], 
              :number=>  gen_material_batch_number(item["material_id"], periode),
              :periode_yyyy=> periode.to_date.strftime("%Y"),
              :periode_mm=> periode.to_date.strftime("%m"), :status=> 'active'
              )
          end  
          puts material_batch_number.errors.full_messages
        end if params[:new_record_item].present?

        params[:material_receiving_item].each do |item|
          transfer_item = MaterialReceivingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
            # material_batch_number = MaterialBatchNumber.find_by(:material_receiving_id=> transfer_item.material_receiving_id, :status=> 'active')
            # material_batch_number.update_columns(:status=> 'suspend') if material_batch_number.present?
          else
            transfer_item.update_columns({
              :supplier_batch_number=> item["supplier_batch_number"],
              :supplier_expired_date=> item["supplier_expired_date"],
              :packaging_condition=> item["packaging_condition"],
              :material_id=> item["material_id"],
              :quantity=> item["quantity"], :material_check_sheet_outstanding=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:material_receiving_item].present?

        MaterialReceivingItem.where(:material_receiving_id=> @material_receiving.id, :status=> 'active').each do |item|
          material_batch_number = MaterialBatchNumber.find_by(:material_receiving_id=> item.material_receiving_id, :material_id=> item.material_id, :status=> 'active')
          item.update_columns(:material_batch_number_id=> material_batch_number.id) if material_batch_number.present?
          puts item.errors.full_messages
        end

        format.html { redirect_to material_receivings_path(:q=> params[:q], :q1=> params[:q1], :q2=> params[:q2]), notice: 'Good Receipt Note was successfully updated.' }
        format.json { render :show, status: :ok, location: @material_receiving }      
      else
        format.html { render :edit }
        format.json { render json: @material_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @material_receiving.date.strftime("%Y%m")
    prev_periode = (@material_receiving.date.to_date-1.month()).strftime("%Y%m")

    case params[:status]
    when 'approve1'
      @material_receiving.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now(), :img_approved1_signature=> current_user.signature}) 
    when 'cancel_approve1'
      @material_receiving.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now(), :img_approved1_signature=> nil}) 
    when 'approve2'
      @material_receiving.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now(), :img_approved2_signature=> current_user.signature}) 
      
      require 'telegram/bot' 
      token = '1488140962:AAEw-NwTv3i0Pe9NKNn3caKu1TDOPcrxL-I'
      url_link = "https://erp.tri-saudara.com/material_receivings/#{@material_receiving.id}"
      msg = "#{@material_receiving.number} approved2 \n"
      chat_id_collects = [303683673, 1698497988]
        
      Telegram::Bot::Client.run(token) do |bot|
        chat_id_collects.each do |chat_id|
          bot.api.send_message(chat_id: chat_id, text: "#{msg} #{url_link}".html_safe, token: token)
        end
      end if chat_id_collects.present?
    when 'cancel_approve2'
      @material_receiving.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now(), :img_approved2_signature=> nil})
    when 'approve3'
      alert = nil
      @material_receiving_items.each do |item|
        po_item = item.purchase_order_supplier_item
        if (po_item.outstanding.to_f-item.quantity.to_f) < 0
          alert = "Tidak boleh dari outstanding PO!"
        end
      end
      if alert.blank?
        @material_receiving.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature})  
        inventory(controller_name, @material_receiving.id, periode, prev_periode, 'approved')  
         
        @material_receiving_items.each do |item|
          po_item = item.purchase_order_supplier_item
          po_item.update(:outstanding=> po_item.outstanding.to_f-item.quantity.to_f) if po_item.present?
        end

        sum_outstanding_pr = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> @material_receiving.purchase_order_supplier_id, :status=> 'active').sum(:outstanding)
        po_supplier = PurchaseOrderSupplier.find_by(:id=> @material_receiving.purchase_order_supplier_id)
        po_supplier.update(:outstanding=> sum_outstanding_pr) if po_supplier.present?
      end
    when 'cancel_approve3'
      # jika dokumen masuk gudang di cancel dan stok menjadi minus

        alert = nil
        @material_receiving_items.each do |item|
          stock = nil
          part_id = nil
          if item.material.present?
            stock = Inventory.find_by(:periode=> periode, :material_id=> item.material_id)
            part_id = item.material.part_id
          end
          if stock.present? and (stock.end_stock.to_f - item.quantity.to_f) < 0
            alert = "#{part_id} Tidak boleh lebih dari stock!"
          end
        end

      if alert.blank?
        @material_receiving.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil}) 
        inventory(controller_name, @material_receiving.id, periode, prev_periode, 'canceled')  
        @material_receiving_items.each do |item|
          po_item = item.purchase_order_supplier_item
          po_item.update(:outstanding=> po_item.outstanding.to_f+item.quantity.to_f) if po_item.present?
        end

        sum_outstanding_pr = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> @material_receiving.purchase_order_supplier_id, :status=> 'active').sum(:outstanding)
        po_supplier = PurchaseOrderSupplier.find_by(:id=> @material_receiving.purchase_order_supplier_id)
        po_supplier.update(:outstanding=> sum_outstanding_pr) if po_supplier.present?  
      end
    end

    respond_to do |format|
      if alert.present?
        format.html { redirect_to material_receiving_path(:id=> @material_receiving.id), alert: "#{alert}" }
      else
        format.html { redirect_to material_receiving_path(:id=> @material_receiving.id), notice: "Good Receipt Note was successfully #{@material_receiving.status}." }
      end
      format.json { head :no_content }
    end
  end

  
  def print
    case @material_receiving.status 
    when 'approved1','canceled2','approved2','canceled3','approved3'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT.PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @material_receiving
      items  = @material_receiving_items
      order_number = (header.purchase_order_supplier.present? ? header.purchase_order_supplier.number : "")

      document_name = "GOOD RECEIPT NOTE"
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

      # if user_approved1_by.present? and header.img_approved1_signature.present?
      #   img_approved1_by = "public/uploads/signature/#{user_approved1_by.id}/#{header.img_approved1_signature}"
      #   if FileTest.exist?("#{img_approved1_by}")
      #     puts "File Exist"
      #     puts img_approved1_by
      #   else
      #     puts "File not found: #{img_approved1_by}"
      #     img_approved1_by = nil
      #   end
      # else
      #   img_approved1_by = nil
      # end

      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A5", :page_layout => :landscape,
            :top_margin => 20,
            :bottom_margin => 20, 
            :left_margin=> 40, 
            :right_margin=> 20) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          items.group(:material_id).each do |item|
            summary_quantity = items.where(:material_id=> item.material_id).sum(:quantity)

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
                    {:content=>"Doc. Number", :size=>10}, ":", {:content=>"#{header.number if header.present?}", :size=>10}
                  ],
                  [
                    {:content=>"Supplier Name", :size=>10}, ":", {:content=>"#{header.supplier.name if header.present?}", :size=>10}
                  ],
                  [
                    {:content=>"Material Name", :size=>10}, ":", {:content=>"#{item.material.name if item.material.present?}", :size=>10}
                  ],[
                    {:content=>"Batch Number", :size=>10}, ":", {:content=>"#{item.material_batch_number.number if item.material_batch_number.present?}", :size=>10}
                  ],[
                    {:content=>"PO # / AWB #", :size=>10}, ":", {:content=>"#{header.purchase_order_supplier.number if header.purchase_order_supplier.present?}", :size=>10}
                  ],[
                    {:content=>"DO #", :size=>10}, ":", {:content=>"#{header.sj_number}", :size=>10}
                  ],[
                    {:content=>"Received Date", :size=>10}, ":", {:content=>"#{header.sj_date.to_date.strftime("%d/%m/%Y") if header.sj_date.present?}", :size=>10}
                  ]
                ], :column_widths => [130, 10, 390], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1, :borders=>[:top]}) 
              
              pdf.move_down 10
              pdf.table([
                  [
                    {:content=>"No.", :size=>10, :valign=> :center, :align=> :center}, 
                    {:content=>"Material Identity", :size=>10, :valign=> :center, :align=> :center},  
                    {:content=>"Result", :size=>10, :valign=> :center, :align=> :center}, 
                    {:content=>"remarks", :size=>10, :valign=> :center, :align=> :center}
                  ], 
                  [
                    {:content=>"1", :size=>10, :align=> :center}, 
                    {:content=>"Quantity", :size=>10},  
                    {:content=> "#{number_with_precision(summary_quantity.to_f, precision: 0, delimiter: ".", separator: ",")} #{item.material.unit_name if item.material.present?}", :size=>10, :align=> :right},  
                    {:content=>"#{item.remarks}", :size=>10, :rowspan=> 4}
                  ], 
                  [
                    {:content=>"2", :size=>10, :align=> :center},
                    {:content=>"Batch/ Serial Number Vendor", :size=>10},  
                    {:content=>"#{item.supplier_batch_number.present? ? item.supplier_batch_number : "Tidak Ada"}", :size=>10}
                  ], 
                  [{:content=>"3", :size=>10, :align=> :center}, {:content=>"Expired date (> 6 months)", :size=>10},  {:content=>"#{item.supplier_expired_date.present? ? item.supplier_expired_date : "Tidak Ada"}", :size=>10}], 
                  [{:content=>"4", :size=>10, :align=> :center}, {:content=>"Packaging Condition", :size=>10},  {:content=>"#{item.packaging_condition.present? ? item.packaging_condition : "Tidak Ada"}", :size=>10}], 
                ], :column_widths => [30, 200, 150, 150], :cell_style => {:border_width => 0.1, :border_color => "000000", :padding=> [1, 5, 5, 5]}) 
              pdf.move_down 5
              pdf.text "* Inspection of items based on PO and content list/packing list", :size=>8

              pdf.move_down 50
              pdf.table([
                [
                  {:content=>"Done by", :size=>10, :width=> 80}, ":", "_______________", {:content=>"", :size=>10, :width=> 80}, {:content=>"Verified by", :size=>10, :width=> 80}, ":", "_______________"
                ],[
                  {:content=>"", :size=>10, :width=> 80}, "", 
                  {:content=>"#{name_prepared_by.present? ? "#{name_prepared_by}" : ('<i>Sign Name</i>')}", :size=>9, :align=> :center, :valign=> :top}, 
                  {:content=>"", :size=>10, :width=> 80}, 
                  {:content=>"", :size=>10, :width=> 80}, "", 
                  {:content=>"#{header.img_approved1_signature.present? ? name_approved1_by : '(<i>Sign Name</i>'}", :size=>9, :align=> :center, :valign=> :top}
                ],[
                  {:content=>"", :size=>10, :width=> 80, :padding=> 0}, "", 
                  {:content=>"#{name_prepared_by.present? ? header.created_at.strftime("%Y-%m-%d %H:%M:%S") : nil}", :size=>9, :align=> :center, :valign=> :top, :padding=> 0}, 
                  {:content=>"", :size=>10, :width=> 80, :padding=> 0}, 
                  {:content=>"", :size=>10, :width=> 80, :padding=> 0}, "", 
                  {:content=>"#{header.img_approved1_signature.present? ? header.approved1_at.strftime("%Y-%m-%d %H:%M:%S") : nil}", :size=>9, :align=> :center, :valign=> :top, :padding=> 0}
                ]
              ], :cell_style => {:border_width => 0, :inline_format=>true} )
              
              pdf.image img_prepared_by, :at => [80, 125], :width =>120 if img_prepared_by.present?
              pdf.image img_approved1_by, :at => [360, 125], :width =>120 if img_approved1_by.present?
              # footer
              pdf.page_count.times do |i|
                pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => 100) {
                  pdf.go_to_page i+1
                  # pdf.text "F-01B-093-Rev 00", :align => :right, :size => 8 
                  # 2023-01-19 samsudin request untuk ganti menjadi F03C-002-Rev 03
                  pdf.text "F03C-002-Rev 03", :align => :right, :size => 8 
                }
              end

            # end
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
        format.html { redirect_to @material_receiving, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @material_receiving }
      end
    end
  end
  # DELETE /material_receivings/1
  # DELETE /material_receivings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to material_receivings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_receiving
      @material_receiving = MaterialReceiving.find_by(:id=> params[:id])
      if @material_receiving.present?
        @purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id).where(:status=> 'approved3', :kind=> 'material').where("outstanding > 0").where(:supplier_id=> @material_receiving.supplier_id)
        @material_receiving_items = MaterialReceivingItem.where(:status=> 'active').includes(:material_receiving).where(:material_receivings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("material_receivings.number desc")
      else
        respond_to do |format|
          format.html { redirect_to material_receivings_url, alert: 'record not found!' }
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
      @material_batch_number = MaterialBatchNumber.where(:status=> 'active', :material_receiving_item_id=> @material_receiving_items)
      
    end
    def check_status     
      noitce_msg = nil 
      if @material_receiving.invoice_supplier.present?
        noitce_msg = "Cannot be edited because a Invoice: #{@material_receiving.invoice_supplier.number} has been created"
      else
        if @material_receiving.status == 'approved3' 
          if params[:status] == "cancel_approve3"
          else 
            noitce_msg = 'Cannot be edited because it has been approved'
          end
        end
      end
      if noitce_msg.present?
        puts "-------------------------------"
        puts  @material_receiving.status
        puts "-------------------------------"
        respond_to do |format|
          format.html { redirect_to @material_receiving, alert: noitce_msg }
          format.json { render :show, status: :created, location: @material_receiving }
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def material_receiving_params
      params.require(:material_receiving).permit(:sj_number, :sj_date, :number, :date, :purchase_order_supplier_id, :supplier_id, :remarks, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end

end
