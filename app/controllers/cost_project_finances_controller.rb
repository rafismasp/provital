class CostProjectFinancesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_instance_variable
  before_action :set_cost_project_finance, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /cost_project_finances
  # GET /cost_project_finances.json
  def index
    records = @records
    if params[:filter_column].present?
      filter_column = params[:filter_column]
      case params[:filter_column] 
      when 'customer_id'
        @option_filter_records = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("name asc")
      when 'sales_order_id'
        @option_filter_records = @records
        filter_column = 'id'
      when 'so_project_name'
        @option_filter_records = @records
        filter_column = 'remarks'
      end

      records = @records.where("#{filter_column}".to_sym=> params[:filter_value]) if params[:filter_value].present?
    end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @records = pagy(records, page: params[:page], items: pagy_items)
  end

  # GET /cost_project_finances/1
  # GET /cost_project_finances/1.json
  def show
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  def print
    respond_to do |format|
      format.html do
        pdf = Prawn::Document.new(:page_size=> "A4",
          :top_margin => 2,
          :bottom_margin => 2, 
          :left_margin=> 2, 
          :right_margin=> 2 ) 
        pdf.text "Cost Project Finance", :align=> :center, :size=> 14
        pdf.stroke_horizontal_rule
        case params[:kind]
        when 'v1', 'v2'
          records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id, :date => session[:date_begin] .. session[:date_end])
            .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, customer:[:currency])
            .includes(sales_order_items:[ 
              production_order_items: [
                production_order_used_prves: [
                  purchase_request_item: [
                    :purchase_request,
                    purchase_order_supplier_items: [ 
                      product_receiving_items: [
                        :product_receiving, :purchase_order_supplier_item
                      ], material_receiving_items: [
                        :material_receiving, :purchase_order_supplier_item
                      ], general_receiving_items: [
                        :general_receiving, :purchase_order_supplier_item
                      ], consumable_receiving_items: [
                        :consumable_receiving, :purchase_order_supplier_item
                      ], equipment_receiving_items: [
                        :equipment_receiving, :purchase_order_supplier_item
                      ], purchase_order_supplier: [:currency, :purchase_order_supplier_items]]]]]])
        else
        end

        pdf.font_size 9

        case params[:kind]
        when 'v1'
          records.each do |record|
            pdf.table([
              [
                {:content=> "Customer", :width=> 60, :font_style=> :bold},
                {:content=> "#{record.customer.name if record.customer.name}"}
                
              ]
            ])
            pdf.table([
              [
                {:content=> "SO Number", :width=> 60, :font_style=> :bold}, 
                {:content=> record.number},
                {:content=> "Project Name", :font_style=> :bold}, 
                {:content=> record.remarks}
              ], [
                {:content=> "Tgl. Number", :width=> 60, :font_style=> :bold}, 
                {:content=> "#{record.date}"},
                {:content=> "PO Suppliers", :font_style=> :bold}, 
                {:content=> "#{record.po_supplier_number}"}
              ]
            ])
            pdf.table([[{:content=> "", :width=> 30}, "SO detail"]])
            so_item_c = 0
            total_amount = 0
            cost_project = 0

            record.sales_order_items.each do |item|
              item.production_order_items.each do |spp_item|
                # pdf.text "#{spp_item.as_json}"
                pdf.table([
                  [{:content=> "#", :width=> 30}, "Product name", "Product ID", "Quantity", "Unit Price"],
                  [
                    {:content=> "#{so_item_c+=1}", :width=> 30, :borders=> [:left, :right]},
                  "#{spp_item.product.name if spp_item.product.present?}", 
                  "#{spp_item.product.part_id if spp_item.product.present?}", 
                  "#{spp_item.quantity}", "#{item.unit_price}"
                ]])
                # step 2
                po_item_c = 0
                spp_item.production_order_used_prves.each do |detail|
                  # step 3
                  # pdf.text "detail qty: #{detail.production_order_detail_material.quantity}"
                  # pdf.text "production_order_used_prve_id: #{detail.id}"
                  # pdf.text "ini =>           [#{detail.id}]   production_order_detail_material_id: #{detail.production_order_detail_material_id}"
                  detail.purchase_request_item.purchase_order_supplier_items.each do |po_item| 
                    part = nil 
                    prf_number = nil 
                    prf_date = nil 
                    if po_item.purchase_request_item.present? 
                     record_item = po_item.purchase_request_item 
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
                    elsif po_item.pdm_item.present? 
                     record_item = po_item.pdm_item 
                     if record_item.present? 
                       if record_item.material.present? 
                         part = record_item.material 
                       end 
                       prf_number =  record_item.pdm.number 
                       prf_date =  record_item.pdm.date 
                     end 
                    end 
                    prf_detail = nil
                    # pdf.text "po_item_id: #{po_item.id}"
                    if po_item.material_receiving_items.present?
                      # pdf.text "material_receiving_items"
                      check_grn_items = check_grn_items(detail.production_order_detail_material_id, "material", po_item.purchase_request_item_id, detail.production_order_item_id, prf_detail, pdf, record.number, po_item.material_receiving_items)
                      total_amount = check_grn_items[:total_amount]
                      if prf_detail.blank?
                        prf_detail   = check_grn_items[:prf_detail]
                      else
                        prf_detail   += check_grn_items[:prf_detail]
                      end
                    end
                    if po_item.product_receiving_items.present?
                      # pdf.text "product_receiving_items"
                      check_grn_items = check_grn_items(detail.production_order_detail_material_id, "product", po_item.purchase_request_item_id, detail.production_order_item_id, prf_detail, pdf, record.number, po_item.product_receiving_items)
                      total_amount = check_grn_items[:total_amount]
                      
                      if prf_detail.blank?
                        prf_detail   = check_grn_items[:prf_detail]
                      else
                        prf_detail   += check_grn_items[:prf_detail]
                      end
                    end
                    if po_item.general_receiving_items.present?
                      # pdf.text "general_receiving_items"
                      check_grn_items = check_grn_items(detail.production_order_detail_material_id, "general", po_item.purchase_request_item_id, detail.production_order_item_id, prf_detail, pdf, record.number, po_item.general_receiving_items)
                      total_amount = check_grn_items[:total_amount]
                      
                      if prf_detail.blank?
                        prf_detail   = check_grn_items[:prf_detail]
                      else
                        prf_detail   += check_grn_items[:prf_detail]
                      end
                    end
                    if po_item.consumable_receiving_items.present?
                      # pdf.text "consumable_receiving_items"
                      check_grn_items = check_grn_items(detail.production_order_detail_material_id, "consumable", po_item.purchase_request_item_id, detail.production_order_item_id, prf_detail, pdf, record.number, po_item.consumable_receiving_items)
                      total_amount = check_grn_items[:total_amount]
                      
                      if prf_detail.blank?
                        prf_detail   = check_grn_items[:prf_detail]
                      else
                        prf_detail   += check_grn_items[:prf_detail]
                      end
                    end
                    if po_item.equipment_receiving_items.present?
                      # pdf.text "equipment_receiving_items"
                      check_grn_items = check_grn_items(detail.production_order_detail_material_id, "equipment", po_item.purchase_request_item_id, detail.production_order_item_id, prf_detail, pdf, record.number, po_item.equipment_receiving_items)
                      total_amount = check_grn_items[:total_amount]
                      
                      if prf_detail.blank?
                        prf_detail   = check_grn_items[:prf_detail]
                      else
                        prf_detail   += check_grn_items[:prf_detail]
                      end
                    end
                      
                    cost_project += total_amount*po_item.unit_price
                    if prf_detail.blank?
                      prf_detail = [
                        [
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "Summary SPP", :colspan=> 6}, {:content=> "#{number_with_precision(total_amount, precision: 2, delimiter: ".", separator: ",")}"}
                        ], [
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "Unit Price", :colspan=> 6}, {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}"}
                        ], [
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "Cost Project", :colspan=> 6}, {:content=> "#{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}"}
                        ]
                      ]
                    else
                      prf_detail += [
                        [
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "Summary SPP", :colspan=> 6}, {:content=> "#{number_with_precision(total_amount, precision: 2, delimiter: ".", separator: ",")}"}
                        ], [
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "Unit Price", :colspan=> 6}, {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}"}
                        ], [
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "", :width=> 30, :borders=> [:left, :right]},
                          {:content=> "Cost Project", :colspan=> 6}, {:content=> "#{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}"}
                        ]
                      ]
                    end


                    pdf.table(prf_detail) if prf_detail.present?
                    pdf.table([
                      [
                        {:content=> "", :width=> 30, :borders=> [:left, :right]}, 
                        {:content=> "", :width=> 30, :borders=> [:left, :right]}, 
                        "PO Number", "Mtrl name", "Mtrl ID", "PO Qty", "Unit Price"],
                      [
                        {:content=> " ", :width=> 30, :borders=> [:left, :right]}, 
                        {:content=> "#{po_item_c += 1}", :width=> 30, :borders=> [:left, :right]}, 
                        {:content=> "#{po_item.purchase_order_supplier.number if po_item.purchase_order_supplier.present?} - #{po_item.purchase_order_supplier.kind if po_item.purchase_order_supplier.present?}", :width=> 90}, 
                        {:content=> "#{part.name if part.present?}", :width=> 250}, 
                        {:content=> "#{part.part_id if part.present?}", :width=> 50}, 
                        {:content=> "#{number_with_precision(po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :width=> 50},
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :width=> 80}
                      ],
                    ])
                    pdf.table([
                      [{:content=> "", :width=> 30, :borders=> [:left, :right]}]
                    ])
                  end
                end
              end
            end

            pdf.table([[
              {:content=> "Cost Project #{record.number}"},
              {:content=> "#{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}"},
            ]])
            pdf.move_down 10
          end
        when 'v2'
          count_so = 0
          records.each do |record|
            so_currency = "#{record.customer.currency.name if record.customer.present? and record.customer.currency.present?}"
            po_currency = ""
            
            count_so += 1
            so_amount = summary_po_amount = summary_grn_amount = 0
            cost_project = 0
            prf_item_group = []

            logger.info "------------------ prf_item_group start"
            record.sales_order_items.each do |so_item|
              so_amount += so_item.quantity*so_item.unit_price
              so_item.production_order_items.each do |spp_item|
                prf_item_group+= spp_item.production_order_used_prves.group(:purchase_request_item_id).map { |e| e.purchase_request_item_id }
              end
            end
            logger.info "------------------ prf_item_group end"
            # pdf.text "#{prf_item_group.uniq.as_json}"
            pdf.table([
              [
                {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
                {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 5}
                
              ], [
                {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> record.number, :width=> 100}, {:content=> " ", :width=> 30},
                {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
                {:content=> record.remarks}
              ], [
                {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.date}"}, {:content=> " ", :width=> 30},
                {:content=> "PO Suppliers", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.po_supplier_number}"}
              ]
            ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
            pdf.move_down 5
            pdf.stroke_horizontal_rule
            pdf.move_down 5
            c = 0

            c_prf = 0

            pdf_header_bg = "f0f0f0"
            spp_used_by_prf = ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item_group.uniq, :status=> 'active').includes(
              purchase_request_item: [
                :purchase_request, 
                product: [:unit], material: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit], 
                  purchase_order_supplier_items: [ 
                    product_receiving_items: [
                      :product_receiving, :purchase_order_supplier_item
                    ], material_receiving_items: [
                      :material_receiving, :purchase_order_supplier_item
                    ], general_receiving_items: [
                      :general_receiving, :purchase_order_supplier_item
                    ], consumable_receiving_items: [
                      :consumable_receiving, :purchase_order_supplier_item
                    ], equipment_receiving_items: [
                      :equipment_receiving, :purchase_order_supplier_item
                    ], purchase_order_supplier: [:currency, :purchase_order_supplier_items]
                  ]
                ]
              )
            spp_used_by_prf.group(:purchase_request_item_id).each do |spp_used|
              logger.info "------------------ purchase_request_item_id #{spp_used.purchase_request_item_id} start"
              # pdf.text "  production_order_item_id: #{spp_used.production_order_item_id}; purchase_request_item_id: #{spp_used.purchase_request_item_id}; "
              sum_spp_quantity = 0
              sum_po_quantity = 0
              sum_grn_quantity = 0
              prf_quantity = spp_used.purchase_request_item.quantity
              if prf_quantity > 0
                prf_header = spp_used.purchase_request_item.purchase_request 
 
                if spp_used.purchase_request_item.product.present? 
                  part = spp_used.purchase_request_item.product 
                elsif spp_used.purchase_request_item.material.present? 
                  part = spp_used.purchase_request_item.material 
                elsif spp_used.purchase_request_item.consumable.present? 
                  part = spp_used.purchase_request_item.consumable 
                elsif spp_used.purchase_request_item.equipment.present? 
                  part = spp_used.purchase_request_item.equipment 
                elsif spp_used.purchase_request_item.general.present? 
                  part = spp_used.purchase_request_item.general 
                end
                unit_name = (part.present? ? part.unit_name : nil)
                if pdf.y.round(1) < 110
                  pdf.start_new_page
                end
                pdf.table([
                  [
                    {:content=> "#", :font_style=> :bold, :borders=> [:left, :bottom, :top], :background_color => pdf_header_bg}, 
                    {:content=> "PRF Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "Material Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "Material Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "PRF Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                  ], [
                    {:content=> "#{c_prf+=1}", :borders=> [:left, :top, :right]}, 
                    {:content=> "#{prf_header.present? ? "#{prf_header.number} #{prf_header.request_kind}" : nil}", :borders=> [:bottom]}, 
                    {:content=> "#{part.present? ? part.part_id : nil}", :borders=> [:bottom]}, 
                    {:content=> "#{part.present? ? part.name : nil}", :borders=> [:bottom]}, 
                    {:content=> "#{number_with_precision(prf_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:bottom, :right]},
                  ]
                ], :column_widths=> [20, 100, 80, 200, 80])

                c_po = 0
                if spp_used.purchase_request_item.purchase_order_supplier_items.present?
                  
                  po_amount  = 0
                  grn_amount = 0
                  pdf.table([
                    [
                      {:content=> " ", :borders=> [:left, :right]}, 
                      {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                      {:content=> "PO Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                      {:content=> "PO Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> " ", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                    ]
                  ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])

                  spp_used.purchase_request_item.purchase_order_supplier_items.each do |po_item|
                    logger.info "------------------ purchase_order_supplier_item_id #{po_item.id} start"
                    po_currency = "#{po_item.purchase_order_supplier.currency.name if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
                    pdf.table([
                      [
                        {:content=> " ", :borders=> [:left, :right] },
                        {:content=> "#{c_po+=1}", :borders=> [:left, :top]},
                        {:content=> "#{po_item.purchase_order_supplier.number}", :align=> :center},
                        {:content=> "#{number_with_precision(po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                        {:content=> "#{po_currency} #{number_with_precision(po_item.unit_price*po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]
                    ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])
                    sum_po_quantity += po_item.quantity
                    po_amount += po_item.unit_price*po_item.quantity

                    c_grn = 0
                    grn_detail = [
                      [
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                        {:content=> "GRN Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                        {:content=> "GRN Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                        {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                        {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                        {:content=> "", :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                      ]
                    ]

                    if po_item.material_receiving_items.present?
                      po_item.material_receiving_items.each do |grn_item|
                        grn_detail += [[
                          {:content=> " ", :borders=> [:left, :right] }, 
                          {:content=> " ", :borders=> [:right] }, 
                          {:content=> "#{c_grn+=1}", :borders=> [:top] },
                          {:content=> "#{grn_item.material_receiving.number}", :align=> :center}, 
                          {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "", :borders=> [:top, :bottom, :right]}
                        ]]
                        sum_grn_quantity += grn_item.quantity
                        grn_amount += grn_item.quantity*po_item.unit_price
                      end
                      pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                    end
                    if po_item.product_receiving_items.present?
                      po_item.product_receiving_items.each do |grn_item|
                        grn_detail += [[
                          {:content=> " ", :borders=> [:left, :right] }, 
                          {:content=> " ", :borders=> [:right] }, 
                          {:content=> "#{c_grn+=1}", :borders=> [:top] },
                          {:content=> "#{grn_item.product_receiving.number}", :align=> :center}, 
                          {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "", :borders=> [:top, :bottom, :right]}
                        ]]
                        sum_grn_quantity += grn_item.quantity
                        grn_amount += grn_item.quantity*po_item.unit_price
                      end
                      pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                    end
                    if po_item.consumable_receiving_items.present?
                      po_item.consumable_receiving_items.each do |grn_item|
                        grn_detail += [[
                          {:content=> " ", :borders=> [:left, :right] }, 
                          {:content=> " ", :borders=> [:right] }, 
                          {:content=> "#{c_grn+=1}", :borders=> [:top] },
                          {:content=> "#{grn_item.consumable_receiving.number}", :align=> :center}, 
                          {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "", :borders=> [:top, :bottom, :right]}
                        ]]
                        sum_grn_quantity += grn_item.quantity
                        grn_amount += grn_item.quantity*po_item.unit_price
                      end
                      pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                    end
                    if po_item.equipment_receiving_items.present?
                      po_item.equipment_receiving_items.each do |grn_item|
                        grn_detail += [[
                          {:content=> " ", :borders=> [:left, :right] }, 
                          {:content=> " ", :borders=> [:right] }, 
                          {:content=> "#{c_grn+=1}", :borders=> [:top] },
                          {:content=> "#{grn_item.equipment_receiving.number}", :align=> :center}, 
                          {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "", :borders=> [:top, :bottom, :right]}
                        ]]
                        sum_grn_quantity += grn_item.quantity
                        grn_amount += grn_item.quantity*po_item.unit_price
                      end
                      pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                    end
                    if po_item.general_receiving_items.present?
                      po_item.general_receiving_items.each do |grn_item|
                        grn_detail += [[
                          {:content=> " ", :borders=> [:left, :right] }, 
                          {:content=> " ", :borders=> [:right] }, 
                          {:content=> "#{c_grn+=1}", :borders=> [:top] },
                          {:content=> "#{grn_item.general_receiving.number}", :align=> :center}, 
                          {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "", :borders=> [:top, :bottom, :right]}
                        ]]
                        sum_grn_quantity += grn_item.quantity
                        grn_amount += grn_item.quantity*po_item.unit_price
                      end
                      pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                    end
                    
                    logger.info "------------------ purchase_order_supplier_item_id #{po_item.id} end"
                  end

                  cost_project += grn_amount
                  summary_po_amount += po_amount
                  summary_grn_amount += grn_amount
                end

                pdf.table([
                  [
                    {:content=> "PO Amount", :font_style=> :bold, :align=> :right, :background_color => pdf_header_bg}, 
                    {:content=> "#{po_currency} #{number_with_precision(po_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                    {:content=> "", :borders=> [:top, :bottom, :right]}
                  ], [
                    {:content=> "GRN Amount", :font_style=> :bold, :align=> :right, :background_color => pdf_header_bg}, 
                    {:content=> "#{po_currency} #{number_with_precision(grn_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                    {:content=> "", :borders=> [:top, :bottom, :right]}
                  ]
                ], :column_widths=> [320, 100, 60])
                pdf.move_down 5

                pdf.table([
                  [
                    {:content=> " ", :font_style=> :bold, :borders=> [:right] }, 
                    {:content=> "SPP Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "Product Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "Product Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "SPP Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                  ]
                ], :column_widths=> [20, 100, 80, 200, 80])
                spp_used_by_prf.where(:purchase_request_item_id=> spp_used.purchase_request_item_id).each do |spp_used_from_item|
                  spp_header = spp_used_from_item.production_order_item.production_order
                  spp_item = spp_used_from_item.production_order_item

                  pdf.table([
                    [
                      {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                      {:content=> "#{spp_header.present? ? spp_header.number : nil}"}, 
                      {:content=> "#{spp_item.product.present? ? spp_item.product.part_id : nil}"}, 
                      {:content=> "#{spp_item.product.present? ? spp_item.product.name : nil}"}, 
                      {:content=> "#{number_with_precision(spp_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                    ]
                  ], :column_widths=> [20, 100, 80, 200, 80])
                  sum_spp_quantity += spp_item.quantity
                end
                pdf.move_down 10
                pdf.table([
                  [
                    {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                    {:content=> "Summary SPP Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                    {:content=> "PRF Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                    {:content=> "Summary PO Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                    {:content=> "Summary GRN Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  ], [
                    {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                    {:content=> "#{number_with_precision(sum_spp_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                    {:content=> "#{number_with_precision(prf_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                    {:content=> "#{number_with_precision(sum_po_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                    {:content=> "#{number_with_precision(sum_grn_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                  ]
                ], :column_widths=> [20, 80, 80, 80, 80])


                pdf.move_down 10
              end
              logger.info "------------------ purchase_request_item_id #{spp_used.purchase_request_item_id} end"
            end
            pdf.move_down 10

            # if cost_project > 0
              cost_project = (so_amount - summary_grn_amount)
              pdf.table([
                [
                  {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
                  {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 9}
                  
                ], [
                  {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
                  {:content=> record.number, :width=> 100}, {:content=> " ", :width=> 30},
                  {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
                  {:content=> record.remarks, :colspan=> 5, :width=> 250}
                ], [
                  {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
                  {:content=> "#{record.date}"}
                ] 
              ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})

              pdf.move_down 20
              pdf.table([
                [
                  {:content=> "SO Amount", :font_style=> :bold}, {:content=> ":"},
                  {:content=> "#{so_currency} #{number_with_precision(so_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                ], [
                  {:content=> "PO Amount", :font_style=> :bold}, {:content=> ":"},
                  {:content=> "#{po_currency} #{number_with_precision(summary_po_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                ], [
                  {:content=> "GRN Amount", :font_style=> :bold}, {:content=> ":"},
                  {:content=> "#{po_currency} #{number_with_precision(summary_grn_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                ], [
                  {:content=> "Cost Project", :font_style=> :bold}, {:content=> ":"},
                  {:content=> "#{po_currency} #{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                ] 
              ], :column_widths=> [80, 10, 140], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
              pdf.move_down 20

              pdf.text "note: *Cost Project = SO Amount - GRN Amount"
              pdf.start_new_page
            # else
            #   pdf.text ""
            # end
            logger.info "------------------#{record.number}"
          end
          pdf.text "Total SO: #{count_so}"
          pdf.number_pages "Page <page> of <total>", :size => 9, :at => [20, 10]
          pdf.number_pages "Printed At: #{DateTime.now().strftime("%Y-%m-%d %H:%M:%S")}", :size => 9, :at => [450, 10]
        when 'v3'
          count_so = 0
          @records.each do |record|
            so_currency = "#{record.customer.currency.name if record.customer.present? and record.customer.currency.present?}"
            po_currency = ""
            pdf.table([
              [
                {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
                {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 5}
                
              ], [
                {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.number, :width=> 100}, {:content=> " ", :width=> 30},
                {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.remarks}
              ], [
                {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.date}"}, {:content=> " ", :width=> 30},
                {:content=> "PO Suppliers", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.po_supplier_number}"}
              ]
            ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
            pdf.move_down 5
            pdf.stroke_horizontal_rule
            pdf.move_down 5

            count_so += 1
            so_amount = summary_po_amount = summary_grn_amount = 0
            cost_project = 0

            pdf_header_bg = "f0f0f0"
            c_prf = 0

            record.cost_project_finance_prf_items.each do |prf_item|
              prf_header = prf_item.purchase_request
              prf_quantity = prf_item.purchase_request_item.quantity
              sum_spp_quantity = 0
              sum_po_quantity = 0
              sum_grn_quantity = 0

              if prf_item.purchase_request_item.product.present? 
                part = prf_item.purchase_request_item.product 
              elsif prf_item.purchase_request_item.material.present? 
                part = prf_item.purchase_request_item.material 
              elsif prf_item.purchase_request_item.consumable.present? 
                part = prf_item.purchase_request_item.consumable 
              elsif prf_item.purchase_request_item.equipment.present? 
                part = prf_item.purchase_request_item.equipment 
              elsif prf_item.purchase_request_item.general.present? 
                part = prf_item.purchase_request_item.general 
              end
              unit_name = (part.present? ? part.unit_name : nil)

              pdf.table([
                [
                  {:content=> "#", :font_style=> :bold, :borders=> [:left, :bottom, :top], :background_color => pdf_header_bg}, 
                  {:content=> "PRF Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Material Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Material Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "PRF Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                ], [
                  {:content=> "#{c_prf+=1}", :borders=> [:left, :top, :right]}, 
                  {:content=> "#{prf_header.present? ? "#{prf_header.number} #{prf_header.request_kind}" : nil}", :borders=> [:bottom]}, 
                  {:content=> "#{part.present? ? part.part_id : nil}", :borders=> [:bottom]}, 
                  {:content=> "#{part.present? ? part.name : nil}", :borders=> [:bottom]}, 
                  {:content=> "#{number_with_precision(prf_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:bottom, :right]},
                ]
              ], :column_widths=> [20, 100, 80, 200, 80])

              c_po = 0
              if prf_item.purchase_request_item.purchase_order_supplier_items.present?
                
                po_amount  = 0
                grn_amount = 0
                pdf.table([
                  [
                    {:content=> " ", :borders=> [:left, :right]}, 
                    {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "PO Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                    {:content=> "PO Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                    {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                    {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                    {:content=> " ", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                  ]
                ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])

                prf_item.purchase_request_item.purchase_order_supplier_items.each do |po_item|
                  logger.info "------------------ purchase_order_supplier_item_id #{po_item.id} start"
                  po_currency = "#{po_item.purchase_order_supplier.currency.name if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
                  pdf.table([
                    [
                      {:content=> " ", :borders=> [:left, :right] },
                      {:content=> "#{c_po+=1}", :borders=> [:left, :top]},
                      {:content=> "#{po_item.purchase_order_supplier.number}", :align=> :center},
                      {:content=> "#{number_with_precision(po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                      {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                      {:content=> "#{po_currency} #{number_with_precision(po_item.unit_price*po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                      {:content=> "", :borders=> [:top, :bottom, :right]}
                    ]
                  ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])
                  sum_po_quantity += po_item.quantity
                  po_amount += po_item.unit_price*po_item.quantity

                  c_grn = 0
                  grn_detail = [
                    [
                      {:content=> " ", :borders=> [:left, :right] }, 
                      {:content=> " ", :borders=> [:left, :right] }, 
                      {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                      {:content=> "GRN Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                      {:content=> "GRN Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "", :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                    ]
                  ]

                  if po_item.material_receiving_items.present?
                    po_item.material_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.material_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.product_receiving_items.present?
                    po_item.product_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.product_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.consumable_receiving_items.present?
                    po_item.consumable_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.consumable_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.equipment_receiving_items.present?
                    po_item.equipment_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.equipment_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.general_receiving_items.present?
                    po_item.general_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.general_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  
                  logger.info "------------------ purchase_order_supplier_item_id #{po_item.id} end"
                end

                cost_project += grn_amount
                summary_po_amount += po_amount
                summary_grn_amount += grn_amount
              end


              pdf.table([
                [
                  {:content=> "PO Amount", :font_style=> :bold, :align=> :right, :background_color => pdf_header_bg}, 
                  {:content=> "#{po_currency} #{number_with_precision(po_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                  {:content=> "", :borders=> [:top, :bottom, :right]}
                ], [
                  {:content=> "GRN Amount", :font_style=> :bold, :align=> :right, :background_color => pdf_header_bg}, 
                  {:content=> "#{po_currency} #{number_with_precision(grn_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                  {:content=> "", :borders=> [:top, :bottom, :right]}
                ]
              ], :column_widths=> [320, 100, 60])
              pdf.move_down 5

              pdf.table([
                [
                  {:content=> " ", :font_style=> :bold, :borders=> [:right] }, 
                  {:content=> "SPP Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Product Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Product Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "SPP Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                ]
              ], :column_widths=> [20, 100, 80, 200, 80])
              spp_by_prf = ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item.purchase_request_item).includes(production_order_item: [:production_order, :product])
              spp_by_prf.each do |spp_used_from_item|
                spp_header = spp_used_from_item.production_order_item.production_order
                spp_item = spp_used_from_item.production_order_item

                pdf.table([
                  [
                    {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                    {:content=> "#{spp_header.present? ? spp_header.number : nil}"}, 
                    {:content=> "#{spp_item.product.present? ? spp_item.product.part_id : nil}"}, 
                    {:content=> "#{spp_item.product.present? ? spp_item.product.name : nil}"}, 
                    {:content=> "#{number_with_precision(spp_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                  ]
                ], :column_widths=> [20, 100, 80, 200, 80])
                sum_spp_quantity += spp_item.quantity
              end
              pdf.move_down 10
              pdf.table([
                [
                  {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                  {:content=> "Summary SPP Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  {:content=> "PRF Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  {:content=> "Summary PO Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  {:content=> "Summary GRN Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                ], [
                  {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                  {:content=> "#{number_with_precision(sum_spp_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                  {:content=> "#{number_with_precision(prf_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                  {:content=> "#{number_with_precision(sum_po_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                  {:content=> "#{number_with_precision(sum_grn_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                ]
              ], :column_widths=> [20, 80, 80, 80, 80])


              pdf.move_down 10
            end
            pdf.move_down 10

            cost_project = (record.amount_so - record.amount_grn)
            pdf.table([
              [
                {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
                {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 9}
                
              ], [
                {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.number, :width=> 100}, {:content=> " ", :width=> 30},
                {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.remarks, :colspan=> 5, :width=> 250}
              ], [
                {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.date}"}
              ] 
            ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})

            pdf.move_down 20
            pdf.table([
              [
                {:content=> "SO Amount", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{so_currency} #{number_with_precision(record.amount_so, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
              ], [
                {:content=> "PO Amount", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{po_currency} #{number_with_precision(record.amount_po, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
              ], [
                {:content=> "GRN Amount", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{po_currency} #{number_with_precision(record.amount_grn, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
              ], [
                {:content=> "Cost Project", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{po_currency} #{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
              ] 
            ], :column_widths=> [80, 10, 140], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
            pdf.move_down 20

            pdf.text "note: *Cost Project = SO Amount - GRN Amount"
            pdf.start_new_page
          end
        else
          # 2022-04-04
          count_so = 0
          # @records.where(:sales_orders=> {:number=> 'PP/PIF/23/XI/2021'}).each do |record|
          @records.each do |record|
            so_currency = "#{record.customer.currency.name if record.customer.present? and record.customer.currency.present?}"
            po_currency = ""
            pdf.table([
              [
                {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
                {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 5}
                
              ], [
                {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.number, :width=> 100}, {:content=> " ", :width=> 30},
                {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.remarks}
              ], [
                {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.date}"}, {:content=> " ", :width=> 30},
                {:content=> "PO Suppliers", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.po_supplier_number}"}
              ]
            ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
            pdf.move_down 5
            pdf.stroke_horizontal_rule
            pdf.move_down 5

            count_so += 1
            so_amount = summary_po_amount = summary_grn_amount = 0
            cost_project = 0

            pdf_header_bg = "f0f0f0"
            c_prf = 0

            record.cost_project_finance_prf_items.each do |prf_item|
              pdm_header = prf_item.pdm
              pdm_quantity = prf_item.pdm_item.quantity if prf_item.pdm_item.present?
              prf_header = prf_item.purchase_request
              prf_quantity = prf_item.purchase_request_item.quantity
              sum_prf_quantity = prf_quantity
              sum_prf_quantity += pdm_quantity if pdm_quantity.present?

              sum_spp_quantity = 0
              sum_po_quantity = 0
              sum_grn_quantity = 0

              po_amount  = 0
              grn_amount = 0

              if prf_item.purchase_request_item.product.present? 
                part = prf_item.purchase_request_item.product 
              elsif prf_item.purchase_request_item.material.present? 
                part = prf_item.purchase_request_item.material 
              elsif prf_item.purchase_request_item.consumable.present? 
                part = prf_item.purchase_request_item.consumable 
              elsif prf_item.purchase_request_item.equipment.present? 
                part = prf_item.purchase_request_item.equipment 
              elsif prf_item.purchase_request_item.general.present? 
                part = prf_item.purchase_request_item.general 
              end
              unit_name = (part.present? ? part.unit_name : nil)

              # ------------------------ PRF
              prf_content = [
                [
                  {:content=> "#", :font_style=> :bold, :borders=> [:left, :bottom, :top], :background_color => pdf_header_bg}, 
                  {:content=> "PRF Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Material Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Material Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "PRF Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                ], [
                  {:content=> "#{c_prf+=1}", :borders=> [:left, :top, :right]}, 
                  {:content=> "#{prf_header.present? ? "#{prf_header.number} #{prf_header.request_kind}" : nil}", :borders=> [:bottom]}, 
                  {:content=> "#{part.present? ? part.part_id : nil}", :borders=> [:bottom]}, 
                  {:content=> "#{part.present? ? part.name : nil}", :borders=> [:bottom]}, 
                  {:content=> "#{number_with_precision(prf_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:bottom, :right]},
                ]
              ]

              pdf.table(prf_content, :column_widths=> [20, 100, 80, 200, 80])

              # PO by PRF
              c_po = 0
              if prf_item.purchase_request_item.purchase_order_supplier_items.present?
                pdf.table([
                  [
                    {:content=> " ", :borders=> [:left, :right]}, 
                    {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "PO Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                    {:content=> "PO Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                    {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                    {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                    {:content=> " ", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                  ]
                ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])

                prf_item.purchase_request_item.purchase_order_supplier_items.each do |po_item|
                  logger.info "------------------ purchase_order_supplier_item_id #{po_item.id} start"
                  po_currency = "#{po_item.purchase_order_supplier.currency.name if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
                  pdf.table([
                    [
                      {:content=> " ", :borders=> [:left, :right] },
                      {:content=> "#{c_po+=1}", :borders=> [:left, :top]},
                      {:content=> "#{po_item.purchase_order_supplier.number}", :align=> :center},
                      {:content=> "#{number_with_precision(po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                      {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                      {:content=> "#{po_currency} #{number_with_precision(po_item.unit_price*po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                      {:content=> "", :borders=> [:top, :bottom, :right]}
                    ]
                  ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])
                  sum_po_quantity += po_item.quantity
                  po_amount += po_item.unit_price*po_item.quantity

                  # GRN by PO
                  c_grn = 0
                  grn_detail = [
                    [
                      {:content=> " ", :borders=> [:left, :right] }, 
                      {:content=> " ", :borders=> [:left, :right] }, 
                      {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                      {:content=> "GRN Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                      {:content=> "GRN Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "", :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                    ]
                  ]

                  if po_item.material_receiving_items.present?
                    po_item.material_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.material_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.product_receiving_items.present?
                    po_item.product_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.product_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.consumable_receiving_items.present?
                    po_item.consumable_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.consumable_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.equipment_receiving_items.present?
                    po_item.equipment_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.equipment_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  if po_item.general_receiving_items.present?
                    po_item.general_receiving_items.each do |grn_item|
                      grn_detail += [[
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:right] }, 
                        {:content=> "#{c_grn+=1}", :borders=> [:top] },
                        {:content=> "#{grn_item.general_receiving.number}", :align=> :center}, 
                        {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]]
                      sum_grn_quantity += grn_item.quantity
                      grn_amount += grn_item.quantity*po_item.unit_price
                    end
                    pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                  end
                  
                  logger.info "------------------ purchase_order_supplier_item_id #{po_item.id} end"
                end

              end
              # ------------------------ PRF

              # ------------------------ PDM
              if pdm_quantity.present?
                prf_content = [
                  [
                    {:content=> "#", :font_style=> :bold, :borders=> [:left, :bottom, :top], :background_color => pdf_header_bg}, 
                    {:content=> "PDM Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "Material Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "Material Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                    {:content=> "PDM Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                  ], [
                    {:content=> "#{c_prf+=1}", :borders=> [:left, :top, :right]}, 
                    {:content=> "#{pdm_header.present? ? "#{pdm_header.number}" : nil}", :borders=> [:bottom]}, 
                    {:content=> "#{part.present? ? part.part_id : nil}", :borders=> [:bottom]}, 
                    {:content=> "#{part.present? ? part.name : nil}", :borders=> [:bottom]}, 
                    {:content=> "#{number_with_precision(pdm_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:bottom, :right]},
                  ] 
                ]
                pdf.table(prf_content, :column_widths=> [20, 100, 80, 200, 80])

                # PO by PDM
                c_po = 0
                if prf_item.pdm_item.purchase_order_supplier_items.present?
                  pdf.table([
                    [
                      {:content=> " ", :borders=> [:left, :right]}, 
                      {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                      {:content=> "PO Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                      {:content=> "PO Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                      {:content=> " ", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                    ]
                  ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])

                  prf_item.pdm_item.purchase_order_supplier_items.each do |po_item|
                    po_currency = "#{po_item.purchase_order_supplier.currency.name if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
                    pdf.table([
                      [
                        {:content=> " ", :borders=> [:left, :right] },
                        {:content=> "#{c_po+=1}", :borders=> [:left, :top]},
                        {:content=> "#{po_item.purchase_order_supplier.number}", :align=> :center},
                        {:content=> "#{number_with_precision(po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                        {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                        {:content=> "#{po_currency} #{number_with_precision(po_item.unit_price*po_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                        {:content=> "", :borders=> [:top, :bottom, :right]}
                      ]
                    ], :column_widths=> [20, 20, 120, 80, 80, 100, 60])
                    sum_po_quantity += po_item.quantity
                    po_amount += po_item.unit_price*po_item.quantity

                    # GRN by PO
                    c_grn = 0
                    grn_detail = [
                      [
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> " ", :borders=> [:left, :right] }, 
                        {:content=> "#", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                        {:content=> "GRN Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center}, 
                        {:content=> "GRN Qty", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                        {:content=> "PO Unit Price", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                        {:content=> "Sub Total", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg, :align=> :center},
                        {:content=> "", :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                      ]
                    ]

                    if po_item.material_receiving_items.present?
                      po_item.material_receiving_items.each do |grn_item|
                        grn_detail += [[
                          {:content=> " ", :borders=> [:left, :right] }, 
                          {:content=> " ", :borders=> [:right] }, 
                          {:content=> "#{c_grn+=1}", :borders=> [:top] },
                          {:content=> "#{grn_item.material_receiving.number}", :align=> :center}, 
                          {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{number_with_precision(po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "#{po_currency} #{number_with_precision(grn_item.quantity*po_item.unit_price, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom] },
                          {:content=> "", :borders=> [:top, :bottom, :right]}
                        ]]
                        sum_grn_quantity += grn_item.quantity
                        grn_amount += grn_item.quantity*po_item.unit_price
                      end
                      pdf.table(grn_detail, :column_widths=> [20, 20, 20, 100, 80, 80, 100, 60])
                    end
                  end

                end
              end
              # ------------------------ PDM

              cost_project += grn_amount
              summary_po_amount += po_amount
              summary_grn_amount += grn_amount

              pdf.table([
                [
                  {:content=> "PO Amount", :font_style=> :bold, :align=> :right, :background_color => pdf_header_bg}, 
                  {:content=> "#{po_currency} #{number_with_precision(po_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                  {:content=> "", :borders=> [:top, :bottom, :right]}
                ], [
                  {:content=> "GRN Amount", :font_style=> :bold, :align=> :right, :background_color => pdf_header_bg}, 
                  {:content=> "#{po_currency} #{number_with_precision(grn_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right, :borders=> [:top, :bottom]},
                  {:content=> "", :borders=> [:top, :bottom, :right]}
                ]
              ], :column_widths=> [320, 100, 60])
              pdf.move_down 5

              pdf.table([
                [
                  {:content=> " ", :font_style=> :bold, :borders=> [:right] }, 
                  {:content=> "SPP Number", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Product Part ID", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "Product Name", :font_style=> :bold, :borders=> [:top, :bottom], :background_color => pdf_header_bg}, 
                  {:content=> "SPP Qty", :font_style=> :bold, :borders=> [:top, :bottom, :right], :background_color => pdf_header_bg}
                ]
              ], :column_widths=> [20, 100, 80, 200, 80])
              spp_by_prf = ProductionOrderUsedPrf.where(:purchase_request_item_id=> prf_item.purchase_request_item).includes(production_order_item: [:production_order, :product])
              spp_by_prf.each do |spp_used_from_item|
                spp_header = spp_used_from_item.production_order_item.production_order
                spp_item = spp_used_from_item.production_order_item

                pdf.table([
                  [
                    {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                    {:content=> "#{spp_header.present? ? spp_header.number : nil}"}, 
                    {:content=> "#{spp_item.product.present? ? spp_item.product.part_id : nil}"}, 
                    {:content=> "#{spp_item.product.present? ? spp_item.product.name : nil}"}, 
                    {:content=> "#{number_with_precision(spp_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                  ]
                ], :column_widths=> [20, 100, 80, 200, 80])
                sum_spp_quantity += spp_item.quantity
              end
              pdf.move_down 10
              pdf.table([
                [
                  {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                  {:content=> "Summary SPP Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  {:content=> "PRF Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  {:content=> "Summary PO Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                  {:content=> "Summary GRN Qty", :font_style=> :bold, :background_color => pdf_header_bg}, 
                ], [
                  {:content=> " ", :font_style=> :bold, :borders=> [:right]}, 
                  {:content=> "#{number_with_precision(sum_spp_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                  {:content=> "#{number_with_precision(sum_prf_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                  {:content=> "#{number_with_precision(sum_po_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
                  {:content=> "#{number_with_precision(sum_grn_quantity, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
                ]
              ], :column_widths=> [20, 80, 80, 80, 80])
              pdf.move_down 10
            end
            pdf.move_down 10

            cost_project = (record.amount_so - record.amount_grn)
            pdf.table([
              [
                {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
                {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 9}
                
              ], [
                {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.number, :width=> 100}, {:content=> " ", :width=> 30},
                {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
                {:content=> record.sales_order.remarks, :colspan=> 5, :width=> 250}
              ], [
                {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{record.date}"}
              ] 
            ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})

            pdf.move_down 20
            pdf.table([
              [
                {:content=> "SO Amount", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{so_currency} #{number_with_precision(record.amount_so, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
              ], [
                {:content=> "PO Amount", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{po_currency} #{number_with_precision(record.amount_po, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
              ], [
                {:content=> "GRN Amount", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{po_currency} #{number_with_precision(record.amount_grn, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
              ], [
                {:content=> "Cost Project", :font_style=> :bold}, {:content=> ":"},
                {:content=> "#{po_currency} #{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
              ] 
            ], :column_widths=> [80, 10, 140], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
            pdf.move_down 20
            pdf.text "PO AMount: #{number_with_precision(summary_po_amount, precision: 2, delimiter: ".", separator: ",")}"
            pdf.text "GRN AMount: #{number_with_precision(summary_grn_amount, precision: 2, delimiter: ".", separator: ",")}"
            pdf.text "note: *Cost Project = SO Amount - GRN Amount"
            pdf.start_new_page
          end
        end
        send_data pdf.render, :type => "application/pdf", :disposition => "inline", :filename => "#{params[:controller].humanize}.pdf"
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cost_project_finance
    end

    def set_instance_variable      
      @option_filters = [['SO Number','sales_order_id'],['Project Name','so_project_name'],['Customer','customer_id']] 


      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      # @sales_orders = SalesOrder.where(:company_profile_id=> current_user.company_profile_id)
      # .where("sales_orders.date between ? and ?", session[:date_begin], session[:date_end])
      # .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, customer:[:currency])
      # .includes(sales_order_items:[ production_order_items: [production_order_used_prves: [purchase_request_item: [purchase_order_supplier_items:[ product_receiving_items: [:product_receiving, :purchase_order_supplier_item], material_receiving_items: [:material_receiving, :purchase_order_supplier_item], purchase_order_supplier: [:currency, :purchase_order_supplier_items]]]]]])

      @records = CostProjectFinance.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end])
      .includes(:sales_order, customer: [:currency], 
        cost_project_finance_po_items: [:purchase_order_supplier],
        cost_project_finance_prf_items: [
          purchase_request_item: [
            product: [:unit], 
            material: [:unit], 
            consumable: [:unit],
            equipment: [:unit], 
            general: [:unit],
            purchase_order_supplier_items: [
              purchase_order_supplier: [:currency],
              material_receiving_items: [:material_receiving],
              product_receiving_items: [:product_receiving],
              general_receiving_items: [:general_receiving],
              equipment_receiving_items: [:equipment_receiving],
              consumable_receiving_items: [:consumable_receiving]
            ]
          ]
        ])
      .order("cost_project_finances.date asc")
    end


  def check_grn_items(spp_detail_material_id, kind, prf_item_id, spp_item_id, prf_detail, pdf, my_so_number, grn_items)
    if prf_detail.blank?
      logger.info "BLANK NIH"
      prf_detail = [
          [
            {:content=> "", :width=> 30, :borders=> [:left, :right]},
            {:content=> "#", :width=> 30},
            {:content=> "GRN Number "},{:content=> "PRF Number "}, {:content=> "(A) SPP Qty"}, 
            {:content=> "(B) Sum SPP Qty"}, {:content=> "(C) GRN Qty"}, {:content=> "A / B"}, 
            {:content=> "A / B * C"}
          ]
        ] 
    else
      prf_detail = [[]]
    end
      
    # puts "total_amount: #{total_amount}"
    # pdf.text "detail id: #{detail.id}"

    total_amount = 0
    grn_items.where(:status=> 'active').each do | grn_item| 
      # pdf.text "grn_item_id: #{grn_item.id}"
      # pdf.text "grn_item_id: #{grn_item.id}"
      # # pdf.text "spp_detail_material_id: #{spp_detail_material_id}"
      # pdf.text "po_item_id: #{po_item_id}"
      # pdf.text "spp_item_id: #{spp_item_id}"
      # pdf.text "prf_item_id: #{prf_item_id}"
      # pdf.text "#{grn_item.as_json}"
      # puts "    #{grn_item.material_receiving.number} => quantity: #{grn_item.quantity}; GRN Price: #{grn_item.quantity * po_item.unit_price}"
      sum_spp_quantity = 0
      grn_item.purchase_order_supplier_item.purchase_request_item.production_order_used_prves.where(:production_order_item_id=> spp_item_id, :status=> 'active').each do |detail_spp_by_prf|
        spp_quantity = (detail_spp_by_prf.production_order_detail_material.present? ? detail_spp_by_prf.production_order_detail_material.quantity : 0)
        sum_spp_quantity += spp_quantity
        # pdf.text "production_order_detail_material_id: #{detail_spp_by_prf.production_order_detail_material_id} => qty: #{spp_quantity}"
      end
      
      po_number = grn_item.purchase_order_supplier_item.purchase_order_supplier.number

      grn_item.purchase_order_supplier_item.purchase_request_item.production_order_used_prves.where(:production_order_item_id=> spp_item_id, :purchase_request_item_id=> prf_item_id, :status=> 'active').each do |detail_spp_by_prf|
        # pdf.text "production_order_used_prve_id: #{detail_id}"
        # pdf.text "detail_spp_by_prf: #{detail_spp_by_prf.production_order_detail_material.as_json}"
        so_number = detail_spp_by_prf.production_order_item.sales_order_item.sales_order.number
        
        prf_number = detail_spp_by_prf.purchase_request_item.purchase_request.number
        prf_kind   = detail_spp_by_prf.purchase_request_item.purchase_request.request_kind
        prf_quantity = detail_spp_by_prf.purchase_request_item.quantity
        # pdf.text "production_order_detail_material: #{detail_spp_by_prf.production_order_detail_material_id}"
        spp_quantity = (detail_spp_by_prf.production_order_detail_material.present? ? detail_spp_by_prf.production_order_detail_material.quantity : 0)
        grn_number = grn_item.try("#{kind}_receiving")&.number
        prf_item = detail_spp_by_prf.purchase_request_item
        part = nil 
        prf_number = nil 
        prf_date = nil 
        if prf_item.present? 
          if prf_item.product.present? 
           part = prf_item.product 
          elsif prf_item.material.present? 
           part = prf_item.material 
          elsif prf_item.consumable.present? 
           part = prf_item.consumable 
          elsif prf_item.equipment.present? 
           part = prf_item.equipment 
          elsif prf_item.general.present? 
           part = prf_item.general 
          end 
        end 
        unit_name = (part.present? ? part.unit_name : nil)
        prf_number =  prf_item.purchase_request.number 
        prf_date =  prf_item.purchase_request.date 
        

        # number << so_number
        if spp_quantity > 0
          percent_by_spp_qty = spp_quantity/sum_spp_quantity
          result1 = percent_by_spp_qty*grn_item.quantity

          if so_number == my_so_number
            # pdf.text ":production_order_item_id=> #{spp_item_id}, :purchase_request_item_id=> #{prf_item_id}"
            prf_detail += [
              [
                {:content=> " ", :borders=> [:left, :right]}, 
                {:content=> " ", :borders=> [:left, :right]}, 
                {:content=> "#{grn_number}", :width=> 90}, 
                {:content=> "#{prf_number}", :width=> 90}, 
                {:content=> "#{number_with_precision(spp_quantity, precision: 2, delimiter: ".", separator: ",")}", :width=> 70},
                {:content=> "#{number_with_precision(sum_spp_quantity, precision: 2, delimiter: ".", separator: ",")}", :width=> 70},
                {:content=> "#{number_with_precision(grn_item.quantity, precision: 2, delimiter: ".", separator: ",")}", :width=> 70},
                {:content=> "#{number_with_precision(percent_by_spp_qty, precision: 2, delimiter: ".", separator: ",")} %", :width=> 70},
                {:content=> "#{number_with_precision(result1, precision: 2, delimiter: ".", separator: ",")}", :width=> 70}
              ],
            ]

            total_amount += percent_by_spp_qty*grn_item.quantity 
            puts " #{po_number} | #{prf_number} => #{percent_by_spp_qty}*#{grn_item.quantity} => #{percent_by_spp_qty*grn_item.quantity } => #{total_amount}"
          else
            puts "---- > #{so_number} | #{po_number} | #{prf_number}"
          end
        end
      end
    end

    return {:total_amount=> total_amount, :prf_detail=> prf_detail}
  end
end
