class GeneralReceivingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_general_receiving, only: [:show, :edit, :update, :destroy, :approve, :print]
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
  
  # GET /general_receivings
  # GET /general_receivings.json
  def index    
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    general_receivings = GeneralReceiving.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("number desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['PO Number','purchase_order_supplier_id'],['Supplier Name','supplier_id']]
      @option_filter_records = general_receivings 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'purchase_order_supplier_id'
          @option_filter_records = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').order("number asc")
        end
        
        general_receivings = general_receivings.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    @purchase_order_suppliers = @purchase_order_suppliers.where("outstanding > 0").where(:supplier_id=> params[:supplier_id]) if params[:supplier_id].present?
    @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> params[:purchase_order_supplier_id], :status=> 'active').where("outstanding > 0") if params[:purchase_order_supplier_id].present?
    
    case params[:view_kind]
    when 'item'
      general_receiving_items = GeneralReceivingItem.where(:general_receiving_id=> general_receivings, :status=> 'active')
      @general_receivings    = general_receiving_items 
    else
      @general_receivings    = general_receivings
    end
  end

  # GET /general_receivings/1
  # GET /general_receivings/1.json
  def show
  end

  # GET /general_receivings/new
  def new
    @general_receiving = GeneralReceiving.new
    @suppliers    = Supplier.where(:status=> 'active', :id=> @purchase_order_suppliers.where("outstanding > 0").group(:supplier_id).select(:supplier_id)).order("name asc")
    @purchase_order_suppliers = nil
  end

  # GET /general_receivings/1/edit
  def edit
  end

  # POST /general_receivings
  # POST /general_receivings.json
  def create    
    params[:general_receiving]["company_profile_id"] = current_user.company_profile_id
    params[:general_receiving]["created_by"] = current_user.id
    params[:general_receiving]["created_at"] = DateTime.now()
    params[:general_receiving]["number"] = document_number(controller_name, params[:general_receiving]["date"].to_date, nil, nil, nil)
    @general_receiving = GeneralReceiving.new(general_receiving_params)
    periode = params[:general_receiving]["date"]
    respond_to do |format|
      if @general_receiving.save
        params[:new_record_item].each do |item|
          general = General.find_by(:id=> item["general_id"])

          transfer_item = GeneralReceivingItem.create({
            :general_receiving_id=> @general_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :supplier_batch_number=> item["supplier_batch_number"],
            :general_id=> item["general_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          general_batch_number = GeneralBatchNumber.find_by(:general_receiving_item_id=> transfer_item.id, :general_id=> item["general_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
          if general_batch_number.blank?
            GeneralBatchNumber.create(
              :general_receiving_item_id=> transfer_item.id, 
              :general_id=> item["general_id"], 
              :number=>  gen_general_batch_number(item["general_id"], periode),
              :outstanding=> item["quantity"],
              :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
              )
          end
        end if params[:new_record_item].present?

        GeneralReceivingItem.where(:general_receiving_id=> @general_receiving.id, :status=> 'active').each do |item|
          general_batch_number = GeneralBatchNumber.find_by(:general_receiving_item_id=> item.id)
          item.update_columns(:general_batch_number_id=> general_batch_number.id) if general_batch_number.present?
          puts item.errors.full_messages
        end
        format.html { redirect_to general_receiving_path(:id=> @general_receiving.id), notice: "#{@general_receiving.number} was successfully created" }
        format.json { render :show, status: :created, location: @general_receiving }
      else
        format.html { render :new }
        format.json { render json: @general_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /general_receivings/1
  # PATCH/PUT /general_receivings/1.json
  def update
    respond_to do |format|
      params[:general_receiving]["updated_by"] = current_user.id
      params[:general_receiving]["updated_at"] = DateTime.now()
      params[:general_receiving]["date"]   = @general_receiving.date
      params[:general_receiving]["number"] = @general_receiving.number
      periode = params[:general_receiving]["date"]

      if @general_receiving.update(general_receiving_params)                
        params[:new_record_item].each do |item|
          general = General.find_by(:id=> item["general_id"])
          transfer_item = GeneralReceivingItem.create({
            :general_receiving_id=> @general_receiving.id,
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :supplier_batch_number=> item["supplier_batch_number"],
            :general_id=> item["general_id"],
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          general_batch_number = GeneralBatchNumber.find_by(:general_receiving_item_id=> transfer_item.id, :general_id=> item["general_id"], :periode_yyyy=> periode.to_date.strftime("%Y"))
          if general_batch_number.blank?
            GeneralBatchNumber.create(
              :general_receiving_item_id=> transfer_item.id, 
              :general_id=> item["general_id"], 
              :number=>  gen_general_batch_number(item["general_id"], periode),
              :outstanding=> item["quantity"],
              :periode_yyyy=> periode.to_date.strftime("%Y"), :status=> 'active'
              )
          end    
        end if params[:new_record_item].present?
        
        params[:general_receiving_item].each do |item|
          transfer_item = GeneralReceivingItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
            general_batch_number = GeneralBatchNumber.find_by(:general_receiving_item_id=> transfer_item.id, :status=> 'active')
            general_batch_number.update_columns(:status=> 'suspend') if general_batch_number.present?
          else
            transfer_item.update_columns({
              :supplier_batch_number=> item["supplier_batch_number"],
              :general_id=> item["general_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if transfer_item.present?
        end if params[:general_receiving_item].present?

        GeneralReceivingItem.where(:general_receiving_id=> @general_receiving.id, :status=> 'active').each do |item|
          general_batch_number = GeneralBatchNumber.find_by(:general_receiving_item_id=> item.id)
          item.update_columns(:general_batch_number_id=> general_batch_number.id) if general_batch_number.present?
          puts item.errors.full_messages
        end
        format.html { redirect_to general_receivings_path(), notice: 'SFO was successfully updated.' }
        format.json { render :show, status: :ok, location: @general_receiving }      
      else
        format.html { render :edit }
        format.json { render json: @general_receiving.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @general_receiving.date.strftime("%Y%m")
    prev_periode = (@general_receiving.date.to_date-1.month()).strftime("%Y%m")
    case params[:status]
    when 'approve1'
      @general_receiving.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @general_receiving.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @general_receiving.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @general_receiving.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      alert = nil
      @general_receiving_items.each do |item|
        po_item = item.purchase_order_supplier_item
        if (po_item.outstanding.to_f-item.quantity.to_f) < 0
          alert = "Tidak boleh dari outstanding PO!"
        end
      end
      if alert.blank?
        @general_receiving.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
        inventory(controller_name, @general_receiving.id, periode, prev_periode, 'approved')
        @general_receiving_items.each do |item|
          po_item = item.purchase_order_supplier_item
          po_item.update(:outstanding=> po_item.outstanding.to_f-item.quantity.to_f) if po_item.present?
        end

        sum_outstanding_pr = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> @general_receiving.purchase_order_supplier_id, :status=> 'active').sum(:outstanding)
        po_supplier = PurchaseOrderSupplier.find_by(:id=> @general_receiving.purchase_order_supplier_id)
        po_supplier.update(:outstanding=> sum_outstanding_pr) if po_supplier.present?
      end
    when 'cancel_approve3'
      # jika dokumen masuk gudang di cancel dan stok menjadi minus

        alert = nil
        @general_receiving_items.each do |item|
          stock = nil
          part_id = nil
          if item.general.present?
            stock = Inventory.find_by(:periode=> periode, :general_id=> item.general_id)
            part_id = item.general.part_id
          end
          if stock.present? and (stock.end_stock.to_f - item.quantity.to_f) < 0
            alert = "#{part_id} Tidak boleh lebih dari stock!"
          end
        end

      if alert.blank?
        @general_receiving.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
        inventory(controller_name, @general_receiving.id, periode, prev_periode, 'canceled')  
        @general_receiving_items.each do |item|
          po_item = item.purchase_order_supplier_item
          po_item.update(:outstanding=> po_item.outstanding.to_f+item.quantity.to_f) if po_item.present?
        end

        sum_outstanding_pr = PurchaseOrderSupplierItem.where(:purchase_order_supplier_id=> @general_receiving.purchase_order_supplier_id, :status=> 'active').sum(:outstanding)
        po_supplier = PurchaseOrderSupplier.find_by(:id=> @general_receiving.purchase_order_supplier_id)
        po_supplier.update(:outstanding=> sum_outstanding_pr) if po_supplier.present?  
      end

    end
    respond_to do |format|
      format.html { redirect_to general_receiving_path(:id=> @general_receiving.id), notice: "SFO was successfully #{@general_receiving.status}." }
      format.json { head :no_content }
    end
  end

  def print
    if @general_receiving.status == 'approved3'
      sop_number      = "SOP-03A-001"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT.PROVITAL PERDANA"
      company_address = "Plant Jalan Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang, Bekasi West Java 17530"

      header = @general_receiving
      items  = @general_receiving_items
      order_number = (header.purchase_order_supplier.present? ? header.purchase_order_supplier.number : "")

      document_name = "GENERAL RECEIPT NOTE"
      checkbox_icon = "app/assets/images/checkbox.png"  

      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 20,
            :bottom_margin => 20, 
            :left_margin=> 40, 
            :right_margin=> 20) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          items.group(:general_id).each do |item|
            summary_quantity = items.where(:general_id=> item.general_id).sum(:quantity)

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
                  {:content=>" Raw General", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Packaging General", :valign=>:center, :size=>10},
                  {:image => checkbox_icon, :image_width => 20},
                  {:content=>" Lab Testing General", :valign=>:center, :size=>10},
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
                    {:content=>"Doc. Number", :size=>10}, ":", {:content=>"#{header.number if header.present?}", :size=>10}
                  ],
                  [
                    {:content=>"Supplier Name", :size=>10}, ":", {:content=>"#{header.supplier.name if header.present?}", :size=>10}
                  ],
                  [
                    {:content=>"Product Name", :size=>10}, ":", {:content=>"#{item.general.name if item.general.present?}", :size=>10}
                  ],[
                    {:content=>"Batch Number", :size=>10}, ":", {:content=>"#{item.general_batch_number.number if item.general_batch_number.present?}", :size=>10}
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
              pdf.move_down 380
              pdf.text "F-03C-027-Rev 00", :align=> :right, :size=>10

              pdf.start_new_page
            # end
          end
          


          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{document_name.humanize}.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @general_receiving, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @general_receiving }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /general_receivings/1
  # DELETE /general_receivings/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to general_receivings_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_general_receiving
      @general_receiving = GeneralReceiving.find_by(:id=> params[:id])
      if @general_receiving.present?
        @general_receiving_items = GeneralReceivingItem.where(:status=> 'active').includes(:general_receiving).where(:general_receivings => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("general_receivings.number desc") 
      else                
        respond_to do |format|
          format.html { redirect_to general_receivings_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      # hanya menampilkan general berkategory Sterilization
      @suppliers    = Supplier.where(:status=> 'active').order("name asc")
      @generals    = General.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where(:kind => ['general', 'services'])
      

      @general_batch_number = GeneralBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
    end
    def check_status   
      if @general_receiving.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @general_receiving.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to general_receiving_path(:id=> @general_receiving.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @general_receiving }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def general_receiving_params
      params.require(:general_receiving).permit(:sj_number, :sj_date, :supplier_id, :purchase_order_supplier_id, :company_profile_id, :number, :date, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end

end
