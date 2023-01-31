class InvoiceSuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice_supplier, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /invoice_suppliers
  # GET /invoice_suppliers.json
  def index
    invoice_suppliers = InvoiceSupplier.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).where(:status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'])
    
    # filter select - begin
      @option_filters = [['Inv.Number','number'],['Inv.Status','status'], ['Supplier Name', 'supplier_id'], ['PO Supplier', 'purchase_order_supplier_id'] ] 
      @option_filter_records = @delivery_orders
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'supplier_id'
          @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
        when 'purchase_order_supplier_id'
          @option_filter_records = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').order("number asc")
        end

        invoice_suppliers = invoice_suppliers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @invoice_suppliers = invoice_suppliers.order("number desc")

    case params[:select_tax_id].to_i
    when 2, 5
      select_tax_id = [2, 5]
    else
      select_tax_id = params[:select_tax_id]
    end
    
    @material_receivings = @material_receivings.where(:supplier_id=> params[:supplier_id], :invoice_supplier_id=> nil)
    .includes(:purchase_order_supplier)
    .where(:purchase_order_suppliers => {:tax_id => select_tax_id })
    .order("material_receivings.number asc")
    @material_receiving_items = MaterialReceivingItem.where(:material_receiving_id=> params[:material_receiving_id], :status=> 'active')
    @material_batch_number = @material_batch_number.where(:material_receiving_item_id=> @material_receiving_items)

    @product_receivings =  @product_receivings.where(:supplier_id=> params[:supplier_id], :invoice_supplier_id=> nil)
    .includes(:purchase_order_supplier)
    .where(:purchase_order_suppliers => {:tax_id => select_tax_id })
    .order("product_receivings.number asc")
    @product_receiving_items = ProductReceivingItem.where(:product_receiving_id=> params[:product_receiving_id], :status=> 'active').includes(:product_batch_number, product: [:unit], product_receiving: [:purchase_order_supplier], purchase_order_supplier_item: [:purchase_order_supplier])
    @product_batch_number = @product_batch_number.where(:product_receiving_item_id=> @product_receiving_items)

    @general_receivings =  @general_receivings.where(:supplier_id=> params[:supplier_id], :invoice_supplier_id=> nil)
    .includes(:purchase_order_supplier)
    .where(:purchase_order_suppliers => {:tax_id => select_tax_id })
    .order("general_receivings.number asc")
    @general_receiving_items = GeneralReceivingItem.where(:general_receiving_id=> params[:general_receiving_id], :status=> 'active').includes(:general_batch_number, general: [:unit], general_receiving: [:purchase_order_supplier], purchase_order_supplier_item: [:purchase_order_supplier])
    @general_batch_number = @general_batch_number.where(:general_receiving_item_id=> @general_receiving_items)

    @consumable_receivings =  @consumable_receivings.where(:supplier_id=> params[:supplier_id], :invoice_supplier_id=> nil)
    .includes(:purchase_order_supplier)
    .where(:purchase_order_suppliers => {:tax_id => select_tax_id })
    .order("consumable_receivings.number asc")
    @consumable_receiving_items = ConsumableReceivingItem.where(:consumable_receiving_id=> params[:consumable_receiving_id], :status=> 'active').includes(:consumable_batch_number, consumable: [:unit], consumable_receiving: [:purchase_order_supplier], purchase_order_supplier_item: [:purchase_order_supplier])
    @consumable_batch_number = @consumable_batch_number.where(:consumable_receiving_item_id=> @consumable_receiving_items)

    @equipment_receivings =  @equipment_receivings.where(:supplier_id=> params[:supplier_id], :invoice_supplier_id=> nil)
    .includes(:purchase_order_supplier)
    .where(:purchase_order_suppliers => {:tax_id => select_tax_id })
    .order("equipment_receivings.number asc")
    @equipment_receiving_items = EquipmentReceivingItem.where(:equipment_receiving_id=> params[:equipment_receiving_id], :status=> 'active').includes(:equipment_batch_number, equipment: [:unit], equipment_receiving: [:purchase_order_supplier], purchase_order_supplier_item: [:purchase_order_supplier])
    @equipment_batch_number = @equipment_batch_number.where(:equipment_receiving_item_id=> @equipment_receiving_items)

    @tax_rates = @tax_rates.where(:currency_id=> params[:select_currency_id])
  end

  # GET /invoice_suppliers/1
  # GET /invoice_suppliers/1.json
  def show
    @record_files = InvoiceSupplierFile.where(:invoice_supplier_id=>params[:id],:status=>"active")
  end

  # GET /invoice_suppliers/new
  def new
    @invoice_supplier = InvoiceSupplier.new
  end

  # GET /invoice_suppliers/1/edit
  def edit
    @material_receivings = @material_receivings.where(:supplier_id=> @invoice_supplier.supplier_id, :invoice_supplier_id=> [@invoice_supplier.id, nil])
    .includes(purchase_order_supplier: [:tax])
    .where(:purchase_order_suppliers => {:tax_id => @invoice_supplier.tax_id })
    .order("material_receivings.number asc")

    @product_receivings = @product_receivings.where(:supplier_id=> @invoice_supplier.supplier_id, :invoice_supplier_id=> [@invoice_supplier.id, nil])
    .includes(purchase_order_supplier: [:tax])
    .where(:purchase_order_suppliers => {:tax_id => @invoice_supplier.tax_id })
    .order("product_receivings.number asc")

    @general_receivings = @general_receivings.where(:supplier_id=> @invoice_supplier.supplier_id, :invoice_supplier_id=> [@invoice_supplier.id, nil])
    .includes(purchase_order_supplier: [:tax])
    .where(:purchase_order_suppliers => {:tax_id => @invoice_supplier.tax_id })
    .order("general_receivings.number asc")

    @consumable_receivings = @consumable_receivings.where(:supplier_id=> @invoice_supplier.supplier_id, :invoice_supplier_id=> [@invoice_supplier.id, nil])
    .includes(purchase_order_supplier: [:tax])
    .where(:purchase_order_suppliers => {:tax_id => @invoice_supplier.tax_id })
    .order("consumable_receivings.number asc")

    @equipment_receivings = @equipment_receivings.where(:supplier_id=> @invoice_supplier.supplier_id, :invoice_supplier_id=> [@invoice_supplier.id, nil])
    .includes(purchase_order_supplier: [:tax])
    .where(:purchase_order_suppliers => {:tax_id => @invoice_supplier.tax_id })
    .order("equipment_receivings.number asc")
    
    @record_files = InvoiceSupplierFile.where(:invoice_supplier_id=>params[:id],:status=>"active")
  end

  # POST /invoice_suppliers
  # POST /invoice_suppliers.json
  def create
    params[:invoice_supplier]["company_profile_id"] = current_user.company_profile_id
    params[:invoice_supplier]["created_by"] = current_user.id
    params[:invoice_supplier]["created_at"] = DateTime.now()
    params[:invoice_supplier]["status"] = "new"
    @invoice_supplier = InvoiceSupplier.new(invoice_supplier_params)

    respond_to do |format|
      if @invoice_supplier.save
        params[:new_record_item].each do |item|
          invoice_item = InvoiceSupplierItem.create({
            :invoice_supplier_id=> @invoice_supplier.id,
            :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
            :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
            :material_receiving_id=> item["material_receiving_id"],
            :material_receiving_item_id=> item["material_receiving_item_id"],
            :material_id=> item["material_id"],
            :product_receiving_id=> item["product_receiving_id"],
            :product_receiving_item_id=> item["product_receiving_item_id"],
            :product_id=> item["product_id"],
            :general_receiving_id=> item["general_receiving_id"],
            :general_receiving_item_id=> item["general_receiving_item_id"],
            :general_id=> item["general_id"],
            :consumable_receiving_id=> item["consumable_receiving_id"],
            :consumable_receiving_item_id=> item["consumable_receiving_item_id"],
            :consumable_id=> item["consumable_id"],
            :equipment_receiving_id=> item["equipment_receiving_id"],
            :equipment_receiving_item_id=> item["equipment_receiving_item_id"],
            :equipment_id=> item["equipment_id"],
            :quantity=> item["quantity"], 
            :unit_price=> item["unit_price"],
            :total=> item["total"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          if item["material_receiving_id"].present?
            material_receiving = MaterialReceiving.find_by(:id=> item["material_receiving_id"], :invoice_supplier_id=> nil)
            if material_receiving.present?
              material_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
            end
          end
          if item["product_receiving_id"].present?
            product_receiving = ProductReceiving.find_by(:id=> item["product_receiving_id"], :invoice_supplier_id=> nil)
            if product_receiving.present?
              product_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
            end
          end
          if item["general_receiving_id"].present?
            general_receiving = GeneralReceiving.find_by(:id=> item["general_receiving_id"], :invoice_supplier_id=> nil)
            if general_receiving.present?
              general_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
            end
          end
          if item["consumable_receiving_id"].present?
            consumable_receiving = ConsumableReceiving.find_by(:id=> item["consumable_receiving_id"], :invoice_supplier_id=> nil)
            if consumable_receiving.present?
              consumable_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
            end
          end
          if item["equipment_receiving_id"].present?
            equipment_receiving = EquipmentReceiving.find_by(:id=> item["equipment_receiving_id"], :invoice_supplier_id=> nil)
            if equipment_receiving.present?
              equipment_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
            end
          end
        end if params[:new_record_item].present?


        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            if many_files[:attachment].present?
              hash = Digest::MD5.hexdigest(content)
              fid = InvoiceSupplierFile.where(:invoice_supplier_id=>@invoice_supplier.id)
              pf = fid.find_by(:file_hash=>hash)
              if pf.blank?
                filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
                ext=File.extname(filename_original)
                filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
                dir = "public/uploads/invoice_supplier/"
                FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
                path = File.join(dir, "#{hash}#{ext}")
                tmp_path_filename=File.join('/tmp', filename)
                File.open(path, 'wb') do |file|
                  file.write(content)
                  InvoiceSupplierFile.create({
                    :invoice_supplier_id=> @invoice_supplier.id,
                    :filename_original=>filename_original,
                    :file_hash=> hash ,
                    :filename=> filename,
                    :path=> path,
                    :ext=> ext,
                    :created_at=> DateTime.now,
                    :created_by=> session[:id]
                  })             
                end
              end
            end
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end
        format.html { redirect_to @invoice_supplier, notice: 'Invoice supplier was successfully created.' }
        format.json { render :show, status: :created, location: @invoice_supplier }
      else
        format.html { render :new }
        format.json { render json: @invoice_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invoice_suppliers/1
  # PATCH/PUT /invoice_suppliers/1.json
  def update
    respond_to do |format|
      params[:invoice_supplier]["updated_by"] = current_user.id
      params[:invoice_supplier]["updated_at"] = DateTime.now()
      if @invoice_supplier.update(invoice_supplier_params)
        InvoiceSupplierItem.where(:invoice_supplier_id=> @invoice_supplier.id, :status=> 'active').each do |invoice_item|
          invoice_item.update_columns(:status=> 'deleted')
          invoice_item.material_receiving.update_columns(:invoice_supplier_id=> nil) if invoice_item.material_receiving.present?
          invoice_item.product_receiving.update_columns(:invoice_supplier_id=> nil) if invoice_item.product_receiving.present?
          invoice_item.general_receiving.update_columns(:invoice_supplier_id=> nil) if invoice_item.general_receiving.present?
          invoice_item.consumable_receiving.update_columns(:invoice_supplier_id=> nil) if invoice_item.consumable_receiving.present?
          invoice_item.equipment_receiving.update_columns(:invoice_supplier_id=> nil) if invoice_item.equipment_receiving.present?
        end
        
        params[:new_record_item].each do |item|
          case item["status"] 
          when 'active'
            if item["product_receiving_id"].present?
              invoice_item = InvoiceSupplierItem.find_by({
                :invoice_supplier_id=> @invoice_supplier.id,
                :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
                :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
                :product_receiving_id=> item["product_receiving_id"],
                :product_receiving_item_id=> item["product_receiving_item_id"]
              })
            elsif item["material_receiving_id"].present?
              invoice_item = InvoiceSupplierItem.find_by({
                :invoice_supplier_id=> @invoice_supplier.id,
                :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
                :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
                :material_receiving_id=> item["material_receiving_id"],
                :material_receiving_item_id=> item["material_receiving_item_id"]
              })
            elsif item["general_receiving_id"].present?
              invoice_item = InvoiceSupplierItem.find_by({
                :invoice_supplier_id=> @invoice_supplier.id,
                :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
                :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
                :general_receiving_id=> item["general_receiving_id"],
                :general_receiving_item_id=> item["general_receiving_item_id"]
              })
            elsif item["consumable_receiving_id"].present?
              invoice_item = InvoiceSupplierItem.find_by({
                :invoice_supplier_id=> @invoice_supplier.id,
                :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
                :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
                :consumable_receiving_id=> item["consumable_receiving_id"],
                :consumable_receiving_item_id=> item["consumable_receiving_item_id"]
              })
            elsif item["equipment_receiving_id"].present?
              invoice_item = InvoiceSupplierItem.find_by({
                :invoice_supplier_id=> @invoice_supplier.id,
                :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
                :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
                :equipment_receiving_id=> item["equipment_receiving_id"],
                :equipment_receiving_item_id=> item["equipment_receiving_item_id"]
              })
            end

            if invoice_item.present?
              invoice_item.update_columns({
                :product_id=> item["product_id"],
                :material_id=> item["material_id"],
                :general_id=> item["general_id"],
                :consumable_id=> item["consumable_id"],
                :equipment_id=> item["equipment_id"],
                :quantity=> item["quantity"], 
                :unit_price=> item["unit_price"],
                :total=> item["total"],
                :status=> 'active',
                :updated_at=> DateTime.now(), :updated_by=> current_user.id
              })
            else
              invoice_item = InvoiceSupplierItem.create({
                :invoice_supplier_id=> @invoice_supplier.id,
                :purchase_order_supplier_id=> item["purchase_order_supplier_id"],
                :purchase_order_supplier_item_id=> item["purchase_order_supplier_item_id"],
                :material_receiving_id=> item["material_receiving_id"],
                :material_receiving_item_id=> item["material_receiving_item_id"],
                :material_id=> item["material_id"],
                :product_receiving_id=> item["product_receiving_id"],
                :product_receiving_item_id=> item["product_receiving_item_id"],
                :product_id=> item["product_id"],
                :general_receiving_id=> item["general_receiving_id"],
                :general_receiving_item_id=> item["general_receiving_item_id"],
                :general_id=> item["general_id"],
                :consumable_receiving_id=> item["consumable_receiving_id"],
                :consumable_receiving_item_id=> item["consumable_receiving_item_id"],
                :consumable_id=> item["consumable_id"],
                :equipment_receiving_id=> item["equipment_receiving_id"],
                :equipment_receiving_item_id=> item["equipment_receiving_item_id"],
                :equipment_id=> item["equipment_id"],
                :quantity=> item["quantity"], 
                :unit_price=> item["unit_price"],
                :total=> item["total"],
                :status=> 'active',
                :created_at=> DateTime.now(), :created_by=> current_user.id
              })
            end

            if item["material_receiving_id"].present?
              material_receiving = MaterialReceiving.find_by(:id=> item["material_receiving_id"], :invoice_supplier_id=> nil)
              if material_receiving.present?
                material_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
              end
            end
            if item["product_receiving_id"].present?
              product_receiving = ProductReceiving.find_by(:id=> item["product_receiving_id"], :invoice_supplier_id=> nil)
              if product_receiving.present?
                product_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
              end
            end
            if item["general_receiving_id"].present?
              general_receiving = GeneralReceiving.find_by(:id=> item["general_receiving_id"], :invoice_supplier_id=> nil)
              if general_receiving.present?
                general_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
              end
            end
            if item["consumable_receiving_id"].present?
              consumable_receiving = ConsumableReceiving.find_by(:id=> item["consumable_receiving_id"], :invoice_supplier_id=> nil)
              if consumable_receiving.present?
                consumable_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
              end
            end
            if item["equipment_receiving_id"].present?
              equipment_receiving = EquipmentReceiving.find_by(:id=> item["equipment_receiving_id"], :invoice_supplier_id=> nil)
              if equipment_receiving.present?
                equipment_receiving.update_columns(:invoice_supplier_id=> @invoice_supplier.id)
              end
            end
          end
        end if params[:new_record_item].present?
        subtotal = 0
        InvoiceSupplierItem.where(:invoice_supplier_id=> @invoice_supplier.id, :status=> 'active').each do |invoice_item|
          subtotal+= invoice_item.total
        end

        if @invoice_supplier.tax.present? and @invoice_supplier.tax.value.present?
          # ppn 10%
          ppntotal = (subtotal.to_f * @invoice_supplier.tax.value)
        else
          ppntotal = 0
        end
        
        # grand total = ((subtotal + ppn total)- pph total) - DP 
        grandtotal = (((subtotal+ppntotal) - @invoice_supplier.pphtotal)- @invoice_supplier.dptotal)
        @invoice_supplier.update_columns({
          :subtotal=> subtotal,
          :ppntotal=> ppntotal, 
          :grandtotal=> grandtotal
        })

        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = InvoiceSupplierFile.where(:invoice_supplier_id=>@invoice_supplier.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/invoice_supplier/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                InvoiceSupplierFile.create({
                  :invoice_supplier_id=> @invoice_supplier.id,
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })             
              end
            end 
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end

        params["record_file"].each do |item|
          file = InvoiceSupplierFile.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            file.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          end
        end if params["record_file"].present?
        format.html { redirect_to @invoice_supplier, notice: 'Invoice supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @invoice_supplier }
      else
        format.html { render :edit }
        format.json { render json: @invoice_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  def print
  end

  def approve
    notice_msg = "Invoice Supplier was successfully #{params[:status]}."
    notice_kind = "notice"
    case params[:status]
    when 'approve1'
      @invoice_supplier.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @invoice_supplier.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @invoice_supplier.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @invoice_supplier.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @invoice_supplier.update_columns({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      if @invoice_supplier.payment_request_supplier.present? and @invoice_supplier.payment_request_supplier.status == 'approved3'
        notice_msg = "Invoice Supplier can't #{params[:status]}, #{@invoice_supplier.payment_request_supplier.number} status approved3."
        notice_kind = "alert"
      else
        @invoice_supplier.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
      end
    end
    respond_to do |format|
      format.html { redirect_to invoice_supplier_path(:id=> @invoice_supplier.id), notice_kind.to_sym => notice_msg }
      format.json { head :no_content }
    end
  end

  # DELETE /invoice_suppliers/1
  # DELETE /invoice_suppliers/1.json
  def destroy
    @invoice_supplier.update_columns({:number=> "#{@invoice_supplier.number}-deleted", :status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()})
    MaterialReceiving.where(:invoice_supplier_id=> @invoice_supplier.id).each do |material_receiving|
      material_receiving.update_columns(:invoice_supplier_id=> nil)
    end
    
    respond_to do |format|
      format.html { redirect_to invoice_suppliers_url, notice: 'Invoice supplier was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invoice_supplier
      @invoice_supplier = InvoiceSupplier.find(params[:id])
      @invoice_supplier_items = InvoiceSupplierItem.where(:invoice_supplier_id=> params[:id], :status=> 'active')
    end
    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:tax).order("suppliers.name asc")
      @material_receivings = MaterialReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:purchase_order_supplier)
      @product_receivings = ProductReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:purchase_order_supplier)
      @general_receivings = GeneralReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:purchase_order_supplier)
      @consumable_receivings = ConsumableReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:purchase_order_supplier)
      @equipment_receivings = EquipmentReceiving.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').includes(:purchase_order_supplier)
      
      @material_batch_number = MaterialBatchNumber.where(:company_profile_id=> current_user.company_profile_id)
      @product_batch_number = ProductBatchNumber.where(:company_profile_id=> current_user.company_profile_id)
      @general_batch_number = GeneralBatchNumber.where(:company_profile_id=> current_user.company_profile_id)
      @consumable_batch_number = ConsumableBatchNumber.where(:company_profile_id=> current_user.company_profile_id)
      @equipment_batch_number = EquipmentBatchNumber.where(:company_profile_id=> current_user.company_profile_id)

      @tax_rates = TaxRate.where(:status=> "active").where("end_date >= ?", DateTime.now()).order("end_date desc")
      @taxes = Tax.where(:status=> 'active')
      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
    end

    def check_status     
      if @invoice_supplier.status == 'approved3' 
        if params[:status] == "cancel_approve3"
        else 
          respond_to do |format|
            format.html { redirect_to @invoice_supplier, notice: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @invoice_supplier }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invoice_supplier_params
      params.require(:invoice_supplier).permit(:status, :number, :company_profile_id, :supplier_id, :payment_request_supplier_id, :sj_number, :fp_number, :currency_id, :date, :due_date, :tax_rate_id, :tax_id, :top_day, :term_of_payment_id, :subtotal, :ppntotal, :pphtotal, :dptotal, :remarks, :grandtotal, :created_by, :created_at, :updated_by, :updated_at)
    end
end
