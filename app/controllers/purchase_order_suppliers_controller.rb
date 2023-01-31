class PurchaseOrderSuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase_order_supplier, only: [:show, :edit, :update, :destroy, :approve, :print]
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

  # GET /purchase_order_suppliers
  # GET /purchase_order_suppliers.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    purchase_order_suppliers = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :kind=> params[:q], :date=> session[:date_begin] .. session[:date_end])
    .includes([:supplier, :department, :currency, :term_of_payment, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided])
    
    @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:status=> 'active', :purchase_order_supplier_id=> params[:id]).includes(purchase_request_item: [product: [:unit], material: [:unit], general: [:unit], equipment: [:unit], consumable: [:unit]])

    case params[:q]
    when 'virtual'
      @purchase_requests = PurchaseRequest.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :department_id=> params[:select_department_id]).where("outstanding > 0")
    else
      @purchase_requests = PurchaseRequest.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :department_id=> params[:select_department_id]).where("outstanding > 0").where(:request_kind=> params[:q])
    end
    @pdms = Pdm.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where("outstanding > 0")
    @pdm_items = PdmItem.where(:pdm_id=> @pdms.select(:id), :status=> 'active').where("outstanding > 0")
    @pdm_items = @pdm_items.where(:pdm_id=> params[:pdm_id]) if params[:pdm_id].present?
    @pdm_items = @pdm_items.includes(:pdm, material: [:unit])

    @purchase_request_items = PurchaseRequestItem.where(:purchase_request_id=> @purchase_requests.select(:id), :status=> 'active').where("outstanding > 0")
    @purchase_request_items = @purchase_request_items.where(:purchase_request_id=> params[:purchase_request_id]) if params[:purchase_request_id].present?
    @purchase_request_items = @purchase_request_items.includes(:purchase_request, product: [:unit], material: [:unit], general: [:unit], equipment: [:unit], consumable: [:unit])
    
    # filter select - begin
      case params[:view_kind]
      when 'item'
        purchase_order_suppliers = PurchaseOrderSupplierItem.where(:status=> 'active')
        .includes(purchase_request_item: [:purchase_request, material: [:unit]])
        .includes(pdm_item: [:pdm, material: [:unit]])
        .includes(:purchase_order_supplier)
        .where(:purchase_order_suppliers => {:company_profile_id => current_user.company_profile_id, :kind=> params[:q], :date=> session[:date_begin] .. session[:date_end] })
        .order("purchase_order_suppliers.date desc")    

        @option_filters = [['PO Number','po_supplier_number'],['PRF number', 'prf_number'], ['PDM number', 'pdm_number']]
        @option_filter_records = purchase_order_suppliers
        
        if params[:filter_column].present?
          case params[:filter_column] 
          when 'pdm_number'
            @option_filter_records = Pdm.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
            purchase_order_suppliers = purchase_order_suppliers.where(:pdms=> {:number=> params[:filter_value]})
          when 'prf_number'
            @option_filter_records = PurchaseRequest.where(:company_profile_id=> current_user.company_profile_id, :request_kind=> params[:q], :status=> 'approved3')
            purchase_order_suppliers = purchase_order_suppliers.where(:purchase_requests=> {:number=> params[:filter_value]})
          when 'po_supplier_number'
            @option_filter_records = PurchaseOrderSupplier.where(:company_profile_id=> current_user.company_profile_id, :kind=> params[:q], :date=> session[:date_begin] .. session[:date_end])
            purchase_order_suppliers = purchase_order_suppliers.where(:purchase_order_suppliers=> {:number=> params[:filter_value]})
          end

        end
      else
        @option_filters = [['PO Number','number'],['Doc.Status','status'], ['Supplier Name', 'supplier_id'], ['Currency', 'currency_id']] 
        @option_filter_records = purchase_order_suppliers
        
        if params[:filter_column].present?
          case params[:filter_column] 
          when 'currency_id'
            @option_filter_records = Currency.all
          when 'supplier_id'
            @option_filter_records = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
          end

          purchase_order_suppliers = purchase_order_suppliers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
        end
      end  
    # filter select - end

    purchase_order_suppliers   = purchase_order_suppliers.order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("purchase_order_suppliers.date desc")

    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @purchase_order_suppliers = pagy(purchase_order_suppliers, page: params[:page], items: pagy_items) 
  end

  # GET /purchase_order_suppliers/1
  # GET /purchase_order_suppliers/1.json
  def show
  end

  # GET /purchase_order_suppliers/new
  def new
    @purchase_order_supplier = PurchaseOrderSupplier.new
  end
  # GET /purchase_order_suppliers/1/edit
  def edit
    @purchase_requests = PurchaseRequest.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where("outstanding > 0")
    @pdms = Pdm.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3').where("outstanding > 0")
  end

  # POST /purchase_order_suppliers
  # POST /purchase_order_suppliers.json
  def create
    params[:purchase_order_supplier]["outstanding"] = 0
    params[:purchase_order_supplier]["company_profile_id"] = current_user.company_profile_id
    params[:purchase_order_supplier]["created_by"] = current_user.id
    params[:purchase_order_supplier]["img_created_signature"] = current_user.signature
    params[:purchase_order_supplier]["created_at"] = DateTime.now()
    params[:purchase_order_supplier]["number"] = document_number(controller_name, params[:purchase_order_supplier]['date'].to_date, nil, nil, nil)
    @purchase_order_supplier = PurchaseOrderSupplier.new(purchase_order_supplier_params)

    respond_to do |format|
      if @purchase_order_supplier.save

        sum_outstanding = 0
        params[:new_record_item].each do |item|
          PurchaseOrderSupplierItem.create({
            :purchase_order_supplier_id=> @purchase_order_supplier.id, 
            :purchase_request_item_id=> (item["purchase_request_item_id"].present? ? item["purchase_request_item_id"] : nil),
            :pdm_item_id=> (item["pdm_item_id"].present? ? item["pdm_item_id"] : nil),
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :unit_price=> item["unit_price"],
            :remarks=> item["remarks"],
            :due_date=> item["due_date"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          sum_outstanding += item["quantity"].to_f
        end if params[:new_record_item].present?


        if params[:file].present?
          params["file"].each do |many_files|
            if many_files[:attachment].present?
              content =  many_files[:attachment].read
              hash = Digest::MD5.hexdigest(content)
              fid = PurchaseOrderSupplierFile.where(:purchase_order_supplier_id=>@purchase_order_supplier.id)
              pf = fid.find_by(:file_hash=>hash)
              if pf.blank?
                filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
                ext=File.extname(filename_original)
                filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
                dir = "public/uploads/purchase_order_supplier/"
                FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
                path = File.join(dir, "#{hash}#{ext}")
                tmp_path_filename=File.join('/tmp', filename)
                File.open(path, 'wb') do |file|
                  file.write(content)
                  PurchaseOrderSupplierFile.create({
                    :purchase_order_supplier_id=> @purchase_order_supplier.id,
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

        case @purchase_order_supplier.kind
        when 'virtual'
          # PO Virtual tidak perlu dibuatkan GRN, karena tujuannya untuk tutup PRF dan PDM
        else
          @purchase_order_supplier.update_columns(:outstanding=> sum_outstanding)
        end
        format.html { redirect_to purchase_order_supplier_path(:id=> @purchase_order_supplier.id, :q=> @purchase_order_supplier.kind), notice: "#{@purchase_order_supplier.number} supplier was successfully created." }
        format.json { render :show, status: :created, location: @purchase_order_supplier }
      else
        format.html { render :new }
        format.json { render json: @purchase_order_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchase_order_suppliers/1
  # PATCH/PUT /purchase_order_suppliers/1.json
  def update
    respond_to do |format|
      params[:purchase_order_supplier]["updated_by"] = current_user.id
      params[:purchase_order_supplier]["updated_at"] = DateTime.now()
      params[:purchase_order_supplier]["number"] = @purchase_order_supplier.number
      if @purchase_order_supplier.update(purchase_order_supplier_params)
        params[:new_record_item].each do |item|
          transfer_item = PurchaseOrderSupplierItem.create({
            :purchase_order_supplier_id=> @purchase_order_supplier.id,
            :purchase_request_item_id=> (item["purchase_request_item_id"].present? ? item["purchase_request_item_id"] : nil),
            :pdm_item_id=> (item["pdm_item_id"].present? ? item["pdm_item_id"] : nil),
            :quantity=> item["quantity"],
            :outstanding=> item["quantity"],
            :unit_price=> item["unit_price"],
            :remarks=> item["remarks"],
            :due_date=> item["due_date"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?
        params[:record_item].each do |item|
          po_item = PurchaseOrderSupplierItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            po_item.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            # 20210428 - aden
            if item["quantity"].to_f != po_item.quantity.to_f
              # jika ada perubahan qty PO
              new_qty         = item["quantity"]
              qty_grn         = (po_item.quantity - po_item.outstanding).to_f
              new_outstanding = (item["quantity"].to_f - qty_grn)
              
              if item["quantity"].to_f < qty_grn 
                new_qty         = minimal_qty
                new_outstanding = 0
              end
            else
              # jika tidak ada perubahan qty
              new_qty         = po_item.quantity
              new_outstanding = po_item.outstanding
            end

            po_item.update_columns({
              :purchase_request_item_id=> (item["purchase_request_item_id"].present? ? item["purchase_request_item_id"] : nil),
              :pdm_item_id=> (item["pdm_item_id"].present? ? item["pdm_item_id"] : nil),
              :quantity=> new_qty, :outstanding=> new_outstanding,
              :unit_price=> item["unit_price"],
              :remarks=> item["remarks"],
              :due_date=> item["due_date"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end if po_item.present?
        end if params[:record_item].present?

        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = PurchaseOrderSupplierFile.where(:purchase_order_supplier_id=>@purchase_order_supplier.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/purchase_order_supplier/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                PurchaseOrderSupplierFile.create({
                  :purchase_order_supplier_id=> @purchase_order_supplier.id,
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
          file = PurchaseOrderSupplierFile.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            file.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          end
        end if params["record_file"].present?
        format.html { redirect_to purchase_order_supplier_path(:q=> @purchase_order_supplier.kind), notice: 'Purchase order supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @purchase_order_supplier }
      else
        format.html { render :edit }
        format.json { render json: @purchase_order_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchase_order_suppliers/1
  # DELETE /purchase_order_suppliers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to purchase_order_suppliers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def approve
    case params[:status]
    when 'approve3'
      @purchase_order_supplier.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
    when 'cancel_approve3'
      alert = nil
      @purchase_order_supplier_items.each do |item|
        case @purchase_order_supplier.kind
        when 'material'
          if item.material_receiving_items.present?
            alert = "Sudah dibuatkan GRN tidak bisa dicancel!"
          end
        when 'general', 'services'
          if item.product_receiving_items.present?
            alert = "Sudah dibuatkan PRN tidak bisa dicancel!"
          end
        end
      end
      if alert.blank?
        @purchase_order_supplier.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil}) 
      end
    when 'approve2'
      @purchase_order_supplier.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now(), :img_approved2_signature=> current_user.signature}) 
    when 'cancel_approve2'
      @purchase_order_supplier.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now(), :img_approved2_signature=> nil})
    when 'approve1'
      alert = nil
      @purchase_order_supplier_items.each do |item|
        purchase_request_item = PurchaseRequestItem.find_by(:id=> item.purchase_request_item_id)
        if purchase_request_item.present?
          if (purchase_request_item.outstanding.to_f-item.quantity.to_f) < 0
            alert = "PRF: Qty tidak boleh lebih dari outstanding!"
          end
          if purchase_request_item.product.present?
            update_po_price(@purchase_order_supplier.date, 'product', purchase_request_item.product_id, item.unit_price)
          elsif purchase_request_item.material.present?
            update_po_price(@purchase_order_supplier.date, 'material', purchase_request_item.material_id, item.unit_price)
          elsif purchase_request_item.consumable.present?
            update_po_price(@purchase_order_supplier.date, 'consumable', purchase_request_item.consumable_id, item.unit_price)
          elsif purchase_request_item.equipment.present?
            update_po_price(@purchase_order_supplier.date, 'equipment', purchase_request_item.equipment_id, item.unit_price)
          elsif purchase_request_item.general.present?
            update_po_price(@purchase_order_supplier.date, 'general', purchase_request_item.general_id, item.unit_price)
          end

        end
        pdm_item = PdmItem.find_by(:id=> item.pdm_item_id)
        if pdm_item.present?
          if (pdm_item.outstanding.to_f-item.quantity.to_f) < 0
            alert = "PDM: Qty tidak boleh lebih dari outstanding!"
          end
        end
      end
      if alert.blank?
        @purchase_order_supplier.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
        @purchase_order_supplier_items.each do |item|
          purchase_request_item = PurchaseRequestItem.find_by(:id=> item.purchase_request_item_id)
          if purchase_request_item.present?
            purchase_request_item.update(:outstanding=> purchase_request_item.outstanding.to_f-item.quantity.to_f)
            purchase_request = PurchaseRequest.find_by(:id=> purchase_request_item.purchase_request_id)
            if purchase_request.present?
              purchase_request.update(:outstanding=> purchase_request.outstanding.to_f-item.quantity.to_f)
              # update outstanding diheader
            end
          end
          pdm_item = PdmItem.find_by(:id=> item.pdm_item_id)
          if pdm_item.present?
            pdm_item.update(:outstanding=> pdm_item.outstanding.to_f-item.quantity.to_f)
            pdm = Pdm.find_by(:id=> pdm_item.pdm_id)
            if pdm.present?
              pdm.update(:outstanding=> pdm.outstanding.to_f-item.quantity.to_f)
              # update outstanding diheader
            end
          end
        end
      end
    when 'cancel_approve1'
      @purchase_order_supplier.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()})
      @purchase_order_supplier_items.each do |item|
        purchase_request_item = PurchaseRequestItem.find_by(:id=> item.purchase_request_item_id)
        if purchase_request_item.present?
          purchase_request_item.update(:outstanding=> purchase_request_item.outstanding.to_f+item.quantity.to_f)
          purchase_request = PurchaseRequest.find_by(:id=> purchase_request_item.purchase_request_id)
          if purchase_request.present?
            purchase_request.update(:outstanding=> purchase_request.outstanding.to_f+item.quantity.to_f)
            # update outstanding diheader
          end
        end
        pdm_item = PdmItem.find_by(:id=> item.pdm_item_id)
        if pdm_item.present?
          pdm_item.update(:outstanding=> pdm_item.outstanding.to_f+item.quantity.to_f)
          pdm = Pdm.find_by(:id=> pdm_item.pdm_id)
          if pdm.present?
            pdm.update(:outstanding=> pdm.outstanding.to_f+item.quantity.to_f)
            # update outstanding diheader
          end
        end
      end
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to purchase_order_suppliers_url(:q=> params[:q]), alert: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        if alert.blank?
          notice_info = "Purchase Order was successfully #{@purchase_order_supplier.status}."
        else
          notice_info = alert
        end
        if alert.present?
          format.html { redirect_to purchase_order_supplier_path(:id=> @purchase_order_supplier.id, :q=> @purchase_order_supplier.kind), alert: notice_info }
          format.json { head :no_content }
        else
          format.html { redirect_to purchase_order_supplier_path(:id=> @purchase_order_supplier.id, :q=> @purchase_order_supplier.kind), notice: notice_info }
          format.json { head :no_content }
        end
      end
    end

  end

  def print
    if @purchase_order_supplier.status == 'approved3'  
      sop_number      = ""
      form_number     = "F-03B-002-Rev 04"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. Provital Perdana"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @purchase_order_supplier
      items  = @purchase_order_supplier_items
      order_number = ""

      term_of_payment = (header.term_of_payment.present? ? header.term_of_payment.name : '')
      supplier_name  = (header.supplier.present? ? header.supplier.name : '')
      supplier_code  = (header.supplier.present? ? header.supplier.number : '')
      supplier_address  = (header.supplier.present? ? header.supplier.address : '')
      supplier_phone  = (header.supplier.present? ? header.supplier.telephone : '')
      supplier_email  = (header.supplier.present? ? header.supplier.email : '')

      currency_name = (header.currency.present? ? header.currency.name : nil)
      precision_digit = (header.currency.present? ? header.currency.precision_digit : 0)

      name_prepared_by = account_name(header.created_by) 
      name_approved2_by = account_name(header.approved2_by)
      name_approved3_by = account_name(header.approved3_by)
      
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

      if header.status == 'approved3' 
        if header.img_approved2_signature.present? 
          user_approved2_by = User.find_by(:id=> header.approved2_by)
          if user_approved2_by.present?
            img_approved2_by = "public/uploads/signature/#{user_approved2_by.id}/#{header.img_approved2_signature}"
            if FileTest.exist?("#{img_approved2_by}")
              puts "File Exist"
              puts img_approved2_by
            else
              puts "File not found: #{img_approved2_by}"
              img_approved2_by = nil
            end
          else
            img_approved2_by = nil
          end      
        else
          img_approved2_by = nil
        end   
        
        if header.img_approved3_signature.present? 
          user_approved3_by = User.find_by(:id=> header.approved3_by)
          if user_approved3_by.present?
            img_approved3_by = "public/uploads/signature/#{user_approved3_by.id}/#{header.img_approved3_signature}"
            if FileTest.exist?("#{img_approved3_by}")
              puts "File Exist"
              puts img_approved3_by
            else
              puts "File not found: #{img_approved3_by}"
              img_approved3_by = nil
            end
          else
            img_approved3_by = nil
          end
        else
          img_approved3_by = nil
        end
      end  


      pdf_items = {}
      items.each do |item|    
        part = nil 
        prf_number = nil 
        prf_date = nil 
        if item.purchase_request_item.present? 
         record_item = item.purchase_request_item 
         if record_item.present? 
           if record_item.product.present? 
             part = record_item.product 
           elsif record_item.material.present? 
             part = record_item.material 
           elsif record_item.consumable.present? 
             part = record_item.consumable 
           elsif record_item.equipment.present? 
             part = record_item.equipment 
           elsif record_item.general.present? 
             part = record_item.general 
           end 
         end 
         unit_name = (part.present? ? part.unit_name : nil)
         prf_number =  record_item.purchase_request.number 
         prf_date =  record_item.purchase_request.date 
        elsif item.pdm_item.present? 
         record_item = item.pdm_item 
         if record_item.present? 
           if record_item.material.present? 
             part = record_item.material 
           end 
           prf_number =  record_item.pdm.number 
           prf_date =  record_item.pdm.date 
         end 
        end 

        pdf_items["#{part.part_id}".to_sym] ||= {}
        pdf_items["#{part.part_id}".to_sym][:part_name] = part.name
        pdf_items["#{part.part_id}".to_sym][:part_code] = part.part_id
        pdf_items["#{part.part_id}".to_sym][:unit_name] = unit_name
        pdf_items["#{part.part_id}".to_sym][:unit_price] = item.unit_price.to_f
        pdf_items["#{part.part_id}".to_sym][:remarks] = item.remarks
      
        if pdf_items["#{part.part_id}".to_sym][:quantity].present?
          pdf_items["#{part.part_id}".to_sym][:quantity] += item.quantity.to_f
        else
          pdf_items["#{part.part_id}".to_sym][:quantity] = item.quantity.to_f
        end
      end

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

          pdf.move_down 185
          tbl_width = [30, 284, 80, 40, 80, 80]
          c = 1
          pdf.move_down 2

          pdf_items.each do |part_id, item|
            total_price = (item[:quantity].to_f*item[:unit_price].to_f)
            logger.info "part_name: #{item[:part_name]}"
            logger.info "quantity: #{item[:quantity].to_f}"
            logger.info "unit_price: #{item[:unit_price].to_f}"
            logger.info "total_price: #{total_price}"
            logger.info "precision_digit: #{precision_digit}"
            y = pdf.y
            pdf.start_new_page if y < 525
            pdf.move_down 185 if y < 525
            pdf.table( [
              [
                {:content=> c.to_s, :align=>:center, :size=> 10}, 
                {:content=>item[:part_name].to_s, :size=> 10},
                {:content=>number_with_precision(item[:quantity].to_f, precision: 1, delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                {:content=> item[:unit_name].to_s, :align=>:center, :size=> 10},
                {:content=>number_with_precision(item[:unit_price].to_f, precision: (item[:unit_price].to_f % 1 == 0 ? precision_digit : 2), delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                {:content=>number_with_precision(total_price, precision: (total_price.to_f % 1 == 0 ? precision_digit : 2), delimiter: ".", separator: ","), :align=>:right, :size=> 10}
              ]], :column_widths => tbl_width, :cell_style => {:padding => [2, 5, 0, 4], :border_color=>"ffffff"})
            pdf.table( [
              [
                {:content=> "", :align=>:center, :size=> 10}, 
                {:content=>"#{item[:remarks]}", :size=> 10},
                {:content=> "", :align=>:right, :size=> 10},
                {:content=> "", :align=>:right, :size=> 10},
                {:content=> "", :align=>:right, :size=> 10},
                {:content=> "", :align=>:right, :size=> 10}
              ]], :column_widths => tbl_width, :cell_style => {:padding => [2, 5, 0, 4], :border_color=>"ffffff"}) if item[:remarks].present?
            
            c +=1
            sub_total += total_price
            
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

                pdf.bounding_box([315, 812], :width => 145, :height => 50) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([460, 812], :width => 130, :height => 50) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end

                pdf.bounding_box([315, 747], :width => 275, :height => 65) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([0, 747], :width => 315, :height => 65) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([0, 747], :width => 30, :height => 65) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([460, 747], :width => 130, :height => 35) do
                  pdf.stroke_color '000000'
                  pdf.stroke_bounds
                end
                pdf.bounding_box([460, 712], :width => 130, :height => 30) do
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
                pdf.move_down 2
                # pdf.table([
                #   [{:content=> "Plant", :size=> 10, :font_style => :bold}, {:content=> "Office", :size=> 10, :font_style => :bold}, "", "","", "", ""],
                #   [{:content=> "Jl. Kranji Blok F15 No. 1C,", :size=> 9}, {:content=> "Gading Bukit Indah Blok SB No. 23,", :size=> 9}, "", "","", "", "", "", ""],
                #   [{:content=> "Delta Silicon 2, Lippo Cikarang,", :size=> 9}, {:content=> "Kelapa Gading, Jakarta 14240", :size=> 9}, "", {:content=> "PRF No.", :size=> 9}, ":", {:content=> "#{header.purchase_request.present? ? header.purchase_request.number : nil}", :size=> 9}, {:content=> "Delivery", :size=> 9}, "", ""],
                #   [{:content=> "Bekasi 17530", :size=> 9}, {:content=> "", :size=> 9}, "", {:content=> "PO No.", :size=> 9}, ":", {:content=> "#{header.present? ? header.number : nil}", :size=> 9}, {:content=> "Date", :size=> 9}, ":", {:content=> "", :size=> 9}],
                #   [{:content=> "", :size=> 9}, {:content=> "", :size=> 9}, "", {:content=> "Date", :size=> 9}, ":", {:content=> "#{header.present? ? header.date : nil}", :size=> 9}, {:content=> "Day", :size=> 9}, ":", {:content=> "", :size=> 9}]                
                #   ],
                #   :column_widths => [148, 160, 8, 40, 8, 100, 40, 8, 80], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 
                
                pdf.table([
                  [{:content=> "Office & Plant :", :size=> 10, :font_style => :bold}, "", "", {:content=> "PRF No.", :size=> 9, :font_style => :bold}, ":", {:content=> "#{header.purchase_request.present? ? header.purchase_request.number : nil}", :size=> 9}, {:content=> "Delivery", :size=> 9, :font_style => :bold}, "", ""],
                  [{:content=> "#{company_address1}", :size=> 9}, "", "", {:content=> "PO No.", :size=> 9, :font_style => :bold}, ":", {:content=> "#{header.present? ? header.number : nil}", :size=> 9}, {:content=> "Date", :size=> 9}, ":", {:content=> "", :size=> 9}],
                  [{:content=> "#{company_address2}", :size=> 9}, "", "", {:content=> "Date", :size=> 9, :font_style => :bold}, ":", {:content=> "#{header.present? ? header.date : nil}", :size=> 9}, {:content=> "Day", :size=> 9}, ":", {:content=> "", :size=> 9}]
                  ],
                  :column_widths => [300, 8, 8, 40, 8, 100, 40, 8, 80], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1 }) 

                pdf.table([
                  [ 
                    {:content=>document_name, :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", "", ""
                  ]],
                  :column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 2

                pdf.table([
                  [{:content=>"TO", :font_style => :bold, :size=>9, :align=>:center}, "", {:content=>"Supplier", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_name}", :size=>9}, {:content=>"Ship to", :size=>9, :align=> :center, :font_style => :bold},":", {:content=>"#{company_name}", :size=>9}, "", {:content=>"Category :", :size=>9, :font_style => :bold}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Address", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_address.to_s[0..90]}", :size=>9, :height=> 22}, {:content=>"#{company_address1}", :size=>9, :colspan=> 3},  "", {:content=>"#{header.asset_kind.humanize}", :size=>9}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Phone", :size=>9, :font_style => :bold},":", {:content=> "#{supplier_phone}", :size=>9}, {:content=>"", :size=>9},"", "", "", {:content=>"Cost Center :", :size=>9, :font_style => :bold}],
                  [{:content=>"", :font_style => :bold, :size=>9}, "", {:content=>"Email", :size=>8, :font_style => :bold},":", {:content=> "#{supplier_email}", :size=>9}, {:content=>"", :size=>9},"", "", "", {:content=>"", :size=>9}]
                  ], :column_widths => [30, 5, 45, 10, 225, 35, 10, 100, 5, 125], :cell_style => {:border_width => 0, :border_color => "000000", :padding=> [0,0,0,1]}) 
                
                pdf.move_down 1
                pdf.table([
                  [ 
                    {:content=>"Please supply the following items / materials :", :size=>9}
                  ]],
                  :column_widths => [200], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 

                pdf.move_down 1          

                pdf.table([ ["No.","DESCRIPTIONS", "QTY", "UNIT", "UNIT PRICE", "TOTAL"]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
              }
            # header end

            # content begin
              den_row = 0
              tbl_top_position = 653
              
              tbl_width.each do |i|
                # puts den_row
                den_row += i
                pdf.bounding_box([0, tbl_top_position], :width => den_row, :height => 140) do
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

              pdf.bounding_box([0, tbl_top_position-140], :width => 80, :height => 60) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([10, tbl_top_position-145], :width => 80) do
                pdf.text "Prepared by,", :size=> 10
              end
              pdf.bounding_box([0, tbl_top_position-156], :width => 80) do
                pdf.table([
                  [{:image=>img_prepared_by, :position=>:center, :scale=>0.15, :height=>30}],
                  [{:content=>"#{name_prepared_by.split(/\W+/)[0][0..12]}", :align=>:center}]
                ], :column_widths => [80], :cell_style => {:border_color => "000000", :borders=>[:left, :right], :padding=>0})
              end if img_prepared_by.present?

              pdf.bounding_box([80, tbl_top_position-140], :width => 80, :height => 60) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([90, tbl_top_position-145], :width => 80) do
                pdf.text "Reviewed by,", :size=> 10
              end
              pdf.bounding_box([80, tbl_top_position-156], :width => 80) do
                pdf.table([
                  [{:image=>img_approved2_by, :position=>:center, :scale=>0.15, :height=>30}],
                  [{:content=>"#{name_approved2_by.split(/\W+/)[0][0..12]}", :align=>:center}]
                ], :column_widths => [80], :cell_style => {:border_color => "000000", :borders=>[:left, :right], :padding=>0})
              end if img_approved2_by.present?

              pdf.bounding_box([160, tbl_top_position-140], :width => 80, :height => 60) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([170, tbl_top_position-145], :width => 80) do
                pdf.text "Approved by,", :size=> 10
              end
              pdf.bounding_box([160, tbl_top_position-156], :width => 80) do
                pdf.table([
                  [{:image=>img_approved3_by, :position=>:center, :scale=>0.15, :height=>30}],
                  [{:content=>"#{name_approved3_by.split(/\W+/)[0][0..12]}", :align=>:center}]
                ], :column_widths => [80], :cell_style => {:border_color => "000000", :borders=>[:left, :right], :padding=>0})
              end if img_approved3_by.present?

              pdf.bounding_box([240, tbl_top_position-140], :width => 194, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([240, tbl_top_position-170], :width => 194, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end

              pdf.bounding_box([245, tbl_top_position-145], :width => 160) do
                pdf.text "Payment Terms : #{header.top_day} #{term_of_payment}", :size=> 10
              end

              pdf.bounding_box([245, tbl_top_position-175], :width => 80) do
                pdf.text "Remarks : #{header.remarks}", :size=> 10
              end

              pdf.bounding_box([434, tbl_top_position-140], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, tbl_top_position-145], :width => 80) do
                pdf.text "SUB TOTAL", :size=> 10
              end
              pdf.bounding_box([434, tbl_top_position-155], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, tbl_top_position-160], :width => 80) do
                pdf.text "PPN", :size=> 10
              end
              pdf.bounding_box([516, tbl_top_position-160], :width => 79) do
                pdf.text "#{currency_name}", :align=> :left , :size=> 9
              end
              pdf.bounding_box([514, tbl_top_position-160], :width => 79) do
                pdf.text number_with_precision(ppn_total, precision: (ppn_total.to_f % 1 == 0 ? precision_digit : 2), delimiter: ".", separator: ","), :align=> :right , :size=> 9
              end

              pdf.bounding_box([514, tbl_top_position-140], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([516, tbl_top_position-145], :width => 79) do
                pdf.text "#{currency_name}", :align=> :left , :size=> 9
              end
              pdf.bounding_box([514, tbl_top_position-145], :width => 79) do
                pdf.text number_with_precision(sub_total, precision: (sub_total.to_f % 1 == 0 ? precision_digit : 2), delimiter: ".", separator: ","), :align=> :right, :size=> 9
              end
              pdf.bounding_box([514, tbl_top_position-155], :width => 80, :height => 15) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end

              pdf.bounding_box([434, tbl_top_position-170], :width => 80, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([434, tbl_top_position-170], :width => 160, :height => 30) do
                pdf.stroke_color '000000'
                pdf.stroke_bounds
              end
              pdf.bounding_box([440, tbl_top_position-175], :width => 80) do
                pdf.text "TOTAL", :size=> 10
              end
              pdf.bounding_box([516, tbl_top_position-175], :width => 79) do
                pdf.text "#{currency_name}", :align=> :left , :size=> 9
              end
              pdf.bounding_box([514, tbl_top_position-175], :width => 79) do
                pdf.text number_with_precision(grand_total, precision: (grand_total.to_f % 1 == 0 ? precision_digit : 2), delimiter: ".", separator: ","), :align=> :right , :size=> 9
              end

              pdf.bounding_box([1, tbl_top_position-205], :width => 549) do
                pdf.text "Note : PO must be attached at the time of billing. If there is a specification and/or quality change, the supplier must inform the Purchasing Section of 
                PT. Provital Perdana", :size=> 7, :style=> :bold
              end
              pdf.bounding_box([1, tbl_top_position-225], :width => 549) do
                pdf.text "White : Finance", :size=> 9
              end
              pdf.bounding_box([150, tbl_top_position-225], :width => 549) do
                pdf.text "Red : Purchasing", :size=> 9
              end
              pdf.bounding_box([360, tbl_top_position-225], :width => 549) do
                pdf.text "Yellow : Warehouse", :size=> 9
              end
              pdf.bounding_box([515, tbl_top_position-225], :width => 549) do
                pdf.text "#{form_number}", :size=> 9
              end
            # content end

            # footer begin
              pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom], :width => pdf.bounds.width, :height => pdf.bounds.height) {
                pdf.go_to_page i+1
                # pdf.move_up 420
                
                # pdf.table([
                #   [
                #     "White : Finance", "Red : Purchasing", {:content=> "Yellow : Warehouse", :align=> :right}, {:content=> "#{form_number}", :align=> :right}
                #   ]
                #   ], :column_widths => [147, 147, 147, 147], :cell_style => {:size=> 9, :border_color => "ffffff", :padding=>1})  

              }

              # 20200807 - udin: minta dihilangin page numbering
              # pdf.number_pages "Page <page> of <total>", :size => 11, :at => [40, 10]
            # footer end
          end

          send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "doc.pdf"
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to purchase_order_supplier_path(:id=> @purchase_order_supplier.id, :q=> @purchase_order_supplier.kind), alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @purchase_order_supplier }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_purchase_order_supplier
      if params[:multi_id].present?
        id_selected = params[:multi_id].split(',')
        @purchase_order_supplier = PurchaseOrderSupplier.where(:id=> id_selected)
      else
        id_selected = params[:id]
        @purchase_order_supplier = PurchaseOrderSupplier.find_by(:id=> id_selected)
      end

      if @purchase_order_supplier.present?
        @record_files = PurchaseOrderSupplierFile.where(:purchase_order_supplier_id=> id_selected, :status=> 'active')
        @purchase_order_supplier_items = PurchaseOrderSupplierItem.where(:status=> 'active').includes([:purchase_order_supplier, pdm_item: [:pdm, :material], purchase_request_item: [:purchase_request, :material, :product]])
        .where(:purchase_order_suppliers => {:id=> id_selected, :company_profile_id => current_user.company_profile_id })
        .order("purchase_order_suppliers.number desc")      
      else
        respond_to do |format|
          format.html { redirect_to purchase_order_suppliers_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @departments = Department.all
      @sections = EmployeeSection.where(:status=> 'active')
      @suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:tax).order("suppliers.name asc")
      @taxes = Tax.where(:status=> "active")
      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
    end

    def update_po_price(periode_date, kind, kind_id, unit_price)      
      po_price = PurchaseOrderPrice.find_by(
        :company_profile_id=> current_user.company_profile_id, 
        :date=> periode_date, 
        "#{kind}_id".to_sym => kind_id)
      if po_price.present?
        po_price.update_columns({
          :unit_price=> unit_price,
          :status=> 'active',
          :updated_by=> current_user.id, :updated_at=> DateTime.now()
        })
      else
        PurchaseOrderPrice.create({
          :company_profile_id=> current_user.company_profile_id, 
          :date=> periode_date, 
          "#{kind}_id".to_sym => kind_id,
          :unit_price=> unit_price,
          :status=> 'active',
          :created_by=> current_user.id, :created_at=> DateTime.now()
        })
      end
    end

    def check_status     
      if @purchase_order_supplier.status == 'approved3'  
        if params[:status] == "cancel_approve3"
        else 
          puts "-------------------------------"
          puts  @purchase_order_supplier.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to @purchase_order_supplier, alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @purchase_order_supplier }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def purchase_order_supplier_params
      params.require(:purchase_order_supplier).permit(:company_profile_id, :number, :kind, :asset_kind, :department_id, :employee_section_id, :outstanding, :supplier_id, :date, :due_date, :tax_id, :term_of_payment_id, :top_day, :currency_id, :remarks, :purchase_request_id, :pdm_id, :created_by, :created_at, :updated_at, :updated_by, :img_created_signature)
    end
end
