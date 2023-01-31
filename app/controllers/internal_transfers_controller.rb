class InternalTransfersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_internal_transfer, only: [:show, :edit, :update, :destroy, :approve, :print]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end
  # GET /internal_transfers
  # GET /internal_transfers.json
  def index    
    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d"))
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : DateTime.now().at_end_of_month().strftime("%Y-%m-%d"))
    @internal_transfers = InternalTransfer.where(:company_profile_id=> current_user.company_profile_id, :transfer_from=> params[:q1], :transfer_to=> params[:q2]).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']]
      @option_filter_records = @internal_transfers 
      
      if params[:filter_column].present?
        @internal_transfers = @internal_transfers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:transfer_kind]
    when 'product'
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    when 'material'
      @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    end
  end

  # GET /internal_transfers/1
  # GET /internal_transfers/1.json
  def show
  end

  # GET /internal_transfers/new
  def new
    @internal_transfer = InternalTransfer.new
  end

  # GET /internal_transfers/1/edit
  def edit
  end

  # POST /internal_transfers
  # POST /internal_transfers.json
  def create
    params[:internal_transfer]["company_profile_id"] = current_user.company_profile_id
    params[:internal_transfer]["number"] = document_number(controller_name, DateTime.now(), params[:internal_transfer]["transfer_kind"], params[:internal_transfer]["transfer_from"], params[:internal_transfer]["transfer_to"])
    @internal_transfer = InternalTransfer.new(internal_transfer_params)

    respond_to do |format|
      if @internal_transfer.save
        params[:new_record_item].each do |item|
          transfer_item = InternalTransferItem.create({
            :internal_transfer_id=> @internal_transfer.id,
            :material_id=> item["material_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> @internal_transfer.created_by
          })
        end if params[:new_record_item].present?
        format.html { redirect_to internal_transfers_path(:q=> params[:q], :q1=> params[:q1], :q2=> params[:q2]), notice: 'Internal transfer was successfully created.' }
        format.json { render :show, status: :created, location: @internal_transfer }
      else
        format.html { render :new }
        format.json { render json: @internal_transfer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /internal_transfers/1
  # PATCH/PUT /internal_transfers/1.json
  def update
    respond_to do |format|
      if @internal_transfer.update(internal_transfer_params)                
        params[:new_record_item].each do |item|
          transfer_item = InternalTransferItem.create({
            :internal_transfer_id=> @internal_transfer.id,
            :material_id=> item["material_id"],
            :product_id=> item["product_id"],
            :quantity=> item["quantity"],
            :remarks=> item["remarks"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> @internal_transfer.created_by
          })
        end if params[:new_record_item].present?
        params[:internal_transfer_item].each do |item|
          transfer_item = InternalTransferItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            transfer_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> @internal_transfer.created_by
            })
          else
            transfer_item.update_columns({
              :material_id=> item["material_id"],
              :product_id=> item["product_id"],
              :quantity=> item["quantity"],
              :remarks=> item["remarks"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> @internal_transfer.created_by
            })
          end if transfer_item.present?
        end if params[:internal_transfer_item].present?

        format.html { redirect_to internal_transfers_path(:q=> params[:q], :q1=> params[:q1], :q2=> params[:q2]), notice: 'Internal transfer was successfully updated.' }
        format.json { render :show, status: :ok, location: @internal_transfer }      
      else
        format.html { render :edit }
        format.json { render json: @internal_transfer.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    periode = @internal_transfer.date.strftime("%Y%m")
    prev_periode = (@internal_transfer.date.to_date-1.month()).strftime("%Y%m")

    puts @internal_transfer.status

    if @internal_transfer.status == 'approved'

      # jika dokumen masuk gudang di cancel dan stok menjadi minus
      case @internal_transfer.transfer_to
      when 'Warehouse FG', 'Warehouse RM'
        alert = nil
        @internal_transfer_items.each do |item|
          stock = nil
          part_id = nil
          if item.product.present?
            stock = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :periode=> periode, :product_id=> item.product_id)
            part_id = item.product.part_id
          elsif item.material.present?
            stock = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :periode=> periode, :material_id=> item.material_id)
            part_id = item.material.part_id
          end
          if stock.present? and (stock.end_stock.to_f - item.quantity.to_f) < 0
            alert = "#{part_id} Tidak boleh lebih dari stock!"
          end
        end
      end
      if alert.blank?
        @internal_transfer.update_columns({:status=> 'canceled', :canceled_by=> current_user.id, :canceled_at=> DateTime.now()}) 
        inventory(controller_name, @internal_transfer.id, periode, prev_periode, 'canceled')    
      end
    else
      # jika dokumen keluar gudang lebih besar dari stok
      case @internal_transfer.transfer_from
      when 'Warehouse FG', 'Warehouse RM'
        alert = nil
        @internal_transfer_items.each do |item|
          stock = nil
          if item.product.present?
            stock = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :periode=> periode, :product_id=> item.product_id)
          elsif item.material.present?
            stock = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :periode=> periode, :material_id=> item.material_id)
          end
          if stock.present? and item.quantity.to_f > stock.end_stock.to_f
            alert = "Tidak boleh lebih dari stock!"
          end
        end
      end
      if alert.blank?
        @internal_transfer.update_columns({:status=> 'approved', :approved_by=> current_user.id, :approved_at=> DateTime.now()})  
        inventory(controller_name, @internal_transfer.id, periode, prev_periode, 'approved')  
      end
    end
    respond_to do |format|
      if alert.present?
        format.html { redirect_to internal_transfer_path(:id=> @internal_transfer.id, :q=> @internal_transfer.transfer_kind, :q1=> @internal_transfer.transfer_from, :q2=> @internal_transfer.transfer_to ), alert: "#{alert}" }
      else
        format.html { redirect_to internal_transfer_path(:id=> @internal_transfer.id, :q=> @internal_transfer.transfer_kind, :q1=> @internal_transfer.transfer_from, :q2=> @internal_transfer.transfer_to ), notice: "Internal transfer was successfully #{@internal_transfer.status}." }
      end
      format.json { head :no_content }
    end
  end

  def print
    company         = "PT. PRIBADI INTERNATIONAL"
    company_address = "Kawasan Delta Silicon 3 
    Jl.Pinang Blok F 17 No.3 
    Lippo Cikarang Bekasi"
    respond_to do |format|
      format.html do
        pdf = Prawn::Document.new(:page_size=> "A4", :top_margin => 25,:bottom_margin => 10, :left_margin=>10, :right_margin=>10) 
        pdf.font "Times-Roman"
        pdf.font_size 11
        record = @internal_transfer
        items = @internal_transfer_items
        tbl_width = [20, 160,90, 80, 80, 60, 80]
        pdf.table([
          [{:content=>company, :font_style=> :bold},"", "Print Date:  "],
          [company_address,"",DateTime.now.strftime("%d/%m/%Y") +", "+ DateTime.now.strftime("%H:%M:%S")]],
          :column_widths => [200, 200, 170], :cell_style => {:border_color => "ffffff", :padding=>1}) 
        pdf.table([
          ["",{:content=> "Internal Transfer", :align=> :center}, ""]],
          :column_widths => [200,170, 200], :cell_style => {:size=> 17, :border_color => "ffffff", :padding=>1})  
                
        pdf.table([["From",":","#{record.transfer_from}","","Tgl.Input",":", record.created_at.strftime("%d-%m-%Y")]], :column_widths=> [100,20,130, 100,100,20, 100], :cell_style => {:border_color => "000000", :padding => [5,1,1,1], :borders=>[:top], :border_width=> 1}, :header => true) 
        pdf.table([["No.Dokumen",":",record.number.to_s,"","Tgl.Produksi",":", record.date.strftime("%d-%m-%Y")]], :column_widths=> [100,20,130,100,100,20, 100], :cell_style => {:border_color => "000000", :padding => [1, 1, 5, 1], :border_width=> 0}, :header => true) 
        
        pdf.move_down 10
        pdf.table([ ["No.","Part Name","Part ID", "Part Model", "Quantity", "Unit", "Remarks"]], 
          :column_widths => tbl_width, :cell_style => {:align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :border_width=> 0})
        c = 1
        pdf.move_down 2
        items.each do |item|
          pdf.table( [ [{ :content=> c.to_s, :align=>:center}, 
              {:content=>(item.product.name if item.product.present?)},
              {:content=>(item.product.part_id if item.product.present?), :align=>:center},
              {:content=>(item.product.part_model if item.product.present?), :align=>:center},
              {:content=>item.quantity.to_s, :align=>:right},
              {:content=>(item.product.unit.name if item.product.present? and item.product.unit.present?), :align=>:center},\
              {:content=>item.remarks}
            ] ], 
              :column_widths => [20, 160,90, 80, 80, 60, 80], 
              :cell_style => {:padding => [4, 5, 0, 4],

              # ,:borders=>[:left, :right]
              :border_color=>"ffffff"
            })
          c +=1
        end  

        pdf.page_count.times do |i|
          den_row = 0
          tbl_top_position = 685
          
          tbl_width.each do |i|
            # puts den_row
            den_row += i
            pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 550) do
              pdf.stroke_color '000000'
              pdf.stroke_bounds
            end
          end

          pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 16) do
            pdf.stroke_color '000000'
            pdf.stroke_bounds
          end
        end
        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
      end
    end
  end
  # DELETE /internal_transfers/1
  # DELETE /internal_transfers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to internal_transfers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_internal_transfer
      @internal_transfer = InternalTransfer.find(params[:id])
      @internal_transfer_items = InternalTransferItem.where(:internal_transfer_id=> params[:id], :status=> 'active')
      @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
      @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def internal_transfer_params
      params[:internal_transfer]["created_by"] = current_user.id
      params[:internal_transfer]["created_at"] = DateTime.now()
      params.require(:internal_transfer).permit(:number, :company_profile_id, :date, :transfer_kind, :transfer_from, :transfer_to, :created_by, :created_at)
    end

end
