class ProductReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
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
  
  # GET /product_receivings
  # GET /product_receivings.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    product_receivings = ProductReceiving.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier)
    .order("number desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['PO Number','purchase_order_supplier_id'],['Supplier Name','supplier_id']]
      @option_filter_records = product_receivings 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'purchase_order_supplier_id'
          @option_filter_records = PurchaseOrderSupplier.where(:id=> product_receivings.select(:purchase_order_supplier_id))
        end
        
        product_receivings = product_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    @purchase_order_suppliers = @purchase_order_suppliers.where("outstanding > 0").where(:supplier_id=> params[:supplier_id]) if params[:supplier_id].present?
    @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> params[:purchase_order_supplier_id], :status=> 'active').where("outstanding > 0") if params[:purchase_order_supplier_id].present?
    
    case params[:view_kind]
    when 'item'
      product_receiving_items = ProductReceivingItem.where(:status=> 'active')
      .includes(:product_receiving).where(:product_receivings => { :company_profile_id => current_user.company_profile_id }).where("product_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("product_receivings.number desc")
      .includes(:product_batch_number, product: [:unit])
      @product_receivings    = product_receiving_items 
    else
      @product_receivings    = product_receivings
    end
  end

  # GET /product_receivings/1
  # GET /product_receivings/1.json
  def show
  end

  # GET /product_receivings/new
  def new
    @product_receiving = ProductReceiving.new
    @suppliers    = Supplier.where(:status=> 'active', :id=> @purchase_order_suppliers.where("outstanding > 0").group(:supplier_id).select(:supplier_id)).order("name asc")
    @purchase_order_suppliers = nil
  end

  # GET /product_receivings/1/edit
  def edit
  end

  # POST /product_receivings
  # POST /product_receivings.json
  def create    
    params[:product_receiving]["company_profile_id"] = current_user.company_profile_id
    params[:product_receiving]["created_by"] = current_user.id
    params[:product_receiving]["created_at"] = DateTime.now()
    params[:product_receiving]["number"] = document_number(controller_name, params[:product_receiving]["date"].to_date, nil, nil, nil)
    @product_receiving = ProductReceiving.new(product_receiving_params)
    periode = params[:product_receiving]["date"]
    respond_to do |format|
      if @product_receiving.save
        params[:new_record_item].each do |item|
          product = Product.find_by(:id=> item["product_id"])

          transfer_item = ProductReceivingItem.create({
            :product_receiving_id=> @product_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :supplier_batch_number=> item["supplier_batch_number"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          product_batch_number = ProductBatchNumber.find_by(:product_receiving_item_id=> transfer_item.id, :product_id=> item["product_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
          if product_batch_number.blank?
            ProductBatchNumber.create(
              :product_receiving_item_id=> transfer_item.id, 
              :product_id=> item["product_id"], 
              :number=>  gen_product_batch_number(item["product_id"], periode),
              :outstanding=> item["quantity"],
              :outstanding_sterilization=> 0,
              :outstanding_sterilization_out=> 0,
              :outstanding_direct_labor=> 0,
              :outstanding_material_issue=> item["quantity"],
              :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
              )
          end 
        end if params[:new_record_item].present?

        ProductReceivingItem.where(:product_receiving_id=> @product_receiving.id, :status=> 'active').each do |item|
          product_batch_number = ProductBatchNumber.find_by(:product_receiving_item_id=> item.id)
          item.update_columns(:product_batch_number_id=> product_batch_number.id) if product_batch_number.present?
          puts item.errors.full_messages
        end
        format.html { redirect_to product_receiving_path(:id=> @product_receiving.id), notice: "#{@product_receiving.number} was successfully created" }
        format.json { render :show, status: :created, location: @product_receiving }
      else
        format.html { render :new }
        format.json { render json: @product_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_receivings/1
  # PATCH/PUT /product_receivings/1.json
  def update
    respond_to do |format|
      params[:product_receiving]["updated_by"] = current_user.id
      params[:product_receiving]["updated_at"] = DateTime.now()
      params[:product_receiving]["date"]   = @product_receiving.date
      params[:product_receiving]["number"] = @product_receiving.number
      periode = params[:product_receiving]["date"]

      if @product_receiving.update(product_receiving_params)                
        params[:new_record_item].each do |item|
          product = Product.find_by(:id=> item["product_id"])
          transfer_item = ProductReceivingItem.create({
            :product_receiving_id=> @product_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :supplier_batch_number=> item["supplier_batch_number"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          
          product_batch_number = ProductBatchNumber.find_by(:product_receiving_item_id=> transfer_item.id, :product_id=> item["product_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
          if product_batch_number.blank?
            ProductBatchNumber.create(
              :product_receiving_item_id=> transfer_item.id, 
              :product_id=> item["product_id"], 
              :number=>  gen_product_batch_number(item["product_id"], periode),
              :outstanding=> item["quantity"],
              :outstanding_sterilization=> 0,
              :outstanding_sterilization_out=> 0,
              :outstanding_direct_labor=> 0,
              :outstanding_material_issue=> item["quantity"],
              :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
              )
          end 
        end if params[:new_record_item].present?
        
        params[:product_receiving_item].each do |item|
          transfer_item = ProductReceivingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
            product_batch_number = ProductBatchNumber.find_by(:product_receiving_item_id=> transfer_item.id, :status=> 'active')
            product_batch_number.update_columns(:status=> 'suspend') if product_batch_number.present?
          else
            transfer_item.update_columns({
              :supplier_batch_number=> item["supplier_batch_number"],
              :product_id=> item["product_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:product_receiving_item].present?

        ProductReceivingItem.where(:product_receiving_id=> @product_receiving.id, :status=> 'active').each do |item|
          product_batch_number = ProductBatchNumber.find_by(:product_receiving_item_id=> item.id)
          item.update_columns(:product_batch_number_id=> product_batch_number.id) if product_batch_number.present?
          puts item.errors.full_messages
        end
        format.html { redirect_to product_receivings_path(), notice: 'SFO was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_receiving }      
      else
        format.html { render :edit }
        format.json { render json: @product_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @product_receiving.date.strftime("%Y%m")
    prev_periode = (@product_receiving.date.to_date-1.month()).strftime("%Y%m")
    case params[:status]
    when 'approve1'
      @product_receiving.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @product_receiving.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @product_receiving.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @product_receiving.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      alert = nil
      @product_receiving_items.each do |item|
        po_item = item.purchase_order_supplier_item
        if (po_item.outstanding.to_f-item.quantity.to_f) < 0
          alert = "Tidak boleh dari outstanding PO!"
        end
      end
      if alert.blank?
        @product_receiving.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
        inventory(controller_name, @product_receiving.id, periode, prev_periode, 'approved')
       
        @product_receiving_items.each do |item|
          po_item = item.purchase_order_supplier_item
          po_item.update(:outstanding=> po_item.outstanding.to_f-item.quantity.to_f) if po_item.present?
        end

        sum_outstanding_pr = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> @product_receiving.purchase_order_supplier_id, :status=> 'active').sum(:outstanding)
        po_supplier = PurchaseOrderSupplier.find_by(:id=> @product_receiving.purchase_order_supplier_id)
        po_supplier.update(:outstanding=> sum_outstanding_pr) if po_supplier.present?
      end
    when 'cancel_approve3'
      # jika dokumen masuk gudang di cancel dan stok menjadi minus

        alert = nil
        @product_receiving_items.each do |item|
          stock = nil
          part_id = nil
          if item.product.present?
            stock = Inventory.find_by(:periode=> periode, :product_id=> item.product_id)
            part_id = item.product.part_id
          end
          if stock.present? and (stock.end_stock.to_f - item.quantity.to_f) < 0
            alert = "#{part_id} Tidak boleh lebih dari stock!"
          end
        end

      if alert.blank?
        @product_receiving.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
        inventory(controller_name, @product_receiving.id, periode, prev_periode, 'canceled')  
        @product_receiving_items.each do |item|
          po_item = item.purchase_order_supplier_item
          po_item.update(:outstanding=> po_item.outstanding.to_f+item.quantity.to_f) if po_item.present?
        end

        sum_outstanding_pr = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> @product_receiving.purchase_order_supplier_id, :status=> 'active').sum(:outstanding)
        po_supplier = PurchaseOrderSupplier.find_by(:id=> @product_receiving.purchase_order_supplier_id)
        po_supplier.update(:outstanding=> sum_outstanding_pr) if po_supplier.present?    
      end

    end
    respond_to do |format|
      if alert.present?
        format.html { redirect_to product_receiving_path(:id=> @product_receiving.id), alert: "#{alert}" }
      else
        format.html { redirect_to product_receiving_path(:id=> @product_receiving.id), notice: "SFO was successfully #{@product_receiving.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    if @product_receiving.status == 'approved3'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT.PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @product_receiving
      items  = @product_receiving_items
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

          items.group(:product_id).each do |item|
            summary_quantity = items.where(:product_id=> item.product_id).sum(:quantity)

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
                  {:content=>" Raw Product", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Packaging Product", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Lab Testing Product", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Other", :valign=>:center, :size=>10}
                ]],
                :column_widths => [25, 80, 25, 100, 25, 100, 25, 80], :cell_style => {:border_width => 0, :border_color => "ffffff", :padding=>1, :borders=>[:top]}) 
              
              pdf.bounding_box([410, 760], :width => 100) do
                pdf.text "______________"
              end

              pdf.move_down 20
              pdf.table([
                  [
                    {:content=>"Doc. Number", :size=>10}, ":", {:content=>"#{header.number if header.present?}", :size=>10}
                  ],
                  [
                    {:content=>"Supplier Name", :size=>10}, ":", {:content=>"#{header.supplier.name if header.present?}", :size=>10}
                  ],
                  [
                    {:content=>"Product Name", :size=>10}, ":", {:content=>"#{item.product.name if item.product.present?}", :size=>10}
                  ],[
                    {:content=>"Batch Number", :size=>10}, ":", {:content=>"#{item.product_batch_number.number if item.product_batch_number.present?}", :size=>10}
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
                  [{:content=>"No.", :size=>10, :valign=> :center, :align=> :center}, {:content=>"Material Identity", :size=>10, :valign=> :center, :align=> :center},  {:content=>"Result", :size=>10, :valign=> :center, :align=> :center},  {:content=>"Suitable/ Not Suitable", :size=>10, :valign=> :center, :align=> :center},  {:content=>"Record", :size=>10, :valign=> :center, :align=> :center}], 
                  [{:content=>"1", :size=>10, :align=> :center}, {:content=>"Product Quantity", :size=>10},  {:content=> "#{number_with_precision(summary_quantity.to_f, precision: 0, delimiter: ".", separator: ",")}", :size=>10, :align=> :right},  {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
                  [{:content=>"2", :size=>10, :align=> :center}, {:content=>"Outside physical condition", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10},  {:content=>"", :size=>10}], 
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
              pdf.text "F-03C-024-Rev 00", :align=> :right, :size=>10

              pdf.start_new_page
            # end
          end
          


          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @product_receiving, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @product_receiving }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /product_receivings/1
  # DELETE /product_receivings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to product_receivings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_receiving
      @product_receiving = ProductReceiving.find_by(:id=> params[:id])
      if @product_receiving.present?
        @product_receiving_items = ProductReceivingItem.where(:status=> 'active').includes(:product_receiving).where(:product_receivings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("product_receivings.number desc") 
      else                
        respond_to do |format|
          format.html { redirect_to product_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      # hanya menampilkan product berkategory Sterilization
      @suppliers    = Supplier.where(:status=> 'active').order("name asc")
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').only_sterilization
      @purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where(:kind => ['general', 'services'])
      

      @product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
    end
    def check_status   
      if @product_receiving.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @product_receiving.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to product_receiving_path(:id=> @product_receiving.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @product_receiving }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_receiving_params
      params.require(:product_receiving).permit(:sj_number, :sj_date, :supplier_id, :purchase_order_supplier_id, :company_profile_id, :number, :date, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end

end
