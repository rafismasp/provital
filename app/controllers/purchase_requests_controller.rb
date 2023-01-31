class PurchaseRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_purchase_request, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit, :approve]
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /purchase_requests
  # GET /purchase_requests.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end
    
    purchase_requests = PurchaseRequest.where(:company_profile_id=> current_user.company_profile_id, :request_kind=> params[:q]).where("purchase_requests.date between ? and ?", session[:date_begin], session[:date_end])
    .includes(:department, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :voided, purchase_request_items: [:production_order_used_prves])
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['Department Name','department_id'], ['Remarks','remarks']] 
      @option_filter_records = purchase_requests
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'department_id'
          @option_filter_records = Department.all
        end
        purchase_requests = purchase_requests.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end

    case params[:partial]
    when 'load_spp_by_prf'      
      @production_order_items = ProductionOrderItem.where(:status=> 'active', :production_order_id=> params[:production_order_id]) if params[:production_order_id].present?
    
      @purchase_request_items = PurchaseRequestItem.where(:status=> 'active')
        .includes(:purchase_request, material: [:unit], product: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit])
        .where(:purchase_requests => {:id=> params[:purchase_request_id], :company_profile_id => current_user.company_profile_id })
        .order("purchase_requests.number desc")
      @prf_use_pdm  = PurchaseRequestUsedPdm.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    when 'load_production_order_detail_material', 'pdm_item_detail'
      @production_order_detail_materials = ProductionOrderDetailMaterial.where("prf_outstanding > 0 and status = 'active'")
      @production_order_detail_materials = @production_order_detail_materials.where(:production_order_id=> params[:production_order_id]) if params[:production_order_id].present?
      @pdm_items = PdmItem.where(:status=> 'active').where("outstanding_prf > 0").includes(:pdm).where(:pdms => {:status=> 'approved3', :company_profile_id => current_user.company_profile_id }).order("pdms.number desc")      
    end

    case params[:view_kind]
    when 'item'
      purchase_requests = PurchaseRequestItem.where(:status=> 'active')
      .includes(:purchase_request, material: [:unit], product: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit])
      .where(:purchase_requests => {:company_profile_id => current_user.company_profile_id, :request_kind=> params[:q] })
      .where("purchase_requests.date between ? and ?", session[:date_begin], session[:date_end])
      .order("purchase_requests.date desc")
    else
      purchase_requests = purchase_requests.order("date desc")
    end
    purchase_requests   = purchase_requests.order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void'])

    @sections = @sections.where(:department_id=> params[:select_department_id]) if params[:select_department_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @purchase_requests = pagy(purchase_requests, page: params[:page], items: pagy_items) 
  end

  # GET /purchase_requests/1
  # GET /purchase_requests/1.json
  def show
  end

  # GET /purchase_requests/new
  def new
    @purchase_request = PurchaseRequest.new
    select_spp = ProductionOrderDetailMaterial.where("prf_outstanding > 0 and status = 'active'").select(:production_order_id)
    @production_orders = @production_orders.where(:id=> select_spp)
  end

  # GET /purchase_requests/1/edit
  def edit
  end

  # POST /purchase_requests
  # POST /purchase_requests.json
  def create    
    params[:purchase_request]["company_profile_id"] = current_user.company_profile_id
    params[:purchase_request]["created_by"] = current_user.id
    params[:purchase_request]["created_at"] = DateTime.now()
    params[:purchase_request]["img_created_signature"] = current_user.signature
    params[:purchase_request]["number"] = document_number(controller_name, params[:purchase_request]["date"].to_date, params[:purchase_request]["employee_section_id"], nil, nil)
   
    sum_outstanding = 0
    @purchase_request = PurchaseRequest.new(purchase_request_params)
    respond_to do |format|
      new_pdm_item    = []
      # create purchase_request_items
      params[:new_record_item].each do |item|
        prf_items = @purchase_request.purchase_request_items.build({
          :material_id=> item["material_id"],
          :product_id=> item["product_id"],
          :consumable_id=> item["consumable_id"],
          :equipment_id=> item["equipment_id"],
          :general_id=> item["general_id"],
          :expected_date=> item["expected_date"],
          :quantity=> item["quantity"], :outstanding=> item["quantity"],
          :summary_production_order=> item["summary_production_order"],
          :moq_quantity=> item["moq_quantity"], :pdm_quantity=> item["pdm_quantity"],
          :remarks=> item["remarks"],
          :specification=> item["specification"],
          :justification_of_purchase=> item["justification_of_purchase"],
          :status=> 'active',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })

        if item["production_order_item_id"].present?
          # Deep Nested
          prf_items.production_order_used_prves.build({
            :company_profile_id=> current_user.company_profile_id,
            :prf_date=> params[:purchase_request]["date"].to_date,
            :production_order_detail_material_id=> nil,
            :production_order_item_id=> item["production_order_item_id"],
            :status=> 'active',
            :created_by=> current_user.id, :created_at=> DateTime.now()
          })
        end       

        sum_outstanding += ( item["quantity"].to_f > 0 ? item["quantity"].to_f : 0 )

        # 20200511
        # qty pembulatan langsung jadi PDM
        # jika PPB di void karena ada revisi SPP, PDM juga harus di void
        new_pdm_item << {
          :material_id=> (item[:material_id].present? ? item[:material_id] : nil),
          :quantity=> item[:moq_quantity],
          :pdm_outstanding=> (item[:quantity].to_f > 0 ? item[:moq_quantity] : 0)
        } if item[:moq_quantity].to_f > 0        
        item[:moq_quantity] = 0
      end if params[:new_record_item].present?
      
      if @purchase_request.save
        @purchase_request.update_columns(:outstanding=> sum_outstanding)

        production_order_detail_materials = ProductionOrderDetailMaterial.where(:company_profile_id=> current_user.company_profile_id).where("prf_outstanding > 0 and status = 'active'")
        items = PurchaseRequestItem.where(:purchase_request_id=> @purchase_request.id, :status=> 'active')
        # 20190424 - start
        # khusus prf otomatis dari spp
        items.each do |i|      
          case @purchase_request.request_kind
          when 'material'
            # digunakan untuk PRF load by SPP & Load SPP manual
            params[:new_pdm_item].each do |value|
              if value["status"] == 'suspend'
                puts "ini harusnya ga masuk"
              else
                if i["material_id"].present? and value["material_id"].to_i == i["material_id"].to_i
                  prf_use_pdm = PurchaseRequestUsedPdm.new({
                    :company_profile_id=> current_user.company_profile_id,
                    :prf_date=> params[:purchase_request]['date'].to_date,
                    :pdm_item_id=> value["pdm_item_id"],
                    :purchase_request_item_id=> i["id"],
                    :material_id=> value["material_id"],
                    :quantity=> value["qty"],
                    :status=> 'active',
                    :created_by=> current_user.id, :created_at=> DateTime.now()

                  })
                  prf_use_pdm.save!

                  pdm_item = PdmItem.find_by(:id=> value["pdm_item_id"])
                  pdm_item.update_columns({:outstanding_prf=> pdm_item.outstanding_prf.to_f-value["qty"].to_f}) if pdm_item.present?
                end
              end
            end if params[:new_pdm_item].present?

            # digunakan untuk PRF load by SPP
            params[:production_order_item].each do |spp_item|
              if i["material_id"].present? and spp_item["material_id"].to_i == i["material_id"].to_i
                spp_use_pdm = ProductionOrderUsedPrf.new({
                  :company_profile_id=> current_user.company_profile_id,
                  :prf_date=> params[:purchase_request]['date'].to_date,
                  :production_order_detail_material_id=> spp_item["production_order_detail_material_id"],
                  :production_order_item_id=> spp_item["id"],
                  :purchase_request_item_id=> i["id"],
                  :status=> 'active',
                  :created_by=> current_user.id, :created_at=> DateTime.now()
                })
                spp_use_pdm.save!

                production_order_detail_materials.where(:production_order_item_id=> spp_item["id"], :material_id=> i["material_id"], :status=> 'active').each do |spp|
                  spp.update_columns({:prf_outstanding=> 0})
                end
              end
            end if params[:production_order_item].present?
          when 'general', 'services'
            params[:production_order_item].each do |spp_item|
              if i["product_id"].present? and spp_item["product_id"].to_i == i["product_id"].to_i
                spp_use_pdm = ProductionOrderUsedPrf.new({
                  :company_profile_id=> current_user.company_profile_id,
                  :prf_date=> params[:purchase_request]['date'].to_date,
                  :production_order_detail_material_id=> spp_item["production_order_detail_material_id"],
                  :production_order_item_id=> spp_item["id"],
                  :purchase_request_item_id=> i["id"],
                  :status=> 'active',
                  :created_by=> current_user.id, :created_at=> DateTime.now()
                })
                spp_use_pdm.save!

                production_order_detail_materials.where(:production_order_item_id=> spp_item["id"], :product_id=> i["product_id"], :status=> 'active').each do |spp|
                  spp.update_columns({:prf_outstanding=> 0})
                end
              end
            end if params[:production_order_item].present?
            
          end
        end 
        # 20190424 - end

        if new_pdm_item.present?
          find_pdm = Pdm.find_by(:company_profile_id=> current_user.company_profile_id, :remarks=> "PDM pembulatan dari PPB: #{@purchase_request.number}")
          if find_pdm.blank?
            find_pdm = Pdm.create({
              :purchase_request_id=> @purchase_request.id,
              :company_profile_id=> current_user.company_profile_id,
              :automatic_calculation=> 1,              
              :number=> document_number('pdms', @purchase_request.date.to_date, nil, nil, nil),
              :date=> @purchase_request.date, :month_required=> @purchase_request.date.to_date.strftime("%Y%m"),
              :remarks=> "PDM pembulatan dari PPB: #{@purchase_request.number}",
              :status=> 'new',
              :created_by=> current_user.id, :created_at=> DateTime.now()
            })
          end
          puts "pembuatan pdm otomatis dari pembulatan PPB"
          # puts new_pdm_item
          new_pdm_item.each do |pdm_item|
            puts pdm_item
            puts "material_id : #{pdm_item[:material_id]}"
            puts "qty : #{pdm_item[:quantity]}"
            puts "-----------------------------------"
            find_pdm_item = PdmItem.find_by(:pdm_id=> find_pdm.id, :material_id=> pdm_item[:material_id])
            if find_pdm_item.present?
              find_pdm_item.update_columns({
                :material_id=> pdm_item[:material_id],
                :quantity=> pdm_item[:quantity], :outstanding=> pdm_item[:pdm_outstanding],
                :status=> 'active'
              })
            else
              new_pdm_item = PdmItem.new({
                :pdm_id=> find_pdm.id,
                :material_id=> pdm_item[:material_id], 
                :quantity=> pdm_item[:quantity],
                :outstanding_prf=> pdm_item[:quantity],
                :outstanding=> pdm_item[:pdm_outstanding],
                :status=> 'active',
                :created_at=> DateTime.now(), :created_by=> current_user.id
              })
              new_pdm_item.save!
            end
          end

          if find_pdm.present?
            find_pdm_items = PdmItem.where(:pdm_id=> find_pdm.id, :status=> 'active')
            find_pdm.update_columns(:outstanding=> find_pdm_items.sum(:outstanding)) if find_pdm_items.present?
          end
        end

        format.html { redirect_to purchase_request_path(:id=> @purchase_request.id, :q=> @purchase_request.request_kind), notice: 'Purchase request was successfully created.' }
        format.json { render :show, status: :created, location: @purchase_request }
      else
        format.html { render :new }
        format.json { render json: @purchase_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchase_requests/1
  # PATCH/PUT /purchase_requests/1.json
  def update
    respond_to do |format|
      params[:purchase_request]["automatic_calculation"] = @purchase_request.automatic_calculation
      params[:purchase_request]["updated_by"] = current_user.id
      params[:purchase_request]["updated_at"] = DateTime.now()
      params[:purchase_request]["number"] = @purchase_request.number

      if @purchase_request.update(purchase_request_params)      
        params[:new_record_item].each do |item|
          prf_item = PurchaseRequestItem.create({
            :purchase_request_id=> @purchase_request.id,
            :material_id=> item["material_id"],
            :product_id=> item["product_id"],
            :consumable_id=> item["consumable_id"],
            :equipment_id=> item["equipment_id"],
            :general_id=> item["general_id"],
            :expected_date=> item["expected_date"],
            :quantity=> item["quantity"], :outstanding=> item["quantity"],
            :remarks=> item["remarks"],
            :specification=> item["specification"],
            :justification_of_purchase=> item["justification_of_purchase"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })

          if item["production_order_item_id"].present?
            # Deep Nested
            ProductionOrderUsedPrf.create({
              :company_profile_id=> current_user.company_profile_id,
              :prf_date=> @purchase_request.date.to_date,
              :production_order_detail_material_id=> nil,
              :production_order_item_id=> item["production_order_item_id"],
              :purchase_request_item_id=> prf_item.id,
              :status=> 'active',
              :created_by=> current_user.id, :created_at=> DateTime.now()
            })
            puts "deep nested"
          end  
          logger.info item
        end if params[:new_record_item].present?

        params[:purchase_request_item].each do |item|
          transfer_item = PurchaseRequestItem.find_by(:id=> item["id"])
          case item["status"]
          when 'deleted'
            if transfer_item.status != item["status"]
              transfer_item.update_columns({
                :status=> item["status"],
                :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
              })
              transfer_item.production_order_used_prves.each do |spp_use_pdm|
                # 20210620 - jika item prf dihapus maka spp bis ditarik ulang untuk PRF baru
                spp_use_pdm.production_order_detail_material.update_columns(:prf_outstanding=> item["quantity"]) if spp_use_pdm.production_order_detail_material.present?
                spp_use_pdm.update_columns(:status=> 'suspend')
              end if transfer_item.production_order_used_prves.present?
            end
          else
            transfer_item.production_order_used_prves.each do |spp_use_pdm|
              spp_use_pdm.update_columns(:status=> 'suspend')
            end if transfer_item.production_order_used_prves.present?

            outstanding = item["quantity"].to_f
            PurchaseOrderSupplierItem.where(:purchase_request_item_id=> item[:id], :status=> 'active').each do |po_item|
              if po_item.purchase_order_supplier.status == 'approved3'
                outstanding -= po_item.quantity.to_f
              end
            end
            transfer_item.update_columns({
              :product_id=> (item["product_id"].present? ? item["product_id"] : transfer_item.product_id),
              :consumable_id=> (item["consumable_id"].present? ? item["consumable_id"] : transfer_item.consumable_id),
              :equipment_id=> (item["equipment_id"].present? ? item["equipment_id"] : transfer_item.equipment_id),
              :general_id=> (item["general_id"].present? ? item["general_id"] : transfer_item.general_id),
              :expected_date=> (item["expected_date"].present? ? item["expected_date"] : transfer_item.expected_date),
              :quantity=> (item["quantity"].present? ? item["quantity"] : transfer_item.quantity),
              :outstanding=> outstanding,
              :remarks=> (item["remarks"].present? ? item["remarks"] : transfer_item.remarks),
              :specification=> (item["specification"].present? ? item["specification"] : transfer_item.specification),
              :justification_of_purchase=> (item["justification_of_purchase"].present? ? item["justification_of_purchase"] : transfer_item.justification_of_purchase),
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })

            transfer_item.production_order_used_prves.each do |spp_use_pdm|
              spp_use_pdm.update_columns(:status=> 'active')
            end if transfer_item.production_order_used_prves.present?
          end if transfer_item.present?
        end if params[:purchase_request_item].present?

        @purchase_request.update_columns(:outstanding=> PurchaseRequestItem.where(:purchase_request_id=> @purchase_request.id, :status=> 'active').sum(:outstanding))

        # 20220428 - start
        production_order_detail_materials = ProductionOrderDetailMaterial.where(:company_profile_id=> current_user.company_profile_id).where("prf_outstanding > 0 and status = 'active'")
        items = PurchaseRequestItem.where(:purchase_request_id=> @purchase_request.id, :status=> 'active')
        # 20190424 - start
        # khusus prf otomatis dari spp
        items.each do |i|      
          case @purchase_request.request_kind
          when 'material'
            # digunakan untuk PRF load by SPP & Load SPP manual
            params[:new_pdm_item].each do |value|
              if value["status"] == 'suspend'
                puts "ini harusnya ga masuk"
              else
                if i["material_id"].present? and value["material_id"].to_i == i["material_id"].to_i
                  prf_use_pdm = PurchaseRequestUsedPdm.find_by({
                    :pdm_item_id=> value["pdm_item_id"],
                    :purchase_request_item_id=> i["id"],
                    :material_id=> value["material_id"]
                  })

                  if prf_use_pdm.present?
                    prf_use_pdm.update_columns({
                      :quantity=> value["qty"],
                      :status=> 'active'
                    })
                  else
                    prf_use_pdm = PurchaseRequestUsedPdm.new({
                      :company_profile_id=> current_user.company_profile_id,
                      :prf_date=> @purchase_request.date.to_date,
                      :pdm_item_id=> value["pdm_item_id"],
                      :purchase_request_item_id=> i["id"],
                      :material_id=> value["material_id"],
                      :quantity=> value["qty"],
                      :status=> 'active',
                      :created_by=> current_user.id, :created_at=> DateTime.now()

                    })
                    prf_use_pdm.save!
                  end
                  pdm_item = PdmItem.find_by(:id=> value["pdm_item_id"])
                  pdm_item.update_columns({:outstanding_prf=> pdm_item.outstanding_prf.to_f-value["qty"].to_f}) if pdm_item.present?
                end
              end
            end if params[:new_pdm_item].present?

            # digunakan untuk PRF load by SPP
            params[:production_order_item].each do |spp_item|
              if i["material_id"].present? and spp_item["material_id"].to_i == i["material_id"].to_i
                spp_use_pdm = ProductionOrderUsedPrf.new({
                  :company_profile_id=> current_user.company_profile_id,
                  :prf_date=> params[:purchase_request]['date'].to_date,
                  :production_order_detail_material_id=> spp_item["production_order_detail_material_id"],
                  :production_order_item_id=> spp_item["id"],
                  :purchase_request_item_id=> i["id"],
                  :status=> 'active',
                  :created_by=> current_user.id, :created_at=> DateTime.now()
                })
                spp_use_pdm.save!

                production_order_detail_materials.where(:production_order_item_id=> spp_item["id"], :material_id=> i["material_id"], :status=> 'active').each do |spp|
                  spp.update_columns({:prf_outstanding=> 0})
                end
              end
            end if params[:production_order_item].present?
          when 'general', 'services'
            params[:production_order_item].each do |spp_item|
              if i["product_id"].present? and spp_item["product_id"].to_i == i["product_id"].to_i
                spp_use_pdm = ProductionOrderUsedPrf.new({
                  :company_profile_id=> current_user.company_profile_id,
                  :prf_date=> params[:purchase_request]['date'].to_date,
                  :production_order_detail_material_id=> spp_item["production_order_detail_material_id"],
                  :production_order_item_id=> spp_item["id"],
                  :purchase_request_item_id=> i["id"],
                  :status=> 'active',
                  :created_by=> current_user.id, :created_at=> DateTime.now()
                })
                spp_use_pdm.save!

                production_order_detail_materials.where(:production_order_item_id=> spp_item["id"], :product_id=> i["product_id"], :status=> 'active').each do |spp|
                  spp.update_columns({:prf_outstanding=> 0})
                end
              end
            end if params[:production_order_item].present?
            
          end
        end 
        # 20190424 - end
        # 20220428 - end
        format.html { redirect_to purchase_requests_path(:q=> params[:q]), notice: 'Purchase request was successfully updated.' }
        format.json { render :show, status: :ok, location: @purchase_request }
      else
        format.html { render :edit }
        format.json { render json: @purchase_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
    if params[:multi_id].present?
      purchase_request_id_selected = params[:multi_id].split(',')
    else
      purchase_request_id_selected = params[:id]
    end
    pdm = Pdm.where(:company_profile_id=> current_user.company_profile_id, :purchase_request_id=> purchase_request_id_selected )
    
    case params[:status]
    when 'void'
      @purchase_request.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now(), :img_approved3_signature=>nil}) 
      # 2022-05-19 ditemukan masalah pada PRF/03A/22/05/002, ada 2 material yg di void
      PurchaseRequestItem.where(:purchase_request_id=> @purchase_request.id).each do |prf_item|
        PurchaseRequestUsedPdm.where(:purchase_request_item_id=> prf_item.id, :status=> 'active').each do |pup|
          PdmItem.where(:id=> pup.pdm_item_id, :status=> 'active').each do |pdm_item|
            pdm_item.update(:outstanding_prf=> pup.quantity)
          end
          pup.update(:status=> 'suspend')
        end
        ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item.id, :status=> 'active').each do |pup|
          ProductionOrderDetailMaterial.where(:id=> pup.production_order_detail_material_id, :status=> 'active').each do |record|
            record.update(:prf_outstanding=> record.quantity) if record.prf_outstanding != record.quantity
          end
          pup.update(:status=> 'suspend')
        end
      end
      if pdm.present?
        pdm.each do |record|
          record.update({
            :status=> 'void', 
            :voided_at=> DateTime.now(), :voided_by=> current_user.id
          })
        end
      end
    when 'cancel_void'
      @purchase_request.update({:status=> 'new'}) 
      if pdm.present?
        pdm.each do |record|
          record.update({ :status=> 'new' })
        end
      end
    when 'approve1'
      @purchase_request.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
      if pdm.present?
        pdm.each do |record|
          record.update({
            :status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()
          })
        end
      end
    when 'cancel_approve1'
      @purchase_request.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
      if pdm.present?
        pdm.each do |record|
          record.update({
            :status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()
          })
        end
      end
    when 'approve2'
      @purchase_request.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
      if pdm.present?
        pdm.each do |record|
          record.update({
            :status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()
          })
        end
      end
    when 'cancel_approve2'
      @purchase_request.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
      if pdm.present?
        pdm.each do |record|
          record.update({
            :status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()
          })
        end
      end
    when 'approve3'
      @purchase_request.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :img_approved3_signature=> current_user.signature}) 
      if pdm.present?
        pdm.each do |record|
          record.update({
            :status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()
          })
        end
      end
    when 'cancel_approve3'
      @purchase_request.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :img_approved3_signature=> nil})
      if pdm.present?
        pdm.each do |record|
          record.update_columns({
            :status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()
          })
        end
      end
    end

    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to purchase_requests_url(:q=> params[:q]), alert: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to purchase_request_path(:id=> @purchase_request.id, :q=> @purchase_request.request_kind), notice: "Purchase request was successfully #{@purchase_request.status}."  }
        format.json { head :no_content }
      end
    end
  end


  def print
    if @purchase_request.status == 'approved3'
      sop_number      = ""
      form_number     = "F-03B-001-Rev 01"
      image_path      = "app/assets/images/logo-bw.png"  
      company_name    = "PT. PROVITAL PERDANA"
      company_address1 = "Jl. Kranji Blok F15 No. 1C, Delta Silicon 2, Lippo Cikarang"
      company_address2 = "Desa Cibatu, Cikarang Selatan, Bekasi 17530"
      company_address3 = "Jawa Barat, Indonesia"

      header = @purchase_request
      items  = @purchase_request_items.where("quantity > 0")
      name_prepared_by = account_name(header.created_by) 
      name_approved_by = account_name(header.approved3_by)

      user_prepared_by = User.find_by(:id=> header.created_by)
      if user_prepared_by.present? and header.img_created_signature.present?
        img_prepared_by = "public/uploads/signature/#{user_prepared_by.id}/#{header.img_created_signature}"
        if FileTest.exist?("#{img_prepared_by}")
          puts "File Exist"
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

      document_name = "PURCHASE REQUISITION FORM"
      respond_to do |format|
        format.html do
          pdf = Prawn::Document.new(:page_size=> "A4",
            :top_margin => 0.90,
            :bottom_margin => 0.78, 
            :left_margin=> 0.59, 
            :right_margin=> 0.39 ) 
         
          # pdf.stroke_axis(:at => [20, 1], :step_length => 20, :negative_axes_length => 5, :color => '0000FF')

          pdf.move_down 75
          tbl_width = [30, 148, 112, 184, 40, 80]
          c = 1
          pdf.move_down 2
          items.each do |item|  
            po_item = PurchaseOrderSupplierItem.find_by(:purchase_request_item_id=> item.id, :status=> 'active') 
            po_number = (po_item.present? ? po_item.purchase_order_supplier.number : "")       
            if item.product.present?
              part = item.product
            elsif item.material.present?
              part = item.material
            elsif item.consumable.present?
              part = item.consumable
            elsif item.equipment.present?
              part = item.equipment
            elsif item.general.present?
              part = item.general
            end
            # (1..30).each do 
              y = pdf.y
              pdf.start_new_page if y < 600
              pdf.move_down 75 if y < 600
              pdf.table( [
                [
                  {:content=> c.to_s, :align=>:center, :size=> 10}, 
                  {:content=>(part.name if part.present?), :size=> 10},
                  {:content=> item.specification.to_s, :align=>:right, :size=> 10},
                  {:content=> "#{item.justification_of_purchase} #{po_number}", :align=>:right, :size=> 10},
                  {:content=>number_with_precision(item.quantity, precision: 0, delimiter: ".", separator: ","), :align=>:right, :size=> 10},
                  {:content=> item.expected_date.to_s, :align=>:center, :size=> 10}
                  
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
                pdf.table([
                  [ 
                    "", 
                    {:content=> "No. #{header.number}", :font_style => :bold, :align=>:left, :valign=>:center, :size=>12}, "", ""
                  ] ],:column_widths => [200, 194, 70, 130], :cell_style => {:border_width => 0, :border_color => "000000", :padding=>1}) 
                pdf.move_down 5
                pdf.stroke_horizontal_rule
                pdf.move_down 5
                       

                pdf.table([ [
                  {:content=>"No.", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Product/ Service Name", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Specification/URS", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Justification of Purchase", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Unit", :height=> 25, :valign=> :center, :align=> :center},
                  {:content=>"Expected Date", :height=> 25, :valign=> :center, :align=> :center}]], 
                  :column_widths => tbl_width, :cell_style => {:size=> 10, :align=>:center, :padding => [2, 2, 2, 2], :border_color=>"000000", :background_color => "f0f0f0", :border_width=> 0.5})
                
                pdf.move_down 215
                pdf.table([
                  [
                    "", {:content=> "Prepared by,", :align=> :center},"", {:content=> "Approved by,", :align=> :center}, ""
                  ]
                  ], :column_widths => [47, 147, 200, 147, 47], :cell_style => {:border_width => 0, :size=> 9, :border_color => "000000", :padding=>1})  

                pdf.image "#{img_prepared_by}", :at => [80,540], :width => 100 if img_prepared_by.present?
                pdf.image "#{img_approved_by}", :at => [430,540], :width => 100 if img_approved_by.present? 

                pdf.move_down 55
                pdf.table([
                  [
                    "", {:content=> "( #{name_prepared_by} )", :align=> :center},"", {:content=> "( #{name_approved_by} )", :align=> :center}, ""
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
        format.html { redirect_to @purchase_request, alert: 'Cannot be displayed, status must be Approve 3' }
        format.json { render :show, status: :ok, location: @purchase_request }
      end
    end
  end

  def export    
    template_report(controller_name, current_user.id, params[:q])
  end
  # DELETE /purchase_requests/1
  # DELETE /purchase_requests/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to purchase_requests_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_purchase_request
      if params[:multi_id].present?
        purchase_request_id_selected = params[:multi_id].split(',')
        @purchase_request = PurchaseRequest.where(:id=> purchase_request_id_selected)
      else
        purchase_request_id_selected = params[:id]
        @purchase_request = PurchaseRequest.find_by(:id=> purchase_request_id_selected)
      end

      if @purchase_request.present?
        @purchase_request_items = PurchaseRequestItem.where(:status=> 'active')
        .includes(:purchase_request, material: [:unit], product: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit])
        .where(:purchase_requests => {:id=> purchase_request_id_selected, :company_profile_id => current_user.company_profile_id })
        .order("purchase_requests.number desc")      
        @prf_use_pdm = PurchaseRequestUsedPdm.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active', :purchase_request_item_id=> @purchase_request_items.select(:id))
        
        @spp_use_prf = ProductionOrderUsedPrf.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
        .includes(purchase_request_item: [:purchase_request], production_order_item: [production_order: [:sales_order], product: [:product_type] ])
        .where(:purchase_request_items => {:status=> 'active'})
        .where(:purchase_requests => {:id=> purchase_request_id_selected, :company_profile_id => current_user.company_profile_id })
      else
        respond_to do |format|
          format.html { redirect_to purchase_requests_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @department = Department.all
      @sections = EmployeeSection.where(:status=> 'active')
      if params[:request_kind].present?
        case params[:request_kind]
        when 'product'
          @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        when 'material'
          @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        when 'consumable'
          @consumables    = Consumable.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        when 'equipment'
          @equipments= Equipment.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        when 'general'
          @generals = General.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        end
      else
        @products    = Product.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        @materials    = Material.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        @consumables    = Consumable.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        @equipments= Equipment.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
        @generals = General.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:unit)
      end
      @production_orders = ProductionOrder.where(:company_profile_id=> current_user.company_profile_id, :status=> 'approved3')
    end
    def check_status   
      noitce_msg = nil 
      if params[:multi_id].present?
        # purchase_request_id_selected = params[:multi_id].split(',')
      else
        if PurchaseOrderSupplier.find_by(:purchase_request_id=> @purchase_request.id ).present?
          noitce_msg = 'Cannot be edited because a PO has been created'
        else
          if @purchase_request.status == 'approved3'
            if params[:status] == "cancel_approve3"
            else
              noitce_msg = 'Cannot be edited because it has been approved'
            end
          end
        end
        if noitce_msg.present?
          puts "-------------------------------"
          puts  @purchase_request.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to purchase_request_path(:id=> @purchase_request.id, :q=> params[:q]), alert: noitce_msg }
            format.json { render :show, status: :created, location: @purchase_request }
          end
        end
      end
    end
    # Never trust parameters from the scary internet, only allow the white list through.
    def purchase_request_params
      params[:purchase_request]["outstanding"] = 0
      params.require(:purchase_request).permit(:automatic_calculation, :company_profile_id, :img_created_signature, :number, :date, :request_kind,  :outstanding, :department_id, :employee_section_id, :remarks, :created_by, :created_at, :updated_by, :updated_at)
    end
end
