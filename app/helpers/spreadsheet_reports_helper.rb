module SpreadsheetReportsHelper

  def account_name(user_id)
    account = User.find_by(:id=> user_id)
    if account.present?
      result = account.first_name 
    else
      result = nil
    end
    return result
  end

  def template_report(controller_name, user_id, kind)
    if controller_name == 'accounts'
      permission_base_link = 'users' 
    else
      permission_base_link = controller_name
    end

    link_param = (params[:q].present? ? "?q=#{params[:q]}" : nil)
    link_param += "&q1=#{params[:q1]}" if params[:q1].present?
    link_param += "&q2=#{params[:q2]}" if params[:q2].present?
    link_param += "&tbl_kind=#{params[:tbl_kind]}" if params[:tbl_kind].present?

    my_path  = "/#{permission_base_link}#{link_param}"

    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : session[:date_begin])
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : session[:date_end])

    p = Axlsx::Package.new
    wb = p.workbook

    case controller_name
    when "payment_suppliers","material_check_sheets","material_additionals","material_returns","employee_schedules","employee_overtimes","employee_presences","working_hour_summaries","template_banks", "customer_ar_summaries","proforma_invoice_customers","outstanding_pdms","outstanding_purchase_order_suppliers", "outstanding_purchase_requests", "voucher_payments","sterilization_product_receivings","voucher_payment_receivings","list_internal_bank_accounts","list_external_bank_accounts","employee_absences","invoice_customers","cost_project_finances","purchase_requests","general_receivings","product_receivings","material_receivings","material_outgoings","invoice_supplier_receivings", "purchase_order_suppliers","employees", "shop_floor_orders", "shop_floor_order_sterilizations", "supplier_ap_recaps", "supplier_ap_summaries", "bill_of_materials","delivery_orders","temporary_inventories","inventories", "sales_orders", "production_orders", "pdms", "employee_contracts", "production_order_material_costs","employee_leaves",'payment_request_suppliers','routine_cost_payments','cash_submissions','cash_settlements','payment_customers'
      case controller_name
      when "template_banks"
        filename = "Template Bank"
        case params[:view_kind]
        when "header"
          # 20220324
          records = TemplateBank.where(:company_profile_id=> current_user.company_profile_id)
          .includes(:list_internal_bank_account, :template_bank_items).where(:template_bank_items=> {:status=> 'active'}).order("date asc")
          kind      = filename
          file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
          wb.add_worksheet(name: kind) do |sheet|
            c = 1
            sheet.add_row [kind]
            sheet.add_row ["No.","Judul Template","Nomor Rekening","Tanggal Transfer","Count Record","Total Amount","Status Approve","Status Paid"]
            records.each do |record|
              sheet.add_row [
                c,
                record.number,
                (record.list_internal_bank_account.number_account if record.list_internal_bank_account.present?),
                record.date,
                record.template_bank_items.count,
                number_with_precision(record.grand_total, precision: 2, delimiter: ".", separator: ","),
                record.status,
                "#{record.paid_by.present? ? "Paid" : "Unpaid"}"
                ], :types => [:string, :string, :string, :string, :string, :string, :string, :string]
              c+=1
            end
          end
        when "item"
          items = TemplateBankItem.where(:status=> 'active')
          .includes(:template_bank).where(:template_banks => {:company_profile_id => current_user.company_profile_id })
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Judul Template", "Nomor Rekening", "Tanggal Transfer","Payment Number","Total Amount","Status Approve","Status Paid"]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              content_row = [c+=1, 
                item.template_bank.number, 
                item.template_bank.list_internal_bank_account.number_account, 
                item.template_bank.date, 
                (item.try(:payment_supplier).present? ? item.payment_supplier.number : (item.try(:voucher_payment).present? ? item.voucher_payment.number : nil)), 
                number_with_precision(item.template_bank.grand_total, precision: 2, delimiter: ".", separator: ","), 
                item.template_bank.status, 
                "#{item.template_bank.paid_by.present? ? "Paid" : "Unpaid"}"
               ]
              sheet.add_row content_row
            end
          end
        else
          header = TemplateBank.find_by(:id=> params[:id], :company_profile_id=> current_user.company_profile_id)
          case header.status
          when 'approved3','canceled3','approved2','paid','unpaid'
            sheet_name = "Template Bank"
            wb.add_worksheet(name: "Template Bank Item") do |sheet|
              c = 1
              sheet.add_row [ '', 'Debited Account','Value Date','Transfer By','Total Amount','Total AMT (Formated)']
              sheet.add_row [ '', "#{header.list_internal_bank_account.number_account if header.list_internal_bank_account.present?}", header.date,'SKN', "#{number_with_precision(header.grand_total, precision: 2)}", "#{number_with_precision(header.grand_total, precision: 2, delimiter: ',', separator: ',')}"]
              sheet.add_row [""]

              sheet.add_row ["Flag","Credit Account No","Credit Account Name","Transfer Amount","Service","Beneficiary Bank Code",
                              "Beneficiary Bank Name","Beneficiary Address 1","Benerficiary Address 2","Beneficiary Address 3","Benerficiary Type", 
                              "Res/Non-Res","Citizenship Code","Notification Email","Email Address","Remarks 1","Remarks 2","Remarks 3","Charge Instruction"]

              items = TemplateBankItem.where(:template_bank_id=> header.id, :status=> 'active')
              .includes(supplier_bank: [:dom_bank, :country_code], payment_supplier: [payment_supplier_items: [:invoice_supplier]]).order('payment_suppliers.grandtotal desc')

              items.each do |item|
                if item.payment_supplier
                  supplier         = item.supplier_bank.supplier if item.supplier_bank.present?
                  supplier_address = "#{supplier.address if supplier.present?}"
                  supplier_contact = "#{supplier.pic if supplier.present?}"
                  supplier_bank    = item.supplier_bank

                  invoice_selected = item.payment_supplier.payment_supplier_items.map { |e| e.invoice_supplier.number if e.invoice_supplier.present? }.uniq
                  payment_number   = (supplier_bank.account_number if supplier_bank.present?)
                  payment_account_holder =(supplier_bank.account_holder if supplier_bank.present?)
                  grandtotal        = item.payment_supplier.grandtotal
                  dom_bank_skn_code = (supplier_bank.dom_bank.skn_code if supplier_bank.present? and supplier_bank.dom_bank.present?)
                  supplier_bank_name = (supplier_bank.name if supplier_bank.present?)
                  supplier_address1 = supplier_address.at(0..49)
                  supplier_address2 = supplier_address.at(50..99)
                  supplier_address3 = supplier_address.at(100..149)
                  supplier_bank_receiver_type = if (supplier_bank.receiver_type if supplier_bank.present?) == 'Individual / Perorangan'
                                                  "1 - #{supplier_bank.receiver_type if supplier_bank.present?}"
                                                elsif (supplier_bank.receiver_type if supplier_bank.present?) == 'Perushaan / Company'
                                                  "2 - #{supplier_bank.receiver_type if supplier_bank.present?}"
                                                elsif (supplier_bank.receiver_type if supplier_bank.present?) == 'Pemerintah / Goverment'
                                                  "3 - #{supplier_bank.receiver_type if supplier_bank.present?}"
                                                else
                                                  " "
                                                end
                  supplier_bank_residence_type = if (supplier_bank.residence_type if supplier_bank.present?) == 'Residence'
                                                  "1 - #{supplier_bank.residence_type if supplier_bank.present?}"
                                                elsif (supplier_bank.residence_type if supplier_bank.present?) == 'Non Residence'
                                                  "2 - #{supplier_bank.residence_type if supplier_bank.present?}"
                                                else
                                                  " " 
                                                end
                  country_code        = "#{supplier_bank.country_code.code if supplier_bank.present? and supplier_bank.country_code.present?} - #{supplier_bank.country_code.name if supplier_bank.present? and supplier_bank.country_code.present?}"
                  supplier_bank_email = if (supplier_bank.email if supplier_bank.present? and supplier_bank.email.present?) != nil
                                          "Yes"
                                        else
                                          "No"
                                        end
                  supplier_bank_email2 = (supplier_bank.email if supplier_bank.present? and supplier_bank.email.present?)
                  payment_invoice      = "#{invoice_selected[0..1].join(", ")} #{invoice_selected.count() > 3 ? ', Etc.' : ''}"
                else
                  # voucher payment
                  payment_number        = (item.voucher_payment.number if item.present? and item.voucher_payment.present?)
                  payment_account_holder =  (item.voucher_payment.list_external_bank_account.name_account if item.voucher_payment.present? and item.voucher_payment.list_external_bank_account.present?)
                  grandtotal            = (item.voucher_payment.grand_total if item.voucher_payment.present?)
                  dom_bank_skn_code     = ''
                  supplier_bank_name    = (item.voucher_payment.list_external_bank_account.dom_bank.bank_name if item.voucher_payment.list_external_bank_account.present? and item.voucher_payment.list_external_bank_account.dom_bank.present?)
                  supplier_address1     = ''
                  supplier_address2     = ''
                  supplier_address3     = ''
                  supplier_bank_receiver_type = ''
                  supplier_bank_residence_type = ''
                  country_code          = ''
                  supplier_bank_email   = ''
                  supplier_bank_email2  = ''
                  payment_invoice       = ''
                end
                sheet.add_row [
                              '1',
                              payment_number,
                              payment_account_holder,
                              "#{number_with_precision(grandtotal, precision: 2)}",
                              'LAC',
                              dom_bank_skn_code,
                              supplier_bank_name,
                              supplier_address1,
                              supplier_address2,
                              supplier_address3,
                              supplier_bank_receiver_type,
                              supplier_bank_residence_type,
                              country_code,
                              supplier_bank_email,
                              supplier_bank_email2,
                              payment_invoice,
                              '', #remark kosong
                              '', #remark kosong
                              item.by_transfer
                  ]
                 c+=1
              end
            end
          end
        end
      when "customer_ar_summaries"
        filename = controller_name.humanize
        # 20220317 - Danny
        params[:periode_yyyy] = (params[:periode_yyyy].present? ? params[:periode_yyyy] : "#{DateTime.now().strftime("%Y")}")
        records = InvoiceCustomer.where(:status=> 'approved3', :company_profile_id=> current_user.company_profile_id).where("date between ? and ?", "#{params[:periode_yyyy]}-01-01", "#{params[:periode_yyyy]}-12-31").includes(customer: [:currency]).order("date asc")

        wb.add_worksheet(name: filename) do |sheet|
          sheet.add_row ["", "Periode: #{params[:periode_yyyy]}"]
          header_row = ["NO.", "CUSTOMER", "CURR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER", "TOTAL"]
          sheet.add_row header_row

          c = 0
          begin_period = "#{params[:periode_yyyy]}-01-01"
          end_period   = "#{params[:periode_yyyy]}-12-31"
          months = (begin_period..end_period).map {|date| ["#{date.to_s[0, 7]}","#{date.to_s[0..-4]}"+"-01"]}.uniq

          records.group(:customer_id).each do |record|

            content_row = [c+=1, 
              "#{record.customer.name if record.customer.present?}",
              "#{record.customer.currency.name if record.customer.present? and record.customer.currency.present?}"
             ]

            sum_by_year = 0
            months.each do |yyyymm, yyyymmdd|
              begin_date = yyyymmdd.to_date.at_beginning_of_month
              end_date   = yyyymmdd.to_date.at_end_of_month
              sum_by_month = records.where(:customer_id=> record.customer_id, :date=> begin_date .. end_date).sum(:subtotal)

              content_row += ["#{sum_by_month}"]
              sum_by_year += sum_by_month
            end
            content_row += ["#{sum_by_year}"]

            sheet.add_row content_row
          end
        end

      when "outstanding_pdms"
        filename = "Outstanding PDM"
        
        items = PdmItem.where(:status=> 'active').where("pdm_items.outstanding > 0")
        .includes(material: [:unit])
        .includes(pdm: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3 ])
        .includes(purchase_order_supplier_items: [:purchase_order_supplier])
        .where(:pdms => {:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin].. session[:date_end]})
        .order("pdms.date desc")    

        wb.add_worksheet(name: filename) do |sheet|
          header_row = ["No.", "PDM Number", "PDM Date", "PDM Status",
            "Part Code", "Part Name", "Unit", "Quantity", "Outstanding", "PO",
            "Created at", "Created by", "Updated at", "Updated by", 
            "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
            "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
          ]
          sheet.add_row header_row
          c = 0
          items.each do |item|
            part = nil
            if item.material.present?
              part = item.material
            end

            unit_name = (part.present? ? part.unit.name : "")
            record = item.pdm
            content_row = [
              "#{c+=1}", record.number, record.date, record.status,
              "#{part.part_id if part.present?}", 
              "#{part.name if part.present?}", "#{unit_name}", item.quantity, item.outstanding,
              item.purchase_order_supplier_items.map { |e| e.purchase_order_supplier.number if e.status == 'active' }.join(", "),
              record.created_at, (record.created.present? ? record.created.first_name : nil), 
              record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
              record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
              record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
              record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
              record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
              record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
            ]
            sheet.add_row content_row
          end
        end
      when "outstanding_purchase_requests"
        filename = "Outstanding PRF"
        
        items = PurchaseRequestItem.where(:status=> 'active').where("purchase_request_items.outstanding > 0")
        .includes(material: [:unit], product: [:unit], consumable:[:unit], equipment: [:unit], general: [:unit])
        .includes(purchase_request: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3 ])
        .includes(purchase_order_supplier_items: [:purchase_order_supplier])
        .where(:purchase_requests => {:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin].. session[:date_end]})
        .order("purchase_requests.date desc")    

        wb.add_worksheet(name: filename) do |sheet|
          header_row = ["No.", "PRF Kind", "PRF Number", "PRF Date", "PRF Status",
            "Part Code", "Part Name", "Unit", "Quantity", "Outstanding", "PO",
            "Created at", "Created by", "Updated at", "Updated by", 
            "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
            "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
          ]
          sheet.add_row header_row
          c = 0
          items.each do |item|
            part = nil

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

            unit_name = (part.present? ? part.unit.name : "")
            record = item.purchase_request
            content_row = [
              "#{c+=1}", record.request_kind, record.number, record.date, record.status,
              "#{part.part_id if part.present?}", 
              "#{part.name if part.present?}", "#{unit_name}", item.quantity, item.outstanding,
              item.purchase_order_supplier_items.map { |e| e.purchase_order_supplier.number if e.status == 'active' }.join(", "),
              record.created_at, (record.created.present? ? record.created.first_name : nil), 
              record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
              record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
              record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
              record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
              record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
              record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
            ]
            sheet.add_row content_row
          end
        end
      when "outstanding_purchase_order_suppliers"
        filename = "Outstanding PO Supplier"
        
        items = PurchaseOrderSupplierItem.where(:status=> 'active').where("purchase_order_supplier_items.outstanding > 0")
        .includes(purchase_request_item: [material: [:unit], product: [:unit], consumable:[:unit], equipment: [:unit], general: [:unit]])
        .includes(pdm_item: [material: [:unit]])
        .includes(purchase_order_supplier: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, supplier:[:currency]])
        .where(:purchase_order_suppliers => {:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin].. session[:date_end]})
        .order("purchase_order_suppliers.date desc")    

        case params[:view_kind]
        when 'Over Due'
          items = items.where("purchase_order_supplier_items.due_date < ?", DateTime.now().strftime("%Y-%m-%d"))
        when 'number of days'
          items = items.where("purchase_order_supplier_items.due_date <= ?", (DateTime.now()+params[:number_of_days].to_i).to_date.strftime("%Y-%m-%d"))
        end

        wb.add_worksheet(name: filename) do |sheet|
          header_row = ["No.", "PO Kind", "PO Number", "PO Date", "PO Status",
            "Part Code", "Part Name", "Unit", "Quantity", "Outstanding", "Due date",
            "Created at", "Created by", "Updated at", "Updated by", 
            "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
            "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
          ]
          sheet.add_row header_row
          c = 0
          items.each do |item|
            part = nil
            if item.purchase_request_item.present?
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
            elsif item.pdm_item.present?
              if item.pdm_item.material.present?
                part = item.pdm_item.material
              end
            end
            unit_name = (part.present? ? part.unit.name : "")
            record = item.purchase_order_supplier
            content_row = [
              "#{c+=1}", record.kind, record.number, record.date, record.status,
              "#{part.part_id if part.present?}", 
              "#{part.name if part.present?}", "#{unit_name}", item.quantity, item.outstanding, item.due_date,
              record.created_at, (record.created.present? ? record.created.first_name : nil), 
              record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
              record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
              record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
              record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
              record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
              record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
            ]
            sheet.add_row content_row
          end
        end
      when "sterilization_product_receivings"
        filename = "Str Prd receipt note"
        case params[:view_kind]
        when 'item'
          items = SterilizationProductReceivingItem.where(:status=> 'active')
          .includes(:product_batch_number, product: [:unit, :product_type], sterilization_product_receiving: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, sales_order: [:customer]])
          .where(:sterilization_product_receivings => {:company_profile_id => current_user.company_profile_id }).where("sterilization_product_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("sterilization_product_receivings.number desc")      
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "SPR Number", "SPR Date", "SO Number", "PO Customer", "Customer",
              "Remarks", 
              "Product Code", "Batch Number", "Product Name", "Product Type", "Quantity", "Unit", "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              record = item.sterilization_product_receiving
              sales_order = record.sales_order
              content_row = [c+=1, record.status, 

                "#{record.number if record.present?}",
                "#{record.date if record.present?}",
                "#{sales_order.number if sales_order.present?}",
                "#{sales_order.po_number if sales_order.present?}",
                "#{sales_order.present? ? (sales_order.customer.present? ? sales_order.customer.name : "-") : "-"}",
                "#{record.remarks if record.present?}",
                item.product.part_id, "#{item.product_batch_number.number if item.product_batch_number.present?}", item.product.name, item.product.type_name, item.quantity, item.product.unit_name, item.remarks,
                 
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        else
          records = SterilizationProductReceiving.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin]..session[:date_end])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, sales_order: [:customer])
          .order("sterilization_product_receivings.number desc")   

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "SPR Number", "SPR Date", "SO Number", "PO Customer", "Customer",
              "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              sales_order = record.sales_order

              content_row = [c+=1, record.status, record.number, record.date, 
                (sales_order.present? ? sales_order.number : "-"), 
                (sales_order.present? ? sales_order.po_number : "-"), 
                (sales_order.present? ? "#{sales_order.customer.present? ? sales_order.customer.name : '-'}" : "-"), 
                record.remarks,
                
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
               ]
              sheet.add_row content_row
            end
          end
        end
      when "cost_project_finances"
        filename = controller_name.humanize
        # records = SalesOrder.where(:company_profile_id=> current_user.company_profile_id)
        #   .where("sales_orders.date between ? and ?", session[:date_begin], session[:date_end])
        #   .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, customer:[:currency])
        #   .includes(sales_order_items:[ 
        #     production_order_items: [
        #       production_order_used_prves: [
        #         purchase_request_item: [
        #           purchase_order_supplier_items: [ 
        #             product_receiving_items: [
        #               :product_receiving, :purchase_order_supplier_item
        #             ], material_receiving_items: [
        #               :material_receiving, :purchase_order_supplier_item
        #             ], general_receiving_items: [
        #               :general_receiving, :purchase_order_supplier_item
        #             ], consumable_receiving_items: [
        #               :consumable_receiving, :purchase_order_supplier_item
        #             ], equipment_receiving_items: [
        #               :equipment_receiving, :purchase_order_supplier_item
        #             ], purchase_order_supplier: [:currency, :purchase_order_supplier_items]]]]]]).where(:sales_orders=> {:number=> 'PP/PIF/12/VI/2021'})
        records = CostProjectFinance.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end])
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

        wb.add_worksheet(name: filename) do |sheet|
          header_row = ["No.", "SO Number", "Project Name", "Service", "Customer", "Tgl.Sales Order", "Amount SO",
            "Purchase Order", "Amount PO", "Amount GRN", 
            "Net"]
          sheet.add_row header_row
          c = 0
          records.each do |record|
            content_row = [c+=1, record.sales_order.number, record.sales_order.remarks, record.sales_order.list_service_type_short.join(", "), "#{record.customer.name if record.customer.present?}", record.date,
              "#{record.amount_so}",
              record.po_supplier_number, 
              "#{record.amount_po}",
              "#{record.amount_grn}",
              "#{record.amount_so - record.amount_grn}",
             ]
            sheet.add_row content_row
          end
        end
      when "production_order_material_costs"
        filename = controller_name.humanize
        new_array = {}
        wb.add_worksheet(name: filename) do |sheet|
          header_row = ["No.","SO Status", "SO Number", "SPP Number", "SPP Date", 
            "Product Part ID", "Product Name", "SO Quantity",
            "Product Price",
            "Material Part ID", "PRF Qty", "PO Supplier Details",
            "","","","","","",
            "Sum Price PO", "Sum Qty PO", "Sum Qty GRN", "Sum Price SO", "SO - PO"
          ]
          sheet.merge_cells "L1:Q1"
          danger_cell = wb.styles.add_style :bg_color => "FF0000", :color => "FF"
          highlight_cell = wb.styles.add_style :bg_color => "33FF33", :color => "FF"
          row_title = wb.styles.add_style :b=> true, :bg_color => "EFECEC", :border=> {:style => :thin, :color => "A1A9B5"}
          sheet.add_row header_row, :style => row_title
          c = 0
          @production_order_used_prves.each do |record|
            material_part = nil
            if record.purchase_request_item.material.present?
              material_part = record.purchase_request_item.material
            elsif record.purchase_request_item.product.present?
              material_part = record.purchase_request_item.product
            end
            po_items = record.purchase_request_item.purchase_order_supplier_items
            so_unit_price = record.production_order_item.sales_order_item.unit_price #Harga PO
            so_quantity = record.production_order_item.sales_order_item.quantity #Harga PO
            so_status = record.production_order_item.production_order.sales_order.status
            so_number = record.production_order_item.production_order.sales_order.number

            row_sum_price = nil
            row_po_item   = nil

            content_row = sheet.add_row [c+=1, 
              record.production_order_item.production_order.sales_order.status,
              so_number,
              record.production_order_item.production_order.number,
              record.production_order_item.production_order.date,
              record.production_order_item.product.part_id,
              record.production_order_item.product.name,
              so_quantity,
              so_unit_price,
              "#{material_part.part_id if material_part.present?}",
              record.purchase_request_item.quantity,
              po_items.present? ? "PO Status" : nil, 
              po_items.present? ? "PO Number" : nil, 
              po_items.present? ? "Unit Price" : nil,
              po_items.present? ? "Qty PO" : nil,
              po_items.present? ? "Good Receive Notes Detail" : nil,
              "","","","","","","",""
             ]

            row_index = content_row.row_index+1
            sheet.merge_cells "P#{row_index}:R#{row_index}"
            sheet["L#{row_index}:P#{row_index}"].each { |c| c.style = row_title } 
            sheet["B#{row_index}"].style = danger_cell if record.production_order_item.production_order.sales_order.status != 'approved3'
            
            if po_items.present?
              sum_qty_po = 0
              sum_qty_grn_by_po = 0
              buy_price = 0
              po_items.each do |po_item|
                # if po_item.purchase_order_supplier.status == 'approved3'
                  grn_items = po_item.material_receiving_items
                  po_item_quantity = po_item.quantity.to_f

                  row_po_item = sheet.add_row ["", "",
                    "", "", "", "", "", "", "", "", "",
                    po_item.purchase_order_supplier.status, 
                    po_item.purchase_order_supplier.number, 
                    po_item.unit_price,
                    po_item_quantity,
                    grn_items.present? ? "GRN Status" : nil,
                    grn_items.present? ? "GRN Number" : nil,
                    grn_items.present? ? "Qty GRN" : nil,
                  ]

                  row_grn_item = nil
                  if grn_items.present?
                    sum_qty_grn = 0
                    grn_items.each do |grn_item|
                      row_grn_item = sheet.add_row ["", "",
                        "", "", "", "", "", "", "", "", 
                        "", 
                        "", 
                        "", 
                        "", "",
                        grn_item.material_receiving.status,
                        grn_item.material_receiving.number,
                        grn_item.quantity,
                      ]
                      sum_qty_grn += grn_item.quantity
                      sum_qty_grn_by_po += grn_item.quantity
                    end
                  end

                  if row_grn_item.present?
                    ["L", "M", "N","O"].each do |col_name|
                      sheet.merge_cells "#{col_name}#{row_po_item.row_index+1}:#{col_name}#{row_grn_item.row_index+1}"
                    end
                  end
                  sum_qty_po += po_item_quantity
                  buy_price += (po_item.unit_price.to_f*po_item_quantity.to_f)

                  new_array[so_number] ||= {}
                  new_array[so_number][record.production_order_item.product.part_id] ||= {}
                  new_array[so_number][record.production_order_item.product.part_id][:so_quantity] = so_quantity
                  new_array[so_number][record.production_order_item.product.part_id][:so_unit_price] = so_unit_price
                  new_array[so_number][record.production_order_item.product.part_id][:po_supplier]||= {}
                  new_array[so_number][record.production_order_item.product.part_id][:po_supplier][po_item.purchase_order_supplier.number] ||= {}
                  new_array[so_number][record.production_order_item.product.part_id][:po_supplier][po_item.purchase_order_supplier.number][:quantity]   = po_item_quantity.to_f
                  new_array[so_number][record.production_order_item.product.part_id][:po_supplier][po_item.purchase_order_supplier.number][:unit_price] = po_item.unit_price.to_f
                  new_array[so_number][record.production_order_item.product.part_id][:po_supplier][po_item.purchase_order_supplier.number][:buy_price]  = po_item.unit_price.to_f*po_item_quantity.to_f
                  new_array[so_number][record.production_order_item.product.part_id][:po_supplier][po_item.purchase_order_supplier.number][:material_part_id] = "#{material_part.part_id if material_part.present?}"
                  # sheet.add_row ["", "",
                  #       "", "", "", "", "", "", "", "", 
                  #       "", 
                  #       "", 
                  #       "", 
                  #       "", 
                  #       "",
                  #       "Summary GRN",
                  #       sum_qty_grn,
                  #     ]
                  row_index = row_po_item.row_index+1
                  sheet["P#{row_index}:R#{row_index}"].each { |c| c.style = row_title } if grn_items.present?
                  sheet["L#{row_index}"].style = danger_cell if po_item.purchase_order_supplier.status != 'approved3'
                # end
              end
              # row_summary_po = sheet.add_row ["", "",
              #       "", "", "", "", "", "", "", "", 
              #       "", 
              #       "", 
              #       "Summary PO",
              #       sum_qty_po,
              #       "",
              #       sum_qty_grn_by_po > 0 ? "Summary GRN" : "",
              #       sum_qty_grn_by_po > 0 ? sum_qty_grn_by_po : ""                    
              #     ]
              # row_index = row_summary_po.row_index+1
              # sheet["N#{row_index}"].style = danger_cell if sum_qty_po.to_f > record.purchase_request_item.quantity.to_f

            end

            if row_po_item.present?
              # merge cell
              ["A","B","C","D","E","F","G","H","I","J","S","T","U","V"].each do |col_name|
                sheet.merge_cells "#{col_name}#{content_row.row_index+1}:#{col_name}#{row_po_item.row_index+1}"
              end
              
              # Summary Buy Price/ Harga PO
                check_row = sheet["S#{content_row.row_index+1}"]
                if check_row.present?
                  check_row.value  = buy_price
                  puts check_row.value 
                end
              # Summary Qty PO
                check_row = sheet["T#{content_row.row_index+1}"]
                if check_row.present?
                  check_row.value  = sum_qty_po
                  puts check_row.value 
                end
              # Summary Qty GRN
                check_row = sheet["U#{content_row.row_index+1}"]
                if check_row.present?
                  check_row.value  = sum_qty_grn_by_po
                  puts check_row.value 
                end
              # Summary Sell Price/ Harga SO
                check_row = sheet["V#{content_row.row_index+1}"]
                if check_row.present?
                  check_row.value  = (so_quantity.to_f * so_unit_price.to_f)
                  puts check_row.value 
                end

                check_row = sheet["W#{content_row.row_index+1}"]
                if check_row.present?
                  check_row.value  = ((so_quantity.to_f * so_unit_price.to_f) - buy_price.to_f)
                  puts check_row.value 
                end

            end

            sheet.add_row [""]
          end
        end
        new_array.each do |so_number, parts|
          puts "so_number: #{so_number}"
          wb.add_worksheet(name: so_number.remove("/")) do |sheet|
            # sheet.add_row ["Part ID", "SO Qty", "SO Unit Price", "Summary Price SO", "Summary Price PO", "G/L"]
            sheet.add_row ["SO Number", so_number]
            sheet.add_row ["No.", "Product Part ID", "SO Qty", "SO Unit Price"]
            c = 0
            sum_so_qty = sum_so_price = 0
            po_items = {}
            parts.each do |part, items|
              puts "  part_id: #{part}"
              puts "  so_quantity: #{items[:so_quantity]}"
              puts "  so_unit_price: #{items[:so_unit_price]}"

              sheet.add_row ["#{c+=1}", "#{part}", "#{items[:so_quantity]}", "#{items[:so_unit_price]}"]
              sum_so_qty += items[:so_quantity].to_f
              sum_so_price += items[:so_unit_price].to_f

              items[:po_supplier].each do |po_supplier, po_details|
                # puts JSON.pretty_generate(po_supplier)
                
                po_items[po_supplier] ||= {}
                po_items[po_supplier]["#{po_details[:material_part_id]}"] ||= {}
                po_items[po_supplier]["#{po_details[:material_part_id]}"][:quantity] = po_details[:quantity]
                po_items[po_supplier]["#{po_details[:material_part_id]}"][:unit_price] = po_details[:unit_price]
              end
            end

            sheet.add_row [" ", "Summary", "#{sum_so_qty}", "#{sum_so_price}"]

            sheet.add_row [" "]
            sheet.add_row ["No.", "PO Number", "Material Part ID", "PO Qty", "Unit Price"]
            c = 0
            sum_po_qty = sum_po_price = 0
            po_items.each do |po_number, items|
              items.each do |material_part_id, item|
                sheet.add_row ["#{c+=1}", "#{po_number}", "#{material_part_id}", "#{item[:quantity]}", "#{item[:unit_price]}"]
                
                sum_po_qty += item[:quantity].to_f
                sum_po_price += item[:unit_price].to_f
              end
            end
            sheet.add_row [" "," ", "Summary", "#{sum_po_qty}", "#{sum_po_price}"]
            sheet.add_row [" "]
            sheet.add_row [" ","Summary Price SO", "#{sum_so_price}"]
            sheet.add_row [" " ,"Summary Price PO", "#{sum_po_price}"]
          end 
          puts "==================================="
        end
        
        # puts JSON.pretty_generate(new_array)
      when "material_check_sheets"
        filename = controller_name.humanize
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "MCS Number", "MCS Date", 
              "Material Batch Number", "Material Name", "Supplier",
              "GRN Number", "GRN Date",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, record.number, record.date, 
                record.material_batch_number.present? ? record.material_batch_number.number : "", record.material.present? ? record.material.name : "", record.supplier.present? ? record.supplier.name : "", 
                record.material_receiving.present? ? record.material_receiving.number : "", 
                record.material_receiving.present? ? record.material_receiving.date : "", 
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
               ]
              sheet.add_row content_row
            end
          end
      when "material_outgoings"
        filename = controller_name.humanize
        case params[:view_kind]
        when 'item'
          items = MaterialOutgoingItem.where(:status=> 'active')
          .includes(
            product_batch_number: [product_receiving_item: [purchase_order_supplier_item: [purchase_order_supplier: [:currency]] ]],
            material: [:unit], product: [:unit], 
            material_outgoing: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, product_batch_number: [shop_floor_order_item: [:shop_floor_order, sales_order: [:customer]]]],
            material_batch_number: [material_receiving_item: [purchase_order_supplier_item: [purchase_order_supplier: [:currency]], material_receiving: [:supplier]]]
            )
          .where(:material_outgoings => {:company_profile_id => current_user.company_profile_id }).where("material_outgoings.date between ? and ?", session[:date_begin], session[:date_end]).order("material_outgoings.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Material Issue Number", "Material Issue Date",
              "SFO Number",
              "No.Sales Order", "No.PO Customer", "Customer Name", "No.PO Supplier",
              "Material Batch Number", "Material Code", "Material Name", "Quantity", "Unit", 
              "Currency", "Unit Price",
              "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              material_outgoing          = item.material_outgoing
              product_batch_number       = material_outgoing.product_batch_number if material_outgoing.present?
              shop_floor_order_item      = product_batch_number.shop_floor_order_item if product_batch_number.present?
              shop_floor_order           = shop_floor_order_item.shop_floor_order if shop_floor_order_item.present?
              sales_order                = shop_floor_order_item.sales_order if shop_floor_order_item.present?

              # puts "item: #{item.id}"
              part = part_batch_number = part_currency = purchase_order_supplier_item = nil
              if item.material.present?
                part = item.material
                part_batch_number = item.material_batch_number

                material_receiving_item    = part_batch_number.material_receiving_item if part_batch_number.present?
                material_receiving         = material_receiving_item.material_receiving if material_receiving_item.present?
                purchase_order_supplier_item = material_receiving_item.purchase_order_supplier_item if material_receiving_item.present?
                purchase_order_supplier      = purchase_order_supplier_item.purchase_order_supplier if purchase_order_supplier_item.present?
                puts "material"
              elsif item.product.present?
                part = item.product
                part_batch_number = item.product_batch_number

                product_receiving_item    = part_batch_number.product_receiving_item if part_batch_number.present?
                purchase_order_supplier_item = product_receiving_item.purchase_order_supplier_item if product_receiving_item.present?
                purchase_order_supplier      = purchase_order_supplier_item.purchase_order_supplier if purchase_order_supplier_item.present?
                puts "product"
              end
              # puts "part_id : #{part.part_id}"
              # puts "part_batch_number: #{part_batch_number.number if part_batch_number.present?}"
              # puts "purchase_order_supplier_item: #{purchase_order_supplier_item.id if purchase_order_supplier_item.present?}"
              # puts "purchase_order_supplier: #{purchase_order_supplier.id if purchase_order_supplier.present?}"
              # puts "----------------------------"
                part_currency     = purchase_order_supplier.currency.name if purchase_order_supplier.present? and purchase_order_supplier.currency.present?
              sheet.add_row [c+=1, item.material_outgoing.status, 
                "#{item.material_outgoing.number if item.material_outgoing.present?}",
                "#{item.material_outgoing.date if item.material_outgoing.present?}",
                "#{shop_floor_order.number if shop_floor_order.present?}",
                "#{sales_order.number if sales_order.present?}",
                "#{sales_order.po_number if sales_order.present?}",
                "#{sales_order.customer.name if sales_order.present?}",
                "#{purchase_order_supplier.number if purchase_order_supplier.present?}",
                "#{part_batch_number.present? ? part_batch_number.number : "Tidak ada Batch Number"}",
                "#{part.part_id if part.present?}", 
                "#{part.name if part.present?}", item.quantity, 
                "#{part.unit_name if part.present?}", 
                "#{part_currency}",
                "#{purchase_order_supplier_item.unit_price if purchase_order_supplier_item.present?}",
                item.remarks,
                material_outgoing.created_at, (material_outgoing.created.present? ? material_outgoing.created.first_name : nil), 
                material_outgoing.approved1_at, (material_outgoing.approved1.present? ? material_outgoing.approved1.first_name : nil), 
                material_outgoing.approved2_at, (material_outgoing.approved2.present? ? material_outgoing.approved2.first_name : nil), 
                material_outgoing.approved3_at, (material_outgoing.approved3.present? ? material_outgoing.approved3.first_name : nil), 
                material_outgoing.canceled1_at, (material_outgoing.canceled1.present? ? material_outgoing.canceled1.first_name : nil), 
                material_outgoing.canceled2_at, (material_outgoing.canceled2.present? ? material_outgoing.canceled2.first_name : nil), 
                material_outgoing.canceled3_at, (material_outgoing.canceled3.present? ? material_outgoing.canceled3.first_name : nil)

               ]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Material Issue Number", "Material Issue Date", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, record.number, record.date, 
                record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "material_returns"
        filename = "Return Material"
        case params[:view_kind]
        when 'item'
          items = MaterialReturnItem.where(:status=> 'active')
          .includes(
            :material_batch_number,
            material: [:unit], 
            material_return: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3],
            )
          .where(:material_returns => {:company_profile_id => current_user.company_profile_id }).where("material_returns.date between ? and ?", session[:date_begin], session[:date_end]).order("material_returns.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "RM Number", "RM Date",
              "Material Batch Number", "Material Code", "Material Name", "Quantity", "Unit", 
              "Remarks Item", "Category",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              material_return         = item.material_return
             
              # puts "item: #{item.id}"
              part = part_batch_number = part_currency = purchase_order_supplier_item = nil
              if item.material.present?
                part = item.material
                part_batch_number = item.material_batch_number
                puts "material"
              end
              # puts "part_id : #{part.part_id}"
              # puts "part_batch_number: #{part_batch_number.number if part_batch_number.present?}"
              # puts "purchase_order_supplier_item: #{purchase_order_supplier_item.id if purchase_order_supplier_item.present?}"
              # puts "purchase_order_supplier: #{purchase_order_supplier.id if purchase_order_supplier.present?}"
              # puts "----------------------------"
              sheet.add_row [c+=1, material_return.status, 
                "#{material_return.number if material_return.present?}",
                "#{material_return.date if material_return.present?}",
                "#{part_batch_number.present? ? part_batch_number.number : "Tidak ada Batch Number"}",
                "#{part.part_id if part.present?}", 
                "#{part.name if part.present?}", item.quantity, 
                "#{part.unit_name if part.present?}", 
                item.remarks,
                item.category,
                material_return.created_at, (material_return.created.present? ? material_return.created.first_name : nil), 
                material_return.approved1_at, (material_return.approved1.present? ? material_return.approved1.first_name : nil), 
                material_return.approved2_at, (material_return.approved2.present? ? material_return.approved2.first_name : nil), 
                material_return.approved3_at, (material_return.approved3.present? ? material_return.approved3.first_name : nil), 
                material_return.canceled1_at, (material_return.canceled1.present? ? material_return.canceled1.first_name : nil), 
                material_return.canceled2_at, (material_return.canceled2.present? ? material_return.canceled2.first_name : nil), 
                material_return.canceled3_at, (material_return.canceled3.present? ? material_return.canceled3.first_name : nil)

               ]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3)
          .order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "RM Number", "RM Date", "Status", "Remarks",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |material_return|
              content_row = [c+=1,
                material_return.number, material_return.date, material_return.status, material_return.remarks,
                material_return.created_at, (material_return.created.present? ? material_return.created.first_name : nil), 
                material_return.approved1_at, (material_return.approved1.present? ? material_return.approved1.first_name : nil), 
                material_return.approved2_at, (material_return.approved2.present? ? material_return.approved2.first_name : nil), 
                material_return.approved3_at, (material_return.approved3.present? ? material_return.approved3.first_name : nil), 
                material_return.canceled1_at, (material_return.canceled1.present? ? material_return.canceled1.first_name : nil), 
                material_return.canceled2_at, (material_return.canceled2.present? ? material_return.canceled2.first_name : nil), 
                material_return.canceled3_at, (material_return.canceled3.present? ? material_return.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "material_additionals"
        filename = "Additional Material"
        case params[:view_kind]
        when 'item'
          items = MaterialAdditionalItem.where(:status=> 'active')
          .includes(
            :material_batch_number,
            material: [:unit], 
            material_additional: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3],
            )
          .where(:material_additionals => {:company_profile_id => current_user.company_profile_id }).where("material_additionals.date between ? and ?", session[:date_begin], session[:date_end]).order("material_additionals.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "AM Number", "AM Date",
              "Material Batch Number", "Material Code", "Material Name", "Quantity", "Unit", 
              "Remarks Item", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              material_additional         = item.material_additional
             
              # puts "item: #{item.id}"
              part = part_batch_number = part_currency = purchase_order_supplier_item = nil
              if item.material.present?
                part = item.material
                part_batch_number = item.material_batch_number
                puts "material"
              end
              
              sheet.add_row [c+=1, material_additional.status, 
                "#{material_additional.number if material_additional.present?}",
                "#{material_additional.date if material_additional.present?}",
                "#{part_batch_number.present? ? part_batch_number.number : "Tidak ada Batch Number"}",
                "#{part.part_id if part.present?}", 
                "#{part.name if part.present?}", item.quantity, 
                "#{part.unit_name if part.present?}", 
                item.remarks,
                material_additional.created_at, (material_additional.created.present? ? material_additional.created.first_name : nil), 
                material_additional.approved1_at, (material_additional.approved1.present? ? material_additional.approved1.first_name : nil), 
                material_additional.approved2_at, (material_additional.approved2.present? ? material_additional.approved2.first_name : nil), 
                material_additional.approved3_at, (material_additional.approved3.present? ? material_additional.approved3.first_name : nil), 
                material_additional.canceled1_at, (material_additional.canceled1.present? ? material_additional.canceled1.first_name : nil), 
                material_additional.canceled2_at, (material_additional.canceled2.present? ? material_additional.canceled2.first_name : nil), 
                material_additional.canceled3_at, (material_additional.canceled3.present? ? material_additional.canceled3.first_name : nil)

               ]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3)
          .order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "RM Number", "RM Date", "Status", "Remarks",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |material_additional|
              content_row = [c+=1,
                material_additional.number, material_additional.date, material_additional.status, material_additional.remarks,
                material_additional.created_at, (material_additional.created.present? ? material_additional.created.first_name : nil), 
                material_additional.approved1_at, (material_additional.approved1.present? ? material_additional.approved1.first_name : nil), 
                material_additional.approved2_at, (material_additional.approved2.present? ? material_additional.approved2.first_name : nil), 
                material_additional.approved3_at, (material_additional.approved3.present? ? material_additional.approved3.first_name : nil), 
                material_additional.canceled1_at, (material_additional.canceled1.present? ? material_additional.canceled1.first_name : nil), 
                material_additional.canceled2_at, (material_additional.canceled2.present? ? material_additional.canceled2.first_name : nil), 
                material_additional.canceled3_at, (material_additional.canceled3.present? ? material_additional.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        end
      
      when "material_receivings"
        filename = "GRN Material"
        case params[:view_kind]
        when 'item'
          items = MaterialReceivingItem.where(:status=> 'active')
          .includes(
            :material_batch_number,
            material: [:unit], 
            material_receiving: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier, :invoice_supplier],
            )
          .where(:material_receivings => {:company_profile_id => current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end] }).order("material_receivings.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Supplier Name", "GRN Number", "GRN Date",
              "No.PO Supplier",
              "Supplier Batch Number", "EXP Date", "Packaging Condition", "Material Batch Number", "Material Code", "Material Name", "Quantity", "Unit", 
              "Currency", "Unit Price",
              "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              material_receiving         = item.material_receiving
             
              # puts "item: #{item.id}"
              part = part_batch_number = part_currency = purchase_order_supplier_item = nil
              if item.material.present?
                part = item.material
                part_batch_number = item.material_batch_number

                purchase_order_supplier_item = item.purchase_order_supplier_item if item.present?
                purchase_order_supplier      = purchase_order_supplier_item.purchase_order_supplier if purchase_order_supplier_item.present?
                puts "material"
              end
              # puts "part_id : #{part.part_id}"
              # puts "part_batch_number: #{part_batch_number.number if part_batch_number.present?}"
              # puts "purchase_order_supplier_item: #{purchase_order_supplier_item.id if purchase_order_supplier_item.present?}"
              # puts "purchase_order_supplier: #{purchase_order_supplier.id if purchase_order_supplier.present?}"
              # puts "----------------------------"
                part_currency     = purchase_order_supplier.currency.name if purchase_order_supplier.present? and purchase_order_supplier.currency.present?
              sheet.add_row [c+=1, material_receiving.status, "#{material_receiving.supplier.name if material_receiving.supplier.present?}",
                "#{material_receiving.number if material_receiving.present?}",
                "#{material_receiving.date if material_receiving.present?}",
                "#{purchase_order_supplier.number if purchase_order_supplier.present?}",
                "#{item.supplier_batch_number.present? ? item.supplier_batch_number : 'Tidak Ada'}",
                "#{item.supplier_expired_date.present? ? item.supplier_expired_date : 'Tidak Ada'}",
                "#{item.packaging_condition.present? ? item.packaging_condition : 'Tidak Ada'}",
                "#{part_batch_number.present? ? part_batch_number.number : "Tidak ada Batch Number"}",
                "#{part.part_id if part.present?}", 
                "#{part.name if part.present?}", item.quantity, 
                "#{part.unit_name if part.present?}", 
                "#{part_currency}",
                "#{purchase_order_supplier_item.unit_price if purchase_order_supplier_item.present?}",
                item.remarks,
                material_receiving.created_at, (material_receiving.created.present? ? material_receiving.created.first_name : nil), 
                material_receiving.approved1_at, (material_receiving.approved1.present? ? material_receiving.approved1.first_name : nil), 
                material_receiving.approved2_at, (material_receiving.approved2.present? ? material_receiving.approved2.first_name : nil), 
                material_receiving.approved3_at, (material_receiving.approved3.present? ? material_receiving.approved3.first_name : nil), 
                material_receiving.canceled1_at, (material_receiving.canceled1.present? ? material_receiving.canceled1.first_name : nil), 
                material_receiving.canceled2_at, (material_receiving.canceled2.present? ? material_receiving.canceled2.first_name : nil), 
                material_receiving.canceled3_at, (material_receiving.canceled3.present? ? material_receiving.canceled3.first_name : nil)

               ]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier)
          .order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Supplier", "PO Number", "GRN Number", "GRN Date", "Status", "Remarks",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |material_receiving|
              content_row = [c+=1, material_receiving.supplier.name, material_receiving.purchase_order_supplier.number,
                material_receiving.number, material_receiving.date, material_receiving.status, material_receiving.remarks,
                material_receiving.created_at, (material_receiving.created.present? ? material_receiving.created.first_name : nil), 
                material_receiving.approved1_at, (material_receiving.approved1.present? ? material_receiving.approved1.first_name : nil), 
                material_receiving.approved2_at, (material_receiving.approved2.present? ? material_receiving.approved2.first_name : nil), 
                material_receiving.approved3_at, (material_receiving.approved3.present? ? material_receiving.approved3.first_name : nil), 
                material_receiving.canceled1_at, (material_receiving.canceled1.present? ? material_receiving.canceled1.first_name : nil), 
                material_receiving.canceled2_at, (material_receiving.canceled2.present? ? material_receiving.canceled2.first_name : nil), 
                material_receiving.canceled3_at, (material_receiving.canceled3.present? ? material_receiving.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "product_receivings"
        filename = "GRN Product"
        case params[:view_kind]
        when 'item'
          items = ProductReceivingItem.where(:status=> 'active')
          .includes(
            :product_batch_number, purchase_order_supplier_item: [purchase_order_supplier: [:currency]], 
            product: [:unit], 
            product_receiving: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier, :invoice_supplier],
            )
          .where(:product_receivings => {:company_profile_id => current_user.company_profile_id }).where("product_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("product_receivings.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "GRN Number", "GRN Date",
              "No.PO Supplier",
              "Supplier Batch Number", "Product Batch Number", "Product Code", "Product Name", "Quantity", "Unit", 
              "Currency", "Unit Price",
              "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              product_receiving         = item.product_receiving
             
              # puts "item: #{item.id}"
              part = part_batch_number = part_currency = purchase_order_supplier_item = nil
              if item.product.present?
                part = item.product
                part_batch_number = item.product_batch_number

                purchase_order_supplier_item = item.purchase_order_supplier_item if item.present?
                purchase_order_supplier      = purchase_order_supplier_item.purchase_order_supplier if purchase_order_supplier_item.present?
                # puts "product"
              end
              # puts "part_id : #{part.part_id}"
              # puts "part_batch_number: #{part_batch_number.number if part_batch_number.present?}"
              # puts "purchase_order_supplier_item: #{purchase_order_supplier_item.id if purchase_order_supplier_item.present?}"
              # puts "purchase_order_supplier: #{purchase_order_supplier.id if purchase_order_supplier.present?}"
              # puts "----------------------------"
                part_currency     = purchase_order_supplier.currency.name if purchase_order_supplier.present? and purchase_order_supplier.currency.present?
              sheet.add_row [c+=1, product_receiving.status, 
                "#{product_receiving.number if product_receiving.present?}",
                "#{product_receiving.date if product_receiving.present?}",
                "#{purchase_order_supplier.number if purchase_order_supplier.present?}",
                "#{item.supplier_batch_number}",
                "#{part_batch_number.present? ? part_batch_number.number : "Tidak ada Batch Number"}",
                "#{part.part_id if part.present?}", 
                "#{part.name if part.present?}", item.quantity, 
                "#{part.unit_name if part.present?}", 
                "#{part_currency}",
                "#{purchase_order_supplier_item.unit_price if purchase_order_supplier_item.present?}",
                item.remarks,
                product_receiving.created_at, (product_receiving.created.present? ? product_receiving.created.first_name : nil), 
                product_receiving.approved1_at, (product_receiving.approved1.present? ? product_receiving.approved1.first_name : nil), 
                product_receiving.approved2_at, (product_receiving.approved2.present? ? product_receiving.approved2.first_name : nil), 
                product_receiving.approved3_at, (product_receiving.approved3.present? ? product_receiving.approved3.first_name : nil), 
                product_receiving.canceled1_at, (product_receiving.canceled1.present? ? product_receiving.canceled1.first_name : nil), 
                product_receiving.canceled2_at, (product_receiving.canceled2.present? ? product_receiving.canceled2.first_name : nil), 
                product_receiving.canceled3_at, (product_receiving.canceled3.present? ? product_receiving.canceled3.first_name : nil)

               ]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier)
          .order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Supplier", "PO Number", "GRN Number", "GRN Date", "Status", "Remarks",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |material_receiving|
              content_row = [c+=1, material_receiving.supplier.name, material_receiving.purchase_order_supplier.number,
                material_receiving.number, material_receiving.date, material_receiving.status, material_receiving.remarks,
                material_receiving.created_at, (material_receiving.created.present? ? material_receiving.created.first_name : nil), 
                material_receiving.approved1_at, (material_receiving.approved1.present? ? material_receiving.approved1.first_name : nil), 
                material_receiving.approved2_at, (material_receiving.approved2.present? ? material_receiving.approved2.first_name : nil), 
                material_receiving.approved3_at, (material_receiving.approved3.present? ? material_receiving.approved3.first_name : nil), 
                material_receiving.canceled1_at, (material_receiving.canceled1.present? ? material_receiving.canceled1.first_name : nil), 
                material_receiving.canceled2_at, (material_receiving.canceled2.present? ? material_receiving.canceled2.first_name : nil), 
                material_receiving.canceled3_at, (material_receiving.canceled3.present? ? material_receiving.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "general_receivings"
        filename = "GRN General"
        case params[:view_kind]
        when 'item'
          items = GeneralReceivingItem.where(:status=> 'active')
          .includes(
            :general_batch_number, purchase_order_supplier_item: [purchase_order_supplier: [:currency]], 
            general: [:unit], 
            general_receiving: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier, :invoice_supplier],
            )
          .where(:general_receivings => {:company_profile_id => current_user.company_profile_id }).where("general_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("general_receivings.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "GRN Number", "GRN Date",
              "No.PO Supplier",
              "Supplier Batch Number", "General Batch Number", "General Code", "General Name", "Quantity", "Unit", 
              "Currency", "Unit Price",
              "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              general_receiving         = item.general_receiving
             
              # puts "item: #{item.id}"
              part = part_batch_number = part_currency = purchase_order_supplier_item = nil
              if item.general.present?
                part = item.general
                part_batch_number = item.general_batch_number

                purchase_order_supplier_item = item.purchase_order_supplier_item if item.present?
                purchase_order_supplier      = purchase_order_supplier_item.purchase_order_supplier if purchase_order_supplier_item.present?
                # puts "product"
              end
              # puts "part_id : #{part.part_id}"
              # puts "part_batch_number: #{part_batch_number.number if part_batch_number.present?}"
              # puts "purchase_order_supplier_item: #{purchase_order_supplier_item.id if purchase_order_supplier_item.present?}"
              # puts "purchase_order_supplier: #{purchase_order_supplier.id if purchase_order_supplier.present?}"
              # puts "----------------------------"
                part_currency     = purchase_order_supplier.currency.name if purchase_order_supplier.present? and purchase_order_supplier.currency.present?
              sheet.add_row [c+=1, general_receiving.status, 
                "#{general_receiving.number if general_receiving.present?}",
                "#{general_receiving.date if general_receiving.present?}",
                "#{purchase_order_supplier.number if purchase_order_supplier.present?}",
                "#{item.supplier_batch_number}",
                "#{part_batch_number.present? ? part_batch_number.number : "Tidak ada Batch Number"}",
                "#{part.part_id if part.present?}", 
                "#{part.name if part.present?}", item.quantity, 
                "#{part.unit_name if part.present?}", 
                "#{part_currency}",
                "#{purchase_order_supplier_item.unit_price if purchase_order_supplier_item.present?}",
                item.remarks,
                general_receiving.created_at, (general_receiving.created.present? ? general_receiving.created.first_name : nil), 
                general_receiving.approved1_at, (general_receiving.approved1.present? ? general_receiving.approved1.first_name : nil), 
                general_receiving.approved2_at, (general_receiving.approved2.present? ? general_receiving.approved2.first_name : nil), 
                general_receiving.approved3_at, (general_receiving.approved3.present? ? general_receiving.approved3.first_name : nil), 
                general_receiving.canceled1_at, (general_receiving.canceled1.present? ? general_receiving.canceled1.first_name : nil), 
                general_receiving.canceled2_at, (general_receiving.canceled2.present? ? general_receiving.canceled2.first_name : nil), 
                general_receiving.canceled3_at, (general_receiving.canceled3.present? ? general_receiving.canceled3.first_name : nil)

               ]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :supplier, :purchase_order_supplier)
          .order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Supplier", "PO Number", "GRN Number", "GRN Date", "Status", "Remarks",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |material_receiving|
              content_row = [c+=1, material_receiving.supplier.name, material_receiving.purchase_order_supplier.number,
                material_receiving.number, material_receiving.date, material_receiving.status, material_receiving.remarks,
                material_receiving.created_at, (material_receiving.created.present? ? material_receiving.created.first_name : nil), 
                material_receiving.approved1_at, (material_receiving.approved1.present? ? material_receiving.approved1.first_name : nil), 
                material_receiving.approved2_at, (material_receiving.approved2.present? ? material_receiving.approved2.first_name : nil), 
                material_receiving.approved3_at, (material_receiving.approved3.present? ? material_receiving.approved3.first_name : nil), 
                material_receiving.canceled1_at, (material_receiving.canceled1.present? ? material_receiving.canceled1.first_name : nil), 
                material_receiving.canceled2_at, (material_receiving.canceled2.present? ? material_receiving.canceled2.first_name : nil), 
                material_receiving.canceled3_at, (material_receiving.canceled3.present? ? material_receiving.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "invoice_supplier_receivings"
        filename = "Invoice Receiving"  
        records = InvoiceSupplierReceivingItem.where(:status=> 'active').where("invoice_date between ? and ?", session[:date_begin], session[:date_end])
          .includes(:invoice_supplier_receiving)
          .where(:invoice_supplier_receivings => {:status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'], :company_profile_id => current_user.company_profile_id }).order("invoice_supplier_receivings.number desc")
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Number", "Date",
              "Date Invoice", "Invoice", "Faktur Pajak",
              "Supplier", "Currency", "TOP", 
              "DPP", "PPN", "AMOUNT", 
              "Invoice Asli", "Faktur Pajak Asli", "Faktur Pajak Copy", "Surat Jalan DO asli", "GRN asli (Jika PO sistem)", "PO Copy",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              invoice_supplier_receiving = record.invoice_supplier_receiving

              content_row = [c+=1, invoice_supplier_receiving.status, 
                record.index_number, invoice_supplier_receiving.date,
                record.invoice_date, 
                record.invoice_number, 
                record.fp_number, 
                "#{invoice_supplier_receiving.supplier.name if invoice_supplier_receiving.supplier.present?}", 
                "#{record.currency.name if record.currency.present?}",
                "#{invoice_supplier_receiving.supplier.top_day if invoice_supplier_receiving.supplier.present?} #{invoice_supplier_receiving.supplier.term_of_payment.name if invoice_supplier_receiving.supplier.present?}",
                record.dpp, record.ppn, record.total,
                invoice_supplier_receiving.check_list1,
                invoice_supplier_receiving.check_list2,
                invoice_supplier_receiving.check_list3,
                invoice_supplier_receiving.check_list4,
                invoice_supplier_receiving.check_list5,
                invoice_supplier_receiving.check_list6,
                invoice_supplier_receiving.created_at, account_name(invoice_supplier_receiving.created_by), invoice_supplier_receiving.updated_at, account_name(invoice_supplier_receiving.updated_by), 
                invoice_supplier_receiving.approved1_at, account_name(invoice_supplier_receiving.approved1_by), invoice_supplier_receiving.approved2_at, account_name(invoice_supplier_receiving.approved2_by),  invoice_supplier_receiving.approved3_at, account_name(invoice_supplier_receiving.approved3_by),
                invoice_supplier_receiving.canceled1_at, account_name(invoice_supplier_receiving.canceled1_by), invoice_supplier_receiving.canceled2_at, account_name(invoice_supplier_receiving.canceled2_by),  invoice_supplier_receiving.canceled3_at, account_name(invoice_supplier_receiving.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
      when "supplier_ap_recaps"  
        periode_yyyy = (params[:periode_yyyy].present? ? params[:periode_yyyy] : DateTime.now().strftime("%Y"))
        records = SupplierApRecap.where("periode between ? and ?", "#{periode_yyyy}01", "#{periode_yyyy}12") 
        filename = "Rekap AP"
        
        wb.add_worksheet(name: "#{periode_yyyy}") do |sheet|
          c = 1
          sheet.add_row ["", "RANGKUMAN AP Hutang & Pembayaran #{periode_yyyy}"]
          header_row1 = ["No", "Supplier"]
          Date::MONTHNAMES.each do |month|
            if month.present?
              header_row1 += [month, "", ""]
            end
          end
          header_row2 = ["", ""]
          (1..12).each do 
             header_row2 += ["Hutang", "Pembayaran", "Sisa AP"]
          end

          sheet.merge_cells("B1:AL1")
          sheet.merge_cells("A2:A3")
          sheet.merge_cells("B2:B3")

          sheet.merge_cells("C2:E2")
          sheet.merge_cells("F2:H2")
          sheet.merge_cells("I2:K2")
          sheet.merge_cells("L2:N2")
          sheet.merge_cells("O2:Q2")
          sheet.merge_cells("R2:T2")
          sheet.merge_cells("U2:W2")
          sheet.merge_cells("X2:Z2")
          sheet.merge_cells("AA2:AC2")
          sheet.merge_cells("AD2:AF2")
          sheet.merge_cells("AG2:AI2")
          sheet.merge_cells("AJ2:AL2")
          sheet.add_row header_row1
          sheet.add_row header_row2
          
          records.each do |h|
            item_row = [
              c, (h.supplier.name.to_s if h.supplier.present?),
            ]
            
            Date::MONTHNAMES.each do |month|
              if month.present?
                sum_debt = records.where(:supplier_id=> h.supplier_id, :periode=> month.to_date.strftime("%Y%m")).sum(:debt)
                sum_pay =  records.where(:supplier_id=> h.supplier_id, :periode=> month.to_date.strftime("%Y%m")).sum(:payment)
                

                item_row += [sum_debt, sum_pay, (sum_debt - sum_pay)]
              end
            end
            c+=1
            sheet.add_row item_row
          end
        end
      when "supplier_ap_summaries"
        records = InvoiceSupplierReceivingItem.where(:status=> 'active').includes(:invoice_supplier_receiving).where(:invoice_supplier_receivings => {:company_profile_id => current_user.company_profile_id }).where("invoice_supplier_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("invoice_supplier_receivings.number desc") 
        filename = "RANGKUMAN AP"
        wb.add_worksheet(name: filename) do |sheet|
          c = 1
          sheet.add_row ["", "RANGKUMAN AP:","#{session[:date_begin]} s/d #{session[:date_end]}"] 

          sheet.add_row ["No", "No.Index", "Supplier", "Invoice", "Tgl.Invoice", "Tgl.Terima Invoice", "Payment Due Date", "Mata Uang", "Amount", "Pengecekan 1", "", "", "Pengecekan 2", "", "", "", "", "Pengecekan Mr Yap", "", "", "", "","Pengecekan Pak Johnny", "", "", "", "", "Pengecekan Pak Peter", "", "", "", "", "Payment", "", "", "", "Kelengkapan DC", "Sisa AP"]              
          sheet.add_row ["", "", "", "", "", "", "", "", "", "Target Selesai", "Tgl.Selesai", "Terlambat (Hari)", "Tgl.Diserahkan", "Target Selesai", "Tgl.Selesai", "Terlambat (Hari)", "Note", "Tgl.Diserahkan", "Target Selesai", "Tgl.Selesai", "Terlambat (Hari)", "Note", "Tgl.Diserahkan", "Target Selesai", "Tgl.Selesai", "Terlambat (Hari)", "Note", "Tgl.Diserahkan", "Target Selesai", "Tgl.Selesai", "Terlambat (Hari)", "Note", "Tgl.Payment", "Terlambat (Hari)","Note", "Amount"  ] 
          sheet.merge_cells("A2:A3")            
          sheet.merge_cells("B2:B3")            
          sheet.merge_cells("C2:C3")            
          sheet.merge_cells("D2:D3")          
          sheet.merge_cells("E2:E3")              
          sheet.merge_cells("F2:F3")            
          sheet.merge_cells("G2:G3")            
          sheet.merge_cells("H2:H3")            
          sheet.merge_cells("I2:I3")  

          sheet.merge_cells("J2:L2")  
          sheet.merge_cells("M2:Q2")  
          sheet.merge_cells("R2:V2")  
          sheet.merge_cells("W2:AA2") 
          sheet.merge_cells("AB2:AF2")  
          sheet.merge_cells("AG2:AJ2")  

          sheet.merge_cells("AK2:AK3")  
          sheet.merge_cells("AL2:AL3")  

          records.each do |h|
            sheet.add_row [
              c, h.index_number, 
              (h.invoice_supplier_receiving.supplier.name.to_s if h.invoice_supplier_receiving.present? and h.invoice_supplier_receiving.supplier.present?),
              h.invoice_number, h.invoice_date,
              (h.invoice_supplier_receiving.date if h.invoice_supplier_receiving_id.present?),
              (h.invoice_supplier_receiving.due_date if h.invoice_supplier_receiving_id.present?),
              (h.currency.name if h.currency.present?), h.total,
              (h.due_date_checked1.present? ? h.due_date_checked1 : (h.invoice_supplier_receiving.date.to_date+4.day if h.invoice_supplier_receiving_id.present?)), 
              h.date_checked1, ((h.date_checked1 - h.due_date_checked1).to_i if h.date_checked1.present? and h.due_date_checked1.present?),
              h.date_receive_checked2, h.due_date_checked2, h.date_checked2, ((h.date_checked2 - h.due_date_checked2).to_i if h.date_checked2.present? and h.due_date_checked2.present?), h.note_checked2,
              h.date_receive_checked3, h.due_date_checked3, h.date_checked3, ((h.date_checked3 - h.due_date_checked3).to_i if h.date_checked3.present? and h.due_date_checked3.present?), h.note_checked3,
              h.date_receive_checked4, h.due_date_checked4, h.date_checked4, ((h.date_checked4 - h.due_date_checked4).to_i if h.date_checked4.present? and h.due_date_checked4.present?), h.note_checked4,
              h.date_receive_checked5, h.due_date_checked5, h.date_checked5, ((h.date_checked5 - h.due_date_checked5).to_i if h.date_checked5.present? and h.due_date_checked5.present?), h.note_checked5,
              h.date_payment, ((h.date_payment - h.invoice_supplier_receiving.due_date).to_i if h.invoice_supplier_receiving_id.present? and h.date_payment.present?), h.remarks, h.amount_payment, 
              h.completeness_dc, (h.total - h.amount_payment)
            ]
            c+=1                
          end
          
        end
      when "bill_of_materials"
        records = BillOfMaterial.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id)
        filename = "Bill of Materials"
        records.each do |header|
          wb.add_worksheet(name: "#{header.product.part_id}") do |sheet|
            c = 1

            sheet.add_row ["No", "Material Name", "Material Code", "Standard Quantity", "Allowance", "Quantity", "Unit Name", "Remarks"]              
            BillOfMaterialItem.where(:bill_of_material_id=> header.id, :status=> 'active').each do |item|
              sheet.add_row [
                c, "#{item.material.name if item.material.present?}", "#{item.material.part_id if item.material.present?}",
                item.standard_quantity, item.allowance, item.quantity, "#{item.material.unit_name if item.material.present?}",
                item.remarks
              ]
              c+=1                
            end
            
          end
        end
      when "delivery_orders"
        filename = "Delivery Orders"
              
        case params[:view_kind]
        when 'item'
          items = DeliveryOrderItem.where(:status=> 'active')
          .includes(:product_batch_number, product: [:product_type, :product_sub_category, :unit], delivery_order: [:customer, :sales_order, :invoice_customer, :picking_slip, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3]).where(:delivery_orders => {:company_profile_id => current_user.company_profile_id }).where("delivery_orders.date between ? and ?", session[:date_begin], session[:date_end])
          .order("delivery_orders.number desc, products.part_id desc")
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Customer", "Invoice customer", "Sales order", "PO Number",
              "Picking slip", 
              "DO Number", "Date", "Vehicle number", "Vehicle driver name", "Remarks", 
              "Batch Number", "Product Code", "Product Name", "Product Type", "Quantity", "Unit", "Sub Category Product","Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              record = item.delivery_order
              content_row = [c+=1, item.delivery_order.status, "#{item.delivery_order.customer.name if item.delivery_order.customer.present?}", "#{item.delivery_order.invoice_customer.number if item.delivery_order.invoice_customer.present?}", "#{item.delivery_order.sales_order.number if item.delivery_order.sales_order.present?}", "#{item.delivery_order.sales_order.po_number if item.delivery_order.sales_order.present?}",
                "#{item.delivery_order.picking_slip.number if item.delivery_order.picking_slip.present?}",
                item.delivery_order.number, item.delivery_order.date, item.delivery_order.vehicle_number, item.delivery_order.vehicle_driver_name, item.delivery_order.remarks,
                item.product_batch_number.number, item.product.part_id, item.product.name, item.product.type_name, item.quantity, item.product.unit_name, "#{item.product.product_sub_category.name if item.product.product_sub_category.present?}", item.remarks,
                
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
               ]
              sheet.add_row content_row
            end
          end
        else
          records = DeliveryOrder.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end]).includes([:sales_order, :picking_slip, :invoice_customer, :customer, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3])
    
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Customer", "Invoice customer", "Sales order", "PO Number",
              "Picking slip", 
              "DO Number", "Date", "Vehicle number", "Vehicle driver name", "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, "#{record.customer.name if record.customer.present?}", "#{record.invoice_customer.number if record.invoice_customer.present?}", "#{record.sales_order.number if record.sales_order.present?}", "#{record.sales_order.po_number if record.sales_order.present?}",
                "#{record.picking_slip.number if record.picking_slip.present?}",
                record.number, record.date, record.vehicle_number, record.vehicle_driver_name, record.remarks,
                
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
               ]
              sheet.add_row content_row
            end
          end
        end
      when "invoice_customers"
        filename = "Invoice Customers"
              
        case params[:view_kind]
        when 'item'
        else
          records = InvoiceCustomer.where(:company_profile_id=> current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end]).includes([:term_of_payment, :customer_tax_invoice, :customer, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3])
          .order("invoice_customers.number desc")
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Customer", "Invoice customer", 
              "Payment Terms", "E-Faktur", "Invoice Date", "Due Date", "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              efatur_number = (record.customer_tax_invoice.present? ? record.customer_tax_invoice.number : record.efaktur_number)
              content_row = [c+=1, record.status, "#{record.customer.name if record.customer.present?}",
                record.number, "#{record.term_of_payment.present? ? record.term_of_payment.name : nil}", efatur_number,
                record.date, record.due_date, record.remarks,                
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
               ]
              sheet.add_row content_row, :types => [:integer, :string, :string, :string, :string, :string]
            end
          end
        end

        items = InvoiceCustomerItem.where(:status=> 'active')
        .includes(:product_batch_number, delivery_order_item: [:delivery_order], sales_order_item: [:sales_order], product: [:product_type, :unit], invoice_customer: [:term_of_payment, :customer_tax_invoice, :customer, :created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3])
        .where(:invoice_customers => {:company_profile_id => current_user.company_profile_id, :date=> session[:date_begin]..session[:date_end]})
        .order("invoice_customers.number desc, products.part_id desc")
        
        wb.add_worksheet(name: "detail") do |sheet|
          header_row = ["No.", "Status", "Customer", "Invoice customer", 
            "Payment Terms", "E-Faktur", "Invoice Date", "Due Date", "Remarks", 
            "DO Number", "PO Number",
            "Product Code", "Product Name", "Product Type",
            "Batch Number", "Quantity", "Unit", "Unit Price", 
            "Discount", "Sub total", "PPN", "Grand Total", 
            "Created at", "Created by", "Updated at", "Updated by", 
            "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
            "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
          ]
          sheet.add_row header_row
          c = 0
          items.each do |item|
            record = item.invoice_customer
            delivery_order = item.delivery_order_item.delivery_order
            sales_order = item.sales_order_item.sales_order
            efatur_number = (record.customer_tax_invoice.present? ? record.customer_tax_invoice.number : record.efaktur_number)
            
            content_row = [c+=1, record.status, "#{record.customer.name if record.customer.present?}",
              record.number, "#{record.term_of_payment.present? ? record.term_of_payment.name : nil}", efatur_number,
              record.date, record.due_date, record.remarks, 
              delivery_order.number, sales_order.po_number,        
              item.product.part_id, item.product.name, item.product.product_type.name,
              item.product_batch_number.number, item.quantity, item.product.unit.name, item.unit_price, 
              record.discount, record.subtotal, record.ppntotal, record.grandtotal,
              record.created_at, (record.created.present? ? record.created.first_name : nil), 
              record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
              record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
              record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
              record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
              record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
              record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
             ]
            sheet.add_row content_row, :types => [:integer, :string, :string, :string, :string, :string]
          end
        end
      when "sales_orders"
        filename = "Sales Orders"
        case params[:view_kind]
        when 'item'
          items = SalesOrderItem.where(:status=> 'active')
          .includes(:product, sales_order: [:customer]).where(:sales_orders => {:company_profile_id => current_user.company_profile_id }).where("sales_orders.date between ? and ?", session[:date_begin], session[:date_end]).order("sales_orders.number desc")      
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Kode Customer","Customer",
              "Sales order", "Date", "PO Number", "PO Received", "Month Delivery", "Remarks", 
              "Product Code", "Product Name", "Product Type", "Quantity", "Outstanding", "Unit", 
              "Harga", "Harga Total", "Due Date",
              "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              sales_order = item.sales_order
              customer    = sales_order.customer if sales_order.present?

              content_row = [c+=1, item.sales_order.status, 
                "#{customer.number if customer.present?}", 
                "#{customer.name if customer.present?}",  
                "#{item.sales_order.number if item.sales_order.present?}", 
                item.sales_order.present? ? item.sales_order.date : nil, 
                "#{item.sales_order.po_number if item.sales_order.present?}", 
                item.sales_order.present? ? item.sales_order.po_received : nil, 
                "#{item.sales_order.month_delivery if item.sales_order.present?}",  
                "#{item.sales_order.remarks if item.sales_order.present?}",
                item.product.part_id, item.product.name, item.product.type_name, item.quantity, item.outstanding, item.product.unit_name, 
                "#{item.unit_price}", "#{item.unit_price.to_f*item.quantity.to_f}", item.due_date,
                item.remarks,
                item.sales_order.created_at, account_name(item.sales_order.created_by), item.sales_order.updated_at, account_name(item.sales_order.updated_by), 
                item.sales_order.approved1_at, account_name(item.sales_order.approved1_by), item.sales_order.approved2_at, account_name(item.sales_order.approved2_by),  item.sales_order.approved3_at, account_name(item.sales_order.approved3_by),
                item.sales_order.canceled1_at, account_name(item.sales_order.canceled1_by), item.sales_order.canceled2_at, account_name(item.sales_order.canceled2_by),  item.sales_order.canceled3_at, account_name(item.sales_order.canceled3_by)

               ]
              sheet.add_row content_row, :types => [:integer, :string, :string, :string, :string, :date]
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Customer", 
              "Sales order", "Date", "PO Number", "PO Received", "Month Delivery", "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, "#{record.customer.name if record.customer.present?}", 
                "#{record.number}", record.date, "#{record.po_number}", record.po_received, record.month_delivery, record.remarks,
                record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

               ]
              sheet.add_row content_row, :types => [:integer, :string, :string, :string, :date, :string, :date]
            end
          end
        end
      when "production_orders"
        filename = "Production Orders (SPP)"
        case params[:view_kind]
        when 'item'
          items = ProductionOrderItem.where(:status=> 'active')
          .includes(:product)
          .includes(:production_order).where(:production_orders => {:company_profile_id => current_user.company_profile_id }).where("production_orders.date between ? and ?", session[:date_begin], session[:date_end]).order("production_orders.number desc")      
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "SPP Number", "SPP Date", "SO Number", "PO Customer", "Customer",
              "Remarks", 
              "Product Code", "Product Name", "Product Type", "Quantity", "Unit", "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              sales_order = item.production_order.sales_order
              content_row = [c+=1, item.production_order.status, 

                "#{item.production_order.number if item.production_order.present?}",
                "#{item.production_order.date if item.production_order.present?}",
                "#{sales_order.number if sales_order.present?}",
                "#{sales_order.po_number if sales_order.present?}",
                "#{sales_order.present? ? (sales_order.customer.present? ? sales_order.customer.name : "-") : "-"}",
                "#{item.production_order.remarks if item.production_order.present?}",
                item.product.part_id, item.product.name, item.product.type_name, item.quantity, item.product.unit_name, item.remarks,
                item.production_order.created_at, account_name(item.production_order.created_by), item.production_order.updated_at, account_name(item.production_order.updated_by), 
                item.production_order.approved1_at, account_name(item.production_order.approved1_by), item.production_order.approved2_at, account_name(item.production_order.approved2_by),  item.production_order.approved3_at, account_name(item.production_order.approved3_by),
                item.production_order.canceled1_at, account_name(item.production_order.canceled1_by), item.production_order.canceled2_at, account_name(item.production_order.canceled2_by),  item.production_order.canceled3_at, account_name(item.production_order.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end

          production_order_detail_materials = ProductionOrderDetailMaterial.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').includes(:production_order, :material,
            product: [:product_type]).where(:production_orders => {:company_profile_id => current_user.company_profile_id, :date=> session[:date_begin] .. session[:date_end] }).order("production_orders.number desc")

          wb.add_worksheet(name: "Detail Material") do |sheet|
            header_row = ["No.", "Status", "SPP Number", "SPP Date",
              "Jenis PRF",
              "Product Name", "Product Code", "Product Type", 
              "Material Name", "Material Code", 
              "Quantity", "PRF Outstanding"
            ]
            sheet.add_row header_row
            c = 0
            production_order_detail_materials.each do |detail|
              content_row = [c+=1, detail.production_order.status, detail.production_order.number, detail.production_order.date,
                detail.prf_kind == 'services' ? "Jasa" : detail.prf_kind,
                "#{detail.product.part_id if detail.product.present?}", "#{detail.product.name if detail.product.present?}", "#{detail.product.type_name if detail.product.present?}",
                "#{detail.material.part_id if detail.material.present?}", "#{detail.material.name if detail.material.present?}",
                detail.quantity, detail.prf_outstanding
              ]
              sheet.add_row content_row
            end

          end
        else
          if params[:id].present?
            record = ProductionOrder.find_by(:id=> params[:id])
            production_order_detail_materials = ProductionOrderDetailMaterial.where(:company_profile_id=> current_user.company_profile_id, :production_order_id=> record.id, :status=> 'active')
            production_order_used_prf = ProductionOrderUsedPrf.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :production_order_detail_material_id=> production_order_detail_materials.select(:id))

            if record.present?
              wb.add_worksheet(name: filename) do |sheet|
                sheet.add_row ["", "SPP Number:", record.number]
                sheet.add_row ["", "SPP Date:", record.date]
                sheet.add_row ["", "SO Number:", (record.sales_order.present? ? record.sales_order.number : "-")]
                sheet.add_row ["", "PO Customer:", (record.sales_order.present? ? record.sales_order.po_number : "-")]
                sheet.add_row ["", "Customer:", (record.sales_order.present? ? (record.sales_order.customer.present? ? record.sales_order.customer.name : "-") : "-")]
                sheet.add_row [""]
                sheet.add_row ["", "PRF Material"]
                sheet.add_row ["No.", "Product Name", "Product Code", "Product Type", "Material Name", "Material Code", "Quantity PRF", "Outstanding PRF", "PRF List"]
                c = 0
                production_order_detail_materials.where(:prf_kind=> 'material').each do |detail|
                  content_row = [
                    "#{c+=1}", 
                    detail.product.name, detail.product.part_id, detail.product.type_name,
                    detail.material.name, detail.material.part_id,
                    detail.quantity, detail.prf_outstanding,
                    "#{production_order_used_prf.where(:production_order_detail_material_id=> detail.id, :production_order_item_id=> detail.production_order_item_id).map { |e| e.purchase_request_item.purchase_request.number if e.purchase_request_item.present? and e.purchase_request_item.purchase_request.present?}.uniq.join(", ")}"
                  ]
                  sheet.add_row content_row
                end

                sheet.add_row [""]
                sheet.add_row ["", "PRF Jasa"]
                sheet.add_row ["No.", "Product Name", "Product Code", "Product Type", "","", "Quantity PRF", "Outstanding PRF", "PRF List"]
                production_order_detail_materials.where(:prf_kind=> 'services').each do |detail|
                  content_row = [
                    "#{c+=1}", 
                    detail.product.name, detail.product.part_id, detail.product.type_name, "", "",
                    detail.quantity, detail.prf_outstanding,
                    "#{production_order_used_prf.where(:production_order_detail_material_id=> detail.id, :production_order_item_id=> detail.production_order_item_id).map { |e| e.purchase_request_item.purchase_request.number if e.purchase_request_item.present? and e.purchase_request_item.purchase_request.present?}.uniq.join(", ")}"
                  ]
                  sheet.add_row content_row
                end
              end
            end
          else
            records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end])
            .includes(sales_order: [:customer])
            .order("date desc")       
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "Status", "SPP Number", "SPP Date", "SO Number", "PO Customer", "Customer",
                "Remarks", 
                "Created at", "Created by", "Updated at", "Updated by", 
                "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
                "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
              ]
              sheet.add_row header_row
              c = 0
              records.each do |record|
                sales_order = record.sales_order

                content_row = [c+=1, record.status, record.number, record.date, 
                  (sales_order.present? ? sales_order.number : "-"), 
                  (sales_order.present? ? sales_order.po_number : "-"), 
                  (sales_order.present? ? "#{sales_order.customer.present? ? sales_order.customer.name : '-'}" : "-"), 
                  record.remarks,
                  record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                  record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                  record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

                 ]
                sheet.add_row content_row
              end
            end
          end
        end
      when "pdms"
        filename = "PDM"
        case params[:view_kind]
        when 'item'
          items = PdmItem.where(:status=> 'active')
          .includes(:material)
          .includes(:pdm).where(:pdms => {:company_profile_id => current_user.company_profile_id }).where("pdms.date between ? and ?", session[:date_begin], session[:date_end]).order("pdms.number desc")      
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "PDM Number", "PDM Date",
              "Remarks", 
              "Product Code", "Product Name", "Quantity", "Outstanding", "Unit", "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              content_row = [c+=1, item.pdm.status, 

                "#{item.pdm.number if item.pdm.present?}",
                "#{item.pdm.date if item.pdm.present?}",
                "#{item.pdm.remarks if item.pdm.present?}",
                item.material.part_id, item.material.name, item.quantity, item.outstanding, item.material.unit_name, item.remarks,
                item.pdm.created_at, account_name(item.pdm.created_by), item.pdm.updated_at, account_name(item.pdm.updated_by), 
                item.pdm.approved1_at, account_name(item.pdm.approved1_by), item.pdm.approved2_at, account_name(item.pdm.approved2_by),  item.pdm.approved3_at, account_name(item.pdm.approved3_by),
                item.pdm.canceled1_at, account_name(item.pdm.canceled1_by), item.pdm.canceled2_at, account_name(item.pdm.canceled2_by),  item.pdm.canceled3_at, account_name(item.pdm.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "PDM Number", "PDM Date",  
              "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, record.number, record.date, 
                record.remarks,
                record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "purchase_requests"
        filename = "PRF"
        case params[:view_kind]
        when 'item'
          items = PurchaseRequestItem.where(:status=> 'active')
          .includes(
            production_order_used_prves: [production_order_item: [:production_order]],
            product: [:unit], 
            material: [:unit], 
            consumable: [:unit], 
            equipment: [:unit], 
            general: [:unit], 
            purchase_request: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :department],
            )
          .where(:purchase_requests => {:company_profile_id => current_user.company_profile_id, :request_kind=> params[:q] }).where("purchase_requests.date between ? and ?", session[:date_begin], session[:date_end]).order("purchase_requests.number desc")      

          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "PRF Number", "PRF Date", "SPP Number", 
              "Remarks", 
              "Product Code", "Product Name", "Quantity", "Outstanding", "Unit", "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              record = item.purchase_request
              part_id = part_name = part_unit = nil
              if item.product.present?
                part_id = item.product.part_id
                part_name = item.product.name
                part_unit = item.product.unit.name
              elsif item.material.present?
                part_id = item.material.part_id
                part_name = item.material.name
                part_unit = item.material.unit.name
              elsif item.consumable.present?
                part_id = item.consumable.part_id
                part_name = item.consumable.name
                part_unit = item.consumable.unit.name
              elsif item.equipment.present?
                part_id = item.equipment.part_id
                part_name = item.equipment.name
                part_unit = item.equipment.unit.name
              elsif item.general.present?
                part_id = item.general.part_id
                part_name = item.general.name
                part_unit = item.general.unit.name
              end

              content_row = [c+=1, record.status, 

                "#{record.number if record.present?}",
                "#{record.date if record.present?}",
                item.production_order_used_prves.map { |e| e.production_order_item.production_order.number if e.status == 'active'}.uniq.join(", "),
                "#{record.remarks if record.present?}",
                part_id, part_name, item.quantity, item.outstanding, part_unit, item.remarks,

                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)
               ]
              sheet.add_row content_row
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).where(:request_kind=> params[:q])
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, :department, purchase_request_items: [:production_order_used_prves])
          .order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Basic Request", "Department", "PRF Number", "PRF Date",  
              "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, record.basic_request, "#{record.department.present? ? record.department.name : nil}",
                record.number, record.date, 
                record.remarks,
                record.created_at, (record.created.present? ? record.created.first_name : nil), 
                record.approved1_at, (record.approved1.present? ? record.approved1.first_name : nil), 
                record.approved2_at, (record.approved2.present? ? record.approved2.first_name : nil), 
                record.approved3_at, (record.approved3.present? ? record.approved3.first_name : nil), 
                record.canceled1_at, (record.canceled1.present? ? record.canceled1.first_name : nil), 
                record.canceled2_at, (record.canceled2.present? ? record.canceled2.first_name : nil), 
                record.canceled3_at, (record.canceled3.present? ? record.canceled3.first_name : nil)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "purchase_order_suppliers"
        filename = "PO Supplier"
        case params[:view_kind]
        when 'item'
          items = PurchaseOrderSupplierItem.where(:status=> 'active')
          .includes(
            purchase_request_item: [material: [:unit], product: [:unit], consumable: [:unit], equipment: [:unit], general: [:unit]], 
            pdm_item: [:material])
          .includes(purchase_order_supplier: [:supplier]).where(:purchase_order_suppliers => {:company_profile_id => current_user.company_profile_id }).where("purchase_order_suppliers.date between ? and ?", session[:date_begin], session[:date_end]).order("purchase_order_suppliers.date desc")      
          
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Supplier Name", "PO Number", "PO Date",
              "Remarks", 
              "PRF/ PDM", "PRF/ PDM Remarks",
              "Product Code", "Product Name", "Quantity", "Outstanding", "Unit Price", "Total", "Unit", "Remarks Item",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              prf_item   = nil
              prf_number = ""
              part_id    = ""
              part_name  = ""
              unit_name  = ""
              if item.purchase_request_item.present?
                prf_item = item.purchase_request_item
                prf_number  = prf_item.purchase_request.number
                prf_remarks = prf_item.purchase_request.remarks

                if prf_item.material.present?
                  part_id = prf_item.material.part_id
                  part_name = prf_item.material.name
                  unit_name = prf_item.material.unit.name
                elsif prf_item.product.present?
                  part_id = prf_item.product.part_id
                  part_name = prf_item.product.name
                  unit_name = prf_item.product.unit.name
                elsif prf_item.consumable.present?
                  part_id = prf_item.consumable.part_id
                  part_name = prf_item.consumable.name
                  unit_name = prf_item.consumable.unit.name
                elsif prf_item.equipment.present?
                  part_id = prf_item.equipment.part_id
                  part_name = prf_item.equipment.name
                  unit_name = prf_item.equipment.unit.name
                elsif prf_item.general.present?
                  part_id = prf_item.general.part_id
                  part_name = prf_item.general.name
                  unit_name = prf_item.general.unit.name
                end
              elsif item.pdm_item.present?
                prf_item = item.pdm_item
                prf_number = prf_item.pdm.number
                prf_remarks = prf_item.pdm.remarks
                
                if prf_item.material.present?
                  part_id = prf_item.material.part_id
                  part_name = prf_item.material.name
                  unit_name = prf_item.material.unit.name
                end
              end

              content_row = [c+=1, item.purchase_order_supplier.status, 
                item.purchase_order_supplier.supplier.name,
                "#{item.purchase_order_supplier.number if item.purchase_order_supplier.present?}",
                "#{item.purchase_order_supplier.date if item.purchase_order_supplier.present?}",
                "#{item.purchase_order_supplier.remarks if item.purchase_order_supplier.present?}",
                "#{prf_number}", "#{prf_remarks}", part_id, part_name, item.quantity, item.outstanding,
                item.unit_price, "#{item.unit_price.to_f*item.quantity.to_f}", 
                unit_name, item.remarks,
                item.purchase_order_supplier.created_at, account_name(item.purchase_order_supplier.created_by), item.purchase_order_supplier.updated_at, account_name(item.purchase_order_supplier.updated_by), 
                item.purchase_order_supplier.approved1_at, account_name(item.purchase_order_supplier.approved1_by), item.purchase_order_supplier.approved2_at, account_name(item.purchase_order_supplier.approved2_by),  item.purchase_order_supplier.approved3_at, account_name(item.purchase_order_supplier.approved3_by),
                item.purchase_order_supplier.canceled1_at, account_name(item.purchase_order_supplier.canceled1_by), item.purchase_order_supplier.canceled2_at, account_name(item.purchase_order_supplier.canceled2_by),  item.purchase_order_supplier.canceled3_at, account_name(item.purchase_order_supplier.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")       
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "PDM Number", "PDM Date",  
              "Remarks", "Total Amount",
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, record.number, record.date, 
                record.remarks, record.total_amount,
                record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "inventories", "temporary_inventories"
        filename = "#{controller_name}"
        records = controller_name.singularize.camelize.constantize.where(:periode=> params[:periode])
        case params[:invetory_kind]
        when 'product'
          records = records.where("product_id > 0 ")
        when 'material'
          records = records.where("material_id > 0 ")
        end
        wb.add_worksheet(name: filename) do |sheet|
          header_row = ["No.", "Periode", "Part Code", "Nama", "Type", "Stok Awal", "Transaksi Masuk", "Transaksi Keluar", "Stok Akhir"
          ]
          sheet.add_row header_row
          c = 0
          records.each do |record|
            part = nil
            type_name = nil
            if record.product.present?
              part = record.product
              type_name = "#{part.type_name if part.present?}"
            elsif record.material.present?
              part = record.material
            end
            content_row = [c+=1, 
              record.periode,
              "#{part.part_id if part.present?}", 
              "#{part.name if part.present?}", 
              "#{type_name}", 
              record.begin_stock, 
              record.trans_in, 
              record.trans_out,
              record.end_stock
             ]
            sheet.add_row content_row
          end
        end
      when "shop_floor_orders"
        filename = "Shop Floor Orders"        
        case params[:view_kind]
        when 'item','outstanding'
          items = ShopFloorOrderItem.where(:status=> 'active')
          .includes(:product)
          .includes(:shop_floor_order).where(:shop_floor_orders => {:company_profile_id => current_user.company_profile_id }).where("shop_floor_orders.date between ? and ?", session[:date_begin], session[:date_end])
          .order("shop_floor_orders.number desc, products.part_id desc")
          
          case params[:view_kind]
          when 'outstanding'
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "Doc.Number", "PO Number", "Product Code", "Product Name", "Batch Number", "Unit", "Qty", "Outstanding"
              ]
              sheet.add_row header_row
              c = 0
              items.each do |item|
                product_batch_number = @product_batch_number.where(:shop_floor_order_item_id=> item.id).map { |e| e.number }.join(", ") if @product_batch_number.present?
                
                content_row = [c+=1, "#{item.shop_floor_order.present? ? item.shop_floor_order.number : nil}",
                  "#{(item.sales_order.present? ? item.sales_order.po_number : nil)}",
                  "#{(item.product.present? ? item.product.part_id : nil)}",
                  "#{(item.product.present? ? item.product.name : nil)}",
                  "#{product_batch_number}",
                  "#{(item.product.present? ? item.product.unit.name : nil)}", 
                  item.quantity,
                  "#{@product_batch_number.find_by(:shop_floor_order_item_id=> item.id).outstanding if @product_batch_number.present?}"
                 ]
                sheet.add_row content_row
              end
            end
          when 'item'
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "Status", "Sales order", "PO Number",
                "Doc. Number", "Date", "Remarks", 
                "Batch Number", "Product Code", "Product Name", "Product Type", "Quantity", "Unit", "Remarks Item",
                "Created at", "Created by", "Updated at", "Updated by", 
                "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
                "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
              ]
              sheet.add_row header_row
              c = 0
              items.each do |item|
                product_batch_number = @product_batch_number.where(:shop_floor_order_item_id=> item.id).map { |e| e.number }.join(", ") if @product_batch_number.present?
                content_row = [c+=1, item.shop_floor_order.status, "#{item.sales_order.number if item.sales_order.present?}", "#{item.sales_order.po_number if item.sales_order.present?}",
                  item.shop_floor_order.number, item.shop_floor_order.date, item.shop_floor_order.remarks,
                  product_batch_number, 
                  "#{item.product.part_id if item.product.present?}", 
                  "#{item.product.name if item.product.present?}", 
                  "#{item.product.type_name if item.product.present?}", item.quantity, 
                  "#{item.product.unit_name if item.product.present?}", item.remarks,
                  item.shop_floor_order.created_at, account_name(item.shop_floor_order.created_by), item.shop_floor_order.updated_at, account_name(item.shop_floor_order.updated_by), 
                  item.shop_floor_order.approved1_at, account_name(item.shop_floor_order.approved1_by), item.shop_floor_order.approved2_at, account_name(item.shop_floor_order.approved2_by),  item.shop_floor_order.approved3_at, account_name(item.shop_floor_order.approved3_by),
                  item.shop_floor_order.canceled1_at, account_name(item.shop_floor_order.canceled1_by), item.shop_floor_order.canceled2_at, account_name(item.shop_floor_order.canceled2_by),  item.shop_floor_order.canceled3_at, account_name(item.shop_floor_order.canceled3_by)

                 ]
                sheet.add_row content_row
              end
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", 
              "Doc. Number", "Date", "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, 
                record.number, record.date, record.remarks,
                record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "shop_floor_order_sterilizations"
        filename = "SFO Sterilizations"        
        case params[:view_kind]
        when 'item','outstanding'
          items = ShopFloorOrderSterilizationItem.where(:status=> 'active')
          .includes(:product)
          .includes(:shop_floor_order_sterilization).where(:shop_floor_order_sterilizations => {:company_profile_id => current_user.company_profile_id }).where("shop_floor_order_sterilizations.date between ? and ?", session[:date_begin], session[:date_end])
          .order("shop_floor_order_sterilizations.number desc, products.part_id desc")
          
          case params[:view_kind]
          when 'outstanding'
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "Doc.Number", "Batch Number Sterilizations", "Product Code", "Product Name", "Batch Number", "Unit", "Qty", "Outstanding"
              ]
              sheet.add_row header_row
              c = 0
              items.each do |item|
                content_row = [c+=1, 
                  "#{item.shop_floor_order_sterilization.present? ? item.shop_floor_order_sterilization.number : nil}",
                  "#{item.shop_floor_order_sterilization.present? ? item.shop_floor_order_sterilization.sterilization_batch_number : nil}",
                  "#{(item.product.present? ? item.product.part_id : nil)}",
                  "#{(item.product.present? ? item.product.name : nil)}",
                  "#{item.product_batch_number.present? ? item.product_batch_number.number : nil }", 
                  "#{(item.product.present? ? item.product.unit.name : nil)}", 
                  item.quantity,
                  item.outstanding
                 ]
                sheet.add_row content_row
              end
            end
          when 'item'
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "Status", "Kind",
                "Doc. Number", "Batch Number Sterilization", "Date", "Remarks", 
                "Batch Number", "Product Code", "Product Name", "Product Type", "Quantity", "Unit", "Remarks Item",
                "Created at", "Created by", "Updated at", "Updated by", 
                "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
                "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
              ]
              sheet.add_row header_row
              c = 0
              items.each do |item|
                content_row = [c+=1, item.shop_floor_order_sterilization.status, item.shop_floor_order_sterilization.kind,
                  item.shop_floor_order_sterilization.number, item.shop_floor_order_sterilization.sterilization_batch_number,
                  item.shop_floor_order_sterilization.date, item.shop_floor_order_sterilization.remarks,
                  "#{item.product_batch_number.present? ? item.product_batch_number.number : nil }", 
                  "#{item.product.part_id if item.product.present?}", 
                  "#{item.product.name if item.product.present?}", 
                  "#{item.product.type_name if item.product.present?}", item.quantity, 
                  "#{item.product.unit_name if item.product.present?}", item.remarks,
                  item.shop_floor_order_sterilization.created_at, account_name(item.shop_floor_order_sterilization.created_by), item.shop_floor_order_sterilization.updated_at, account_name(item.shop_floor_order_sterilization.updated_by), 
                  item.shop_floor_order_sterilization.approved1_at, account_name(item.shop_floor_order_sterilization.approved1_by), item.shop_floor_order_sterilization.approved2_at, account_name(item.shop_floor_order_sterilization.approved2_by),  item.shop_floor_order_sterilization.approved3_at, account_name(item.shop_floor_order_sterilization.approved3_by),
                  item.shop_floor_order_sterilization.canceled1_at, account_name(item.shop_floor_order_sterilization.canceled1_by), item.shop_floor_order_sterilization.canceled2_at, account_name(item.shop_floor_order_sterilization.canceled2_by),  item.shop_floor_order_sterilization.canceled3_at, account_name(item.shop_floor_order_sterilization.canceled3_by)

                 ]
                sheet.add_row content_row
              end
            end
          end
        else
          records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "Status", "Kind",
              "ORDER NUMBER STERILIZATION", "BATCH NUMBER STERILIZATION", "Date", "Remarks", 
              "Created at", "Created by", "Updated at", "Updated by", 
              "Approved1 at", "Approved1 by", "Approved2 at", "Approved2 by", "Approved3 at", "Approved3 by", 
              "Canceled1 at", "Canceled1 by", "Canceled2 at", "Canceled2 by", "Canceled3 at", "Canceled3 by"
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, record.status, record.kind,
                record.number, record.sterilization_batch_number, record.date, record.remarks,
                record.created_at, account_name(record.created_by), record.updated_at, account_name(record.updated_by), 
                record.approved1_at, account_name(record.approved1_by), record.approved2_at, account_name(record.approved2_by),  record.approved3_at, account_name(record.approved3_by),
                record.canceled1_at, account_name(record.canceled1_by), record.canceled2_at, account_name(record.canceled2_by),  record.canceled3_at, account_name(record.canceled3_by)

               ]
              sheet.add_row content_row
            end
          end
        end
      when "employees"
        filename = "Daftar Karyawan"
        records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id).where(:employee_status=> params[:select_employee_status], :employee_legal_id=> params[:select_employee_legal_id])
        .includes(:department, :position, :work_status)
         
        kind      = "Daftar Karyawan #{params[:select_employee_status]}"
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","NIK", "NAMA", "DIVISI", "DEPARTEMEN", "JABATAN", "STATUS KERJA", "SCHEDULE KERJA", "JUMLAH OVERTIME", "TEMPAT","TANGGAL LAHIR", "AGAMA", "PTKP", "GOLONGAN DARAH", "SEX", "PENDIDIKAN","NO HP","EMAIL", "JURUSAN", "TANGGAL MASUK", "MULAI KERJA", "HABIS KONTRAK", "NO. KTP", "MASA BERLAKU KTP", "NPWP", "ALAMAT NPWP", "No. BPJS", "No. KPJ", "KLINIK BPJS", "ALAMAT KTP", "ALAMAT SEKARANG","PENEMPATAN KERJA","PAYROLL"]
          records.order("name asc").each do |r|
            origin_a = r.origin_address
            domicile_a = r.domicile_address
            npwp_a = r.npwp_address

            employee_payroll   = r.legality_name
            employee_placement = r.legality_name
            sheet.add_row [
               c,r.nik.to_s, 
               r.name.to_s,
              
              r.legality_name,
               (r.department.name.to_s if r.department.present?),  
               (r.position.name.to_s if r.position_id.present?), 
               (r.work_status.name.to_s if r.work_status.present?),
               (r.work_schedule[0..0].to_s if r.work_schedule.present?),
               (r.work_schedule[2..2].to_s if r.work_schedule.present?),   
               (r.born_place.to_s),
               (r.born_date.strftime("%d-%m-%Y").to_date if r.born_date.present?), 
               r.religion.to_s,
               case r.married_status
               when 'Tidak Kawin' 
                  "TK"
               when 'Kawin (3)' 
                  "K3"
               when 'Kawin (2)' 
                  "K2"
               when 'Kawin (1)' 
                  "K1"
               when 'Kawin (0)' 
                  "K0"
               else 
                  ""
               end, 
               r.blood.to_s,
               r.gender.to_s,
               r.last_education.to_s,
               r.phone_number.to_s,
               r.email_address.to_s,
               r.vocational_education.to_s,
               (r.join_date.strftime("%d-%m-%Y").to_date if r.join_date.present?) ,
               (r.begin_of_contract.strftime("%d-%m-%Y").to_date if r.begin_of_contract.present?) ,
               (r.end_of_contract.strftime("%d-%m-%Y").to_date if r.end_of_contract.present?) ,
               r.ktp.to_s,
               (r.ktp_expired_date.present? ? r.ktp_expired_date : "Seumur Hidup"),
               r.npwp.to_s,
               r.npwp_address.to_s, 
               r.bpjs.to_s,
               r.kpj_number.to_s, 
               r.bpjs_hospital.to_s,
               r.origin_address.to_s, 
               r.domicile_address.to_s,
               employee_placement.to_s, employee_payroll.to_s
              ] , :types => [:string, :string,:string,:string,:string,:string,:string,:string,:string,:string,:date,:string,:string,:string,:string,:string,:string,:string,:string,:date,:date,:date,:string,:string,:string,:string,:string,:string,:string,:string,:string,:string]
            c+=1
          end
        end   
      when "employee_contracts"
        #zulvan 08-04-21
        filename = "Daftar Karyawan Kontrak Provital"
        records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id)
        .includes(:department, :position, :work_status, :employee)
         
        kind      = "List Kontrak Provital"
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","No. Dokumen", "NIK", "NAMA", "DEPARTEMEN", "POSISI", "STATUS KERJA", "TANGGAL AWAL", "TANGGAL AKHIR", "GAJI POKOK", "TUNJANGAN MAKAN DAN TRANSPORT"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               r.number.to_s,
               r.employee.nik.to_s, 
               r.employee.name.to_s,
               (r.department.name.to_s if r.department.present?),  
               (r.position.name.to_s if r.position_id.present?), 
               (r.work_status.name.to_s if r.work_status.present?),
               (r.begin_of_contract.strftime("%d-%m-%Y").to_date),
               (r.end_of_contract.strftime("%d-%m-%Y").to_date),
               (r.basic_salary.to_s),
               (r.meal_and_transport_cost.to_s),
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :date, :date, :string, :string]
            c+=1
          end
        end
      when "employee_absences"
        #zulvan 08-04-21
        filename = "Daftar Pengajuan Cuti dan Izin"
        records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id).where("begin_date >= '#{params[:date_begin]}' and end_date <= '#{params[:date_end]}'")
        .includes(:employee_absence_type, :employee)
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","NIK", "NAMA", "DEPARTEMEN", "JABATAN", "KODE", "JENIS IZIN", "KETERANGAN", "JUMLAH HARI", "TANGGAL MULAI", "TANGGAL AKHIR", "STATUS DOKUMEN"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               r.employee.nik.to_s,
               r.employee.name.to_s,
               (r.employee.department.name.to_s if r.employee.department.present?),  
               (r.employee.position.name.to_s if r.employee.position_id.present?), 
               r.employee_absence_type.code,
               r.employee_absence_type.name,
               r.description,
               r.day,
               (r.begin_date.strftime("%d-%m-%Y").to_date),
               (r.end_date.strftime("%d-%m-%Y").to_date),
               (r.status),
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :date, :date, :string]
            c+=1
          end
        end
      when "list_external_bank_accounts"
        filename = "List Rekening Bank External"
        records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id)
        .includes(:dom_bank, :currency)
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["No.","Nama Rekening", "Currency", "Nama Bank", "No. Rekening", "Status"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               r.name_account,
               (r.currency.name.to_s if r.currency.present?),
               (r.dom_bank.bank_name.to_s if r.dom_bank.present?),
               r.number_account,
               r.status,
              ] , :types => [:string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when "list_internal_bank_accounts"
        filename = "List Internal Bank External"
        records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id)
        .includes(:dom_bank, :currency)
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["No.","Nama Rekening", "Currency", "Kode Voucher", "Nama Bank", "No. Rekening", "Status"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               r.name_account,
               (r.currency.name.to_s if r.currency.present?),
               r.code_voucher,
               (r.dom_bank.bank_name.to_s if r.dom_bank.present?),
               r.number_account,
               r.status,
              ] , :types => [:string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when "voucher_payment_receivings"
        filename = "Voucher Payment Received"
        case params[:view_kind]
        when 'item'
          items = VoucherPaymentReceivingItem.where(:status=> 'active')
          # .includes(:voucher_payment_receiving).where(:voucher_payment_receivings => {:company_profile_id => current_user.company_profile_id }).where("voucher_payment_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("voucher_payment_receivings.number desc")      
          .includes(:voucher_payment_receiving).where(:voucher_payment_receivings => {:company_profile_id => current_user.company_profile_id })      
          # Item
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "No. Voucher", "Nama Pengirim", "Tanggal Pembayaran", "No. Coa", "Nama Coa", "Keterangan", "Amount", "Status"
            ]
            sheet.add_row header_row
            c = 0
            items.each do |item|
              content_row = [c+=1, 
                "#{item.voucher_payment_receiving.number if item.voucher_payment_receiving.present?}", 
                "#{item.voucher_payment_receiving.name_account if item.voucher_payment_receiving.present?}", 
                "#{item.voucher_payment_receiving.date if item.voucher_payment_receiving.present?}", 
                item.coa_number,
                item.coa_name,
                item.description,
                number_with_precision(item.amount, precision: 2, delimiter: ".", separator: ","),
                item.voucher_payment_receiving.status

               ]
              sheet.add_row content_row
            end
          end
        else
          # records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")       
          records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id) 
          wb.add_worksheet(name: filename) do |sheet|
            header_row = ["No.", "No. Voucher", "Nama Pengirim", "Tanggal Pembayaran", "Total Amount", "Status" 
            ]
            sheet.add_row header_row
            c = 0
            records.each do |record|
              content_row = [c+=1, 
                "#{record.number}", 
                record.name_account, 
                record.date, 
                number_with_precision(record.total_amount, precision: 2, delimiter: ".", separator: ","),
                record.status

               ]
              sheet.add_row content_row
            end
          end
        end

      when "voucher_payments"  
        @list_internal_bank_accounts = ListInternalBankAccount.where(:status=> 'approved3')
        filename = "Voucher Payment"
        records = controller_name.singularize.camelize.constantize.where("#{controller_name}.company_profile_id = ?", current_user.company_profile_id)
        if params[:periode].present?
          records = records.where("date like '#{params[:periode].to_date.strftime("%Y-%m").to_s}%'")
        end
        if params["bank_type"].present?
          records = records.where(:list_internal_bank_account_id=>@list_internal_bank_accounts.where(:code_voucher=>params["bank_type"]).map {|e| [e.id]})
        end 
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["No.","No. Voucher", "Nama Penerima", "Tanggal", "Tanggal Pembayaran", "Sub Total", "PPN Total", "PPH Total", "Potongan Lainnya", "Total Amount", "Jenis Voucher", "Status"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               "#{r.number}",
               "#{r.list_external_bank_account.name_account if r.list_external_bank_account.present?}",
               r.date,
               r.payment_date,
               number_with_precision(r.sub_total, precision: 2, delimiter: ".", separator: ","),
               number_with_precision(r.ppn_total, precision: 2, delimiter: ".", separator: ","),
               number_with_precision(r.pph_total, precision: 2, delimiter: ".", separator: ","),
               number_with_precision(r.other_cut_fee, precision: 2, delimiter: ".", separator: ","),
               number_with_precision(r.grand_total, precision: 2, delimiter: ".", separator: ","),
               r.kind,
               r.status,
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when "proforma_invoice_customers"
        filename = "Proforma Invoice customer"
        items = ProformaInvoiceCustomerItem.where(:status=> 'active')     
        .includes(:proforma_invoice_customer).where(:proforma_invoice_customers => {:company_profile_id => current_user.company_profile_id })      
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          header_row = ["No.", "Status", "Customer", "Proforma Invoice Number", "TOP Day", "TOP", "Down Payment", "Proforma Invoice Date", "Due Date", "Remarks","PO Number", "Product Code", "Product Name", "Type", "Unit", "Qty", "Discount", "Unit Price", "Amount", "Amount Discount", "Total","Down Payment", "Discount","PPN", "grand total"]
          sheet.add_row header_row
          c = 0
          items.each do |item|
            content_row = [c+=1, 
              "#{item.proforma_invoice_customer.status if item.proforma_invoice_customer.present?}", 
              # "#{item.proforma_invoice_customer.sales_order.customer.name if item.proforma_invoice_customer.sales_order.present?}", 
              "#{item.proforma_invoice_customer.customer.name if item.proforma_invoice_customer.customer.present?}", 
              # "#{item.proforma_invoice_customer.sales_order.number if item.proforma_invoice_customer.sales_order.present?}", 
              "#{item.proforma_invoice_customer.number if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.top_day if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.term_of_payment.name if item.proforma_invoice_customer.term_of_payment.present?}", 
              "#{item.proforma_invoice_customer.down_payment if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.date if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.due_date if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.remarks if item.proforma_invoice_customer.present?}", 
              "#{item.sales_order.po_number if item.sales_order.present?}", 
              "#{item.sales_order_item.product.part_id if item.sales_order_item.present?}", 
              "#{item.sales_order_item.product.name if item.sales_order_item.present?}", 
              "#{item.sales_order_item.product.type_name if item.sales_order_item.present?}", 
              "#{item.sales_order_item.product.unit_name if item.sales_order_item.present?}", 
              "#{item.sales_order_item.quantity if item.sales_order_item.present?}", 
              "#{item.sales_order_item.discount if item.sales_order_item.present?}", 
              "#{item.sales_order_item.unit_price if item.sales_order_item.present?}", 
              item.amount,
              item.amountdisc,
              "#{item.proforma_invoice_customer.total if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.down_payment_total if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.discount_total if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.ppn_total if item.proforma_invoice_customer.present?}", 
              "#{item.proforma_invoice_customer.grand_total if item.proforma_invoice_customer.present?}",
             ]
            sheet.add_row content_row
          end
        end
      when "employee_leaves"
        #zulvan 10-11-21
        filename = "Daftar Sisa Cuti Karyawan #{kind}"
        records = EmployeeLeave.where(:company_profile_id=>current_user.company_profile_id, :period=>kind)
        .includes(:employee)
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","NIK", "NAMA KARYAWAN", "CUTI TERPAKAI", "SISA CUTI", "PERIODE"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               (r.employee.nik.to_s if r.employee.nik.present?),
               (r.employee.name.to_s if r.employee.nik.present?),
               r.day,  
               r.outstanding,  
               r.period
              ] , :types => [:string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'employee_schedules'
        #zulvan 05-11-21
        filename = "Schedule Periode #{kind}"              
         
        # file_name = kind
        wb.add_worksheet(name: 'List Schedule') do |sheet|
          style1 = sheet.styles.add_style(b:true, :alignment => {:horizontal => :center, :vertical => :center, :wrap_text => true}, :border => { :style => :thin, :color => "000000"})
          style2 = sheet.styles.add_style(:alignment => {:horizontal => :center, :vertical => :center}, :border => { :style => :thin, :color => "000000"})
          sheet.add_row ['List Schedule Karyawan']
          sheet.add_row ["No","CODE","SENIN","", "SELASA","", "RABU","", "KAMIS","", "JUMAT","", "SABTU","", "MINGGU",""], :style=>style1
          sheet.add_row ["","","JAM MASUK","JAM KELUAR","JAM MASUK","JAM KELUAR","JAM MASUK","JAM KELUAR","JAM MASUK","JAM KELUAR","JAM MASUK","JAM KELUAR","JAM MASUK","JAM KELUAR","JAM MASUK","JAM KELUAR"], :style=>style1
          sheet.merge_cells ("A2:A3")
          sheet.merge_cells ("B2:B3")
          sheet.merge_cells ("C2:D2")
          sheet.merge_cells ("E2:F2")
          sheet.merge_cells ("G2:H2")
          sheet.merge_cells ("I2:J2")
          sheet.merge_cells ("K2:L2")
          sheet.merge_cells ("M2:N2")
          sheet.merge_cells ("O2:P2")
          c = 1
          schedules = Schedule.where(:status=>'active')
          schedules.each do |r|
            col_widths = [8,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]
            sheet.add_row [
               c,
               (r.code if r.code.present?),
               (r.monday_in.strftime("%H:%M") if r.monday_in.present?),
               (r.monday_out.strftime("%H:%M") if r.monday_out.present?),
               (r.tuesday_in.strftime("%H:%M") if r.tuesday_in.present?),
               (r.tuesday_out.strftime("%H:%M") if r.tuesday_out.present?),
               (r.wednesday_in.strftime("%H:%M") if r.wednesday_in.present?),
               (r.wednesday_out.strftime("%H:%M") if r.wednesday_out.present?),
               (r.thursday_in.strftime("%H:%M") if r.thursday_in.present?),
               (r.thursday_out.strftime("%H:%M") if r.thursday_out.present?),
               (r.friday_in.strftime("%H:%M") if r.friday_in.present?),
               (r.friday_out.strftime("%H:%M") if r.friday_out.present?),
               (r.saturday_in.strftime("%H:%M") if r.saturday_in.present?),
               (r.saturday_out.strftime("%H:%M") if r.saturday_out.present?),
               (r.sunday_in.strftime("%H:%M") if r.sunday_in.present?),
               (r.sunday_out.strftime("%H:%M") if r.sunday_out.present?)
              ], :style=>style2, :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            sheet.column_widths *col_widths
            c+=1
          end
        end

        wb.add_worksheet(name: 'schedule kerja') do |sheet|
          basic_style = sheet.styles.add_style(:sz=>10, b:true, :alignment => {:horizontal => :center, :vertical => :center, :wrap_text => true})
          style1 = sheet.styles.add_style(:sz=>10, b:true, :alignment => {:horizontal => :center, :vertical => :center, :wrap_text => true}, :border => { :style => :thin, :color => "000000"})
          style2 = sheet.styles.add_style(:width  =>nil, :alignment => {:horizontal => :left, :vertical => :center}, :border => { :style => :thin, :color => "000000"})
          sheet_cell = ["A","B","C","D","E"]
          sheet_cell.each do |c|
            sheet.merge_cells ("#{c}5:#{c}6")
          end

          c = 1
          employees = Employee.where(:employee_status=>'Aktif', :employee_legal_id=>1).order('name asc')
          period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
          period_begin = period.to_date+20.day if period.present?
          period_end = period.to_date+1.month+19.day if period.present?
          # update_employee_presence(period_begin,period_end)
          # sheet.cells()

          title = ['No','NIK','Nama Karyawan','Department','Jabatan']
          day = ["","","","",""]
          period_begin.upto(period_end) do |r|
            title << r.strftime('%d-%m')
            if r.monday?
              d = 'Sn'
            elsif r.tuesday?
              d = 'Sl'
            elsif r.wednesday?
              d = 'Rb'
            elsif r.thursday?
              d = 'Km'
            elsif r.friday?
              d = 'Jm'
            elsif r.saturday?
              d = 'Sb'
            elsif r.sunday?
              d = 'Mg'                                                      
            end
            day << d
          end

          sheet.add_row []
          sheet.add_row []
          sheet.add_row ["","PERIODE","#{params[:period]}"], :style=>basic_style
          sheet.add_row []
          sheet << title
          sheet << day
          employees.each do |r|
            # recap_schedule = EmployeeScheduleRecap.find_by(:employee_id=>r.id, :periode=>params[:period], :status=>'active')
            col_widths = [5,18,25,22,nil]
            schedule_data = [] 
            schedule_data << (c)
            schedule_data << (r.nik if r.present?)
            schedule_data << (r.name if r.present?)
            schedule_data << (r.department.name if r.present? and r.department.present?)
            schedule_data << (r.position.name if r.present? and r.position.present?)
            period_begin.upto(period_end) do |dt|
              emp_sched = EmployeeSchedule.find_by(:employee_id=> r.id, :date=>dt.strftime('%Y-%m-%d'), :status=>'active')
              schedule_data << (emp_sched.present? ? emp_sched.schedule.code : nil)
            end

            sheet.add_row(schedule_data, :style => style2)

            # puts "#{r.name if recap_schedule.present?} ----name----"
            # sheet.add_row [
            #    c,
            #    (r.nik if r.present?),
            #    (r.name if r.present?),
            #    (r.department.name if r.present? and r.position.present?)
            #   ], :style=>style2, :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            sheet.column_widths *col_widths
            c+=1
            sheet.column_widths *col_widths
          end
          sheet.rows[4].style = style1
          sheet.rows[5].style = style1
        end
      when "employee_overtimes"
        #zulvan 05-11-21
        
        params[:period] = (params[:period].blank? ? (DateTime.now()-1.month).strftime("%Y%m")  : params[:period] )
        period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
        period_begin = period.to_date+20.day if period.present?
        period_end = period.to_date+1.month+19.day if period.present?

        if params[:period].to_s[4,2]=='01'
          periode = '21 Jan - 20 Feb'
        elsif params[:period].to_s[4,2]=='02'
          periode = '21 Feb - 20 Mar'
        elsif params[:period].to_s[4,2]=='03'
          periode = '21 Mar - 20 Apr'
        elsif params[:period].to_s[4,2]=='04'
          periode = '21 Apr - 20 Mei'
        elsif params[:period].to_s[4,2]=='05'
          periode = '21 Mei - 20 Jun'
        elsif params[:period].to_s[4,2]=='06'
          periode = '21 Jun - 20 Jul'
        elsif params[:period].to_s[4,2]=='07'
          periode = '21 Jul - 20 Aug'
        elsif params[:period].to_s[4,2]=='08'
          periode = '21 Aug - 20 Sep'
        elsif params[:period].to_s[4,2]=='09'
          periode = '21 Sep - 20 Okt'
        elsif params[:period].to_s[4,2]=='10'
          periode = '21 Okt - 20 Nov'
        elsif params[:period].to_s[4,2]=='11'
          periode = '21 Nov - 20 Des'
        elsif params[:period].to_s[4,2]=='12'
          periode = '21 Des - 20 Jan'
        end
          

        filename = "Overtime #{periode}"
        status = ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3']
        records = EmployeeOvertime.where(:company_profile_id=> current_user.company_profile_id, :status=>status).where("date between ? and ?", period_begin, period_end )
        .includes(employee: [:department])
       
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","NIK", "NAMA KARYAWAN", "DEPARTMENT", "JABATAN", "TANGGAL", "MULAI LEMBUR", "SELESAI LEMBUR", "TOTAL JAM LEMBUR", "KETERANGAN"]
          records.order("created_at asc").each do |r|
            sheet.add_row [
               c,
               (r.employee.nik.to_s if r.employee.nik.present?),
               (r.employee.name.to_s if r.employee.nik.present?),
               (r.employee.department.name if r.employee.department.present?),
               (r.employee.position.name if r.employee.position.present?),
               r.date.to_s,  
               r.overtime_begin.strftime("%H:%M").to_s,  
               r.overtime_end.strftime("%H:%M").to_s, 
               TimeDifference.between(r.datetime_overtime_begin, r.datetime_overtime_end).in_hours, 
               r.description
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'employee_presences'
      when 'working_hour_summaries'
        period = params[:yyyymm].present? ? (params[:yyyymm]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
        period_begin = period.to_date+20.day if period.present?
        period_end = period.to_date+1.month+19.day if period.present?
        ws_name = "Summary Jam Kerja"
        filename = ws_name+", #{period}"

        # 20200424: aden dan zulvan periode libur 25 desember tahun kemarin dan tahun sekarang
        # holiday = HrdHolidayDate.where(:status=> 'active').where("date between ? and ?", period.to_date.beginning_of_year()-1.month+20.day, period.to_date.end_of_year()-1.month+20.day).order("date asc")
        
        # holiday = HrdHolidayDate.where(:status=> 'active').where("date between ? and ?", (period.to_date-1.years).strftime("%Y-12-25"), period.to_date.strftime("%Y-12-25")).order("date asc")
        holiday = HolidayDate.where(:status=> 'active').where("date between ? and ?", (period_begin.to_date).strftime("%Y-12-25"), period_end.to_date.strftime("%Y-12-25")).order("date asc")
        
        holiday_periode = 0
        holiday_periode2 = 0
        holiday.where("date between ? and ?", period_begin, period_end).each do |dt|
          # hari libur nasional pada hari kerja karyawan 
          puts "#{dt.date} #{dt.date.wday}"
          case dt.date.wday
          when 1, 2, 3, 4, 5, 6
            holiday_periode+= 1
          end
          holiday_periode2+= 1
        end

        # holiday_periode = holiday.where("date between ? and ?",(period_begin),(period_end)).size
        puts "holiday_periode: #{holiday_periode}"
        count_month = (period_end-period_begin).to_i+1
        my_days = [1,2,3,4,5,6] # day of the week in 0-6. Sunday is day-of-week 0; Saturday is day-of-week 6.
        count_month_work_day = ((period_begin)..(period_end)).to_a.select {|k| my_days.include?(k.wday)}.size-holiday_periode

        my_days_non_shift = [1,2,3,4,5] # day of the week in 0-6. Sunday is day-of-week 0; Saturday is day-of-week 6.
        count_month_work_day_non_shift = ((period_begin)..(period_end)).to_a.select {|k| my_days_non_shift.include?(k.wday)}.size
        wb.add_worksheet(name: "General Info" ) do |sheet|
          c = 1
          sheet.add_row [""]
          sheet.add_row ["","","","No.","Tanggal Libur","Libur Nasional","","No.","Tanggal Libur","Libur Periode Ini"]
          holiday.each do |r|
            sheet.add_row ["","","",c,r.date,r.holiday,"","","",""], :types => [:string, :string, :string, :string, :string, :string,:string, :string, :string, :string, :string, :string,:string, :string, :string, :string, :string, :string]
            c+=1
          end

          (1..30).each do 
            sheet.add_row ["","","","","","","","",""]
          end

          sheet.rows[2].cells[0].value = "Tanggal Mulai"
          sheet.rows[2].cells[1].value = "#{period_begin}"

          sheet.rows[3].cells[0].value = "Tanggal Akhir"
          sheet.rows[3].cells[1].value = "#{period_end}"

          sheet.rows[4].cells[0].value = "Jumlah hari dalam 1 bulan"
          sheet.rows[4].cells[1].value = "#{count_month}"

          # total hari kerja - total hari libur nasional (senin sd sabtu)
          sheet.rows[5].cells[0].value = "Jumlah hari kerja dalam 1 bulan"
          sheet.rows[5].cells[1].value = "#{count_month_work_day}"

          sheet.rows[6].cells[0].value = "Hari Libur National dalam 1 bulan"
          sheet.rows[6].cells[1].value = "#{holiday_periode2}"

          sheet.rows[7].cells[0].value = "hari kerja dalam 1 bulan (5 hari kerja)"
          sheet.rows[7].cells[1].value = "#{count_month_work_day_non_shift-holiday_periode}"
          c = 1
          row = 2
          # libur periode ini
          holiday.where("date between ? and ?",(period_begin),(period_end)).each do |r|
            sheet.rows[row].cells[7].value = c.to_i
            sheet.rows[row].cells[8].value = r.date
            sheet.rows[row].cells[9].value = r.holiday

            c+=1
            row += 1
          end
        end

        # records = HrdEmployee.where(:hrd_employee_payroll_id=> @selected_plant, :status=> 'active').order("name asc")
        records = WorkingHourSummary.where(:company_profile_id=> current_user.company_profile_id.to_i, :status=> 'active', :period_begin=> period_begin, :period_end=> period_end )
        records = records.where(:department_id=> kind) if kind.present?
        records  = records.includes({employee: :position}, :department)
        wb.add_worksheet(name: ws_name ) do |sheet|
          c = 1
          sheet.add_row [ws_name]
          sheet.add_row ["No.","PIN","NIK","Nama Karyawan","Departemen","Posisi","Periode","Working Day","Working Off Day","OT Hour",
            "Masuk Hari Libur","Working Hour",
            "OT jam pertama","OT jam kedua","OT jam ke 4 s/d 7",
            "OT jam ke 8 s/d 11","OT diatas jam ke 11","OT jam ke 5 s/d 8","OT diatas jam ke 8",
            "Total Alpa", "Total Izin", "Total Sakit", "Total Cuti", "Total Libur", "Total Terlambat"
            ]
          records.each do |r|
            if r.employee.present?
              att_user = AttendanceUser.find_by(:company_profile_id=> current_user.company_profile_id.to_i, :employee_id=> r.employee_id, :status=> 'active')
              if att_user.present?
                sheet.add_row [
                  c, att_user.id_number, r.employee.nik, r.employee.name, r.department.name, "#{r.employee.position.name if r.employee.position.present?}",
                  presence_period(r.period), r.working_weekday, r.working_off_day, r.overtime_hour,
                  r.working_weekend, r.working_hour,
                  r.overtime_first_hour, r.overtime_second_hour,
                  r.overtime_4_7, r.overtime_8_11, r.overtime_11plus, r.overtime_5_8, r.overtime_8plus,
                  r.absence_a, r.absence_i, r.absence_s, r.absence_c, r.absence_l, r.late_come
                  ], :types => [:string, :string, :string, :string, :string, :string
                  ]
                c+=1
              end
            end
          end
        end      
      when 'payment_request_suppliers'
        filename = "Payment Request Supplier "
        records = PaymentRequestSupplier.where('date between ? and ?', params[:date_begin], params[:date_end])
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","STATUS", "NUMBER", "DATE", "SUPPLIER", "GRAND TOTAL"]
          records.order("created_at desc").each do |r|
            sheet.add_row [
               c,
               r.status,
               r.number,
               r.date,
               (r.supplier.name.to_s if r.supplier.present?),
               r.grandtotal
              ] , :types => [:string, :string, :string, :string, :string, :string]
            c+=1
          end
        end

        wb.add_worksheet(name: 'Detail') do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","STATUS", "NUMBER", "DATE", "SUPPLIER", "INVOICE", "SUBTOTAL", "PPN", "PPH", "DP", "GRAND TOTAL"]
          items = PaymentRequestSupplierItem.where(:status=>'active', :payment_request_supplier_id=>(records.map { |e| e.id }))
          
          items.order("payment_request_supplier_id desc").each do |r|
            sheet.add_row [
               c,
               r.payment_request_supplier.status,
               r.payment_request_supplier.number,
               r.payment_request_supplier.date,
               (r.payment_request_supplier.supplier.name.to_s if r.payment_request_supplier.supplier.present?),
               (r.invoice_supplier.number if r.invoice_supplier.present?),
               r.payment_request_supplier.subtotal,
               r.payment_request_supplier.ppntotal,
               r.payment_request_supplier.pphtotal,
               r.payment_request_supplier.dptotal,
               r.payment_request_supplier.grandtotal
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'routine_cost_payments'
        filename = "Bpk Biaya Rutin"
        records = RoutineCostPayment.where('date between ? and ?', params[:date_begin], params[:date_end])
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row ["NO.","Company Profile", "Department", "Number", "Date", "Grand Total", "Voucher Number", "Payment Rutin", "Remarks", "Status", "Created At", "Grand Total","Created By", "Updated At", "Updated By", "Approved 1 At", "Approved 1 By", "Approved 2 At", "Approved 2 By", "Approved 3 At", "Approved 3 By", "Canceled 1 At", "Canceled 1 By", "Canceled 2 At", "Canceled 2 At", "Canceled 3 At", "Canceled 3 By"]
          records.order("created_at desc").each do |r|
            item = RoutineCostPaymentItem.find_by(:routine_cost_payment_id=>r.id)
            sheet.add_row [
              c,
              (r.company_profile.name if r.company_profile.present?),
              (r.department.name if r.department.present?),
              r.number,
              r.date,
              r.grand_total,
              r.voucher_number,
              (item.routine_cost.cost_name if item.routine_cost.present?),
              r.remarks,
              r.status,
              (r.created_at.strftime('%d-%m-%Y').to_s if r.created_at.present?),
              (r.created.first_name if r.created_by.present?),
              (r.updated_at.strftime('%d-%m-%Y').to_s if r.updated_at.present?),
              (r.updated.first_name if r.updated_by.present?),
              (r.approved1_at.strftime('%d-%m-%Y').to_s if r.approved1_at.present?),
              (r.approved1.first_name if r.approved1.present?),
              (r.approved2_at.strftime('%d-%m-%Y').to_s if r.approved2_at.present?),
              (r.approved2.first_name if r.approved2_by.present?),
              (r.approved3_at.strftime('%d-%m-%Y').to_s if r.approved3_at.present?),
              (r.approved3.first_name if r.approved3_by.present?),
              (r.canceled1_at.strftime('%d-%m-%Y').to_s if r.canceled1_at.present?),
              (r.canceled1.first_name if r.canceled1_by.present?),
              (r.canceled2_at.strftime('%d-%m-%Y').to_s if r.canceled2_at.present?),
              (r.canceled2.first_name if r.canceled2_by.present?),
              (r.canceled3_at.strftime('%d-%m-%Y').to_s if r.canceled3_at.present?),
              (r.canceled3.first_name if r.canceled3_by.present?)
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'cash_submissions'
        filename = "Pengajuan Kasbon"
        records = CashSubmission.where('date between ? and ?', params[:date_begin], params[:date_end])
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row ["NO.","Status", "Number", "Voucher Payment (Number)", "Date", "Department", "Description", "Grand Total", "Receiver Name", "Bank Name", "Bank Number", "Email"]
          records.order("created_at desc").each do |r|
            item = RoutineCostPaymentItem.find_by(:routine_cost_payment_id=>r.id)
            sheet.add_row [
              c,
              r.status,
              r.number,
              r.voucher_number,
              r.date,
              (r.department.name if r.department.present?),
              r.description,
              r.amount,
              r.receiver_name,
              r.bank_name,
              r.bank_number,
              r.email_notification
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'cash_settlements'
        filename = "Penyelesaian Kasbon "
                
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","STATUS", "NUMBER", "KASBON NUMBER", "VOUCHER NUMBER", "Date", "DEPARTMENT", "BON TOTAL", "SETTLEMENT TOTAL", "ADVANTAGE", "CREATED BY", "CREATED AT"]
          records = CashSettlement.where('date between ? and ?', params[:date_begin], params[:date_end])
          records.order("created_at desc").each do |r|
            sheet.add_row [
               c,
               r.status,
               r.number,
               (r.cash_submission.number if r.cash_submission.present?),
               r.voucher_number,
               r.date,
               (r.department.name if r.department.present?),
               r.expenditure_total,
               r.settlement_total,
               r.advantage,
               (r.created.first_name if r.created_by.present?),
               (r.created_at.strftime('%d-%m-%Y').to_s if r.created_at.present?)
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end

        wb.add_worksheet(name: 'Detail') do |sheet|
          c = 1
          sheet.add_row [kind]
          sheet.add_row ["NO.","STATUS", "NUMBER", "KASBON NUMBER", "VOUCHER NUMBER", "DATE", "DEPARTMENT", "DESCRIPTION HEADER", "DESCRIPTION ITEM", "PAYMENT TYPE", "COA NAME", "AMOUNT"]
          items = CashSettlementItem.where(:status=>'active', :cash_settlement_id=>(records.map { |e| e.id }))
          
          items.order("cash_settlement_id desc").each do |r|
            sheet.add_row [
               c,
               r.cash_settlement.status,
               r.cash_settlement.number,
               (r.cash_settlement.cash_submission.number if r.cash_settlement.cash_submission.present?),
               (r.cash_settlement.voucher_number if r.cash_settlement.present?),
               (r.cash_settlement.date if r.cash_settlement.present?),
               (r.cash_settlement.department.name if r.cash_settlement.department.present?),
               (r.cash_settlement.description if r.cash_settlement.present?),
               r.description,
               r.payment_type,
               r.coa_name,
               r.amount
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'payment_customers'
        filename = "Payment Received"
        records = PaymentCustomer.where('date between ? and ?', session[:date_begin], session[:date_end])
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row ["NO.","Status", "INVOICE KIND", "NUMBER", "Date", "SUPPLIER NAME", "INVOICE NUMBER", "JUMLAH", "PAJAK", "DISCOUNT", "DOWN PAYMENT", "TOTAL PAJAK INVOICE", "TOTAL AMOUNT INVOICE", "BIAYA ADM. BANK", "POTONGAN LAIN", "JUMLAH TRANSFER"]
          records.order("created_at desc").each do |r|
            sheet.add_row [
              c,
              r.status,
              r.invoice_kind,
              r.number,
              r.date,
              (r.customer.name if r.customer.present?),
              r.description,
              r.amount,
              r.receiver_name,
              r.bank_name,
              r.bank_number,
              r.email_notification
              ] , :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            c+=1
          end
        end
      when 'payment_suppliers'
        filename = "Payment Supplier"
        records = PaymentSupplier.where('date between ? and ?', session[:date_begin], session[:date_end]).includes(:supplier_payment_method, :bank_transfer, :currency, :supplier)
         
        kind      = filename
        file_name = kind+", "+DateTime.now.strftime(" %Y-%m-%d %H:%M:%S")
        wb.add_worksheet(name: kind) do |sheet|
          c = 1
          sheet.add_row ["NO.","Status", "Payment Number", "Payment Date", "SUPPLIER NAME", "Pay.Method", "Bank Transfer", "Currency", "Subtotal", "PPN Total", "PPH Total", "DP", "Grand Total"]
          records.order("created_at desc").each do |record|
            sheet.add_row [ 
              c, record.status, record.number, record.date, "#{record.supplier.present? ? record.supplier.name : nil}",
              record.supplier_payment_method.present? ? record.supplier_payment_method.name : nil, record.bank_transfer.present? ? record.bank_transfer.name : nil,
              record.currency.present? ? record.currency.name : nil, 
              record.subtotal, record.ppntotal, record.pphtotal, record.dptotal, record.grandtotal
            ]
            c+=1
          end
        end
      end

      filename_original = "#{user_id}_#{SecureRandom.hex(10)}_#{filename}.xlsx"
      path    = "#{Rails.root}/tmp/export/#{filename_original}"
      puts filename
      filename_xlsx = filename.parameterize.underscore+"_"+DateTime.now.strftime("%Y%m%d_%H%M%S")+".xlsx"
      puts filename_xlsx
      send_data p.to_stream.read, :type => "application/vnd.ms-excel", :filename => filename_xlsx, :stream => true
    else  
      feature_list = PermissionBase.find_by(:status=> 'active', :spreadsheet_status=> 'Y', :link=> "/#{permission_base_link}", :link_param=> link_param)
      if feature_list.present?
        spreadsheet_report = SpreadsheetReport.find_by(:permission_base_id=> feature_list.id)
        if spreadsheet_report.present?
          spreadsheet_contents = SpreadsheetContent.where(:spreadsheet_report_id=> spreadsheet_report.id, :status=> 'active').order("sequence_number asc")
          
          filename = feature_list.name

          case controller_name
          when "direct_labor_prices"
            records = controller_name.singularize.camelize.constantize.all
          when "supplier_tax_invoices"
            records = controller_name.singularize.camelize.constantize.where(:periode=> params[:periode])
          when "customers", "suppliers","materials", "products","direct_labor_workers","tax_rates"
            records = controller_name.singularize.camelize.constantize.where(:status=> 'active')
          when "purchase_requests"          
            records = controller_name.singularize.camelize.constantize.where(:request_kind=> kind).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
          when "shop_floor_orders"
            records = controller_name.singularize.camelize.constantize.where(:kind=> kind).where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
          else
            records = controller_name.singularize.camelize.constantize.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
          end

          # report material receiving form
          case params[:tbl_kind]
          when "items"
            items = "#{controller_name.singularize}_item".camelize.constantize.where("#{controller_name.singularize}_id".to_sym=> records, :status=> 'active')
            records = items 
          end

          case params[:view_kind]
          when "batch_number"
            # direct_labor
            direct_labors = records
            select_product_batch_number_id = DirectLaborItem.where(:status=> 'active').includes(:direct_labor).where(:direct_labors => {:company_profile_id => current_user.company_profile_id }).order("direct_labors.number desc").group("direct_labor_items.product_batch_number_id").select("direct_labor_items.product_batch_number_id")
            product_batch_number = ProductBatchNumber.where(:status=> 'active', :company_profile_id=> current_user.company_profile_id, :id=> select_product_batch_number_id)
      
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "Batch Number"]
              (session[:date_begin].to_date..session[:date_end].to_date).each do |date|
                header_row += [date.to_date.strftime("%d %B")] 
              end
              sheet.add_row header_row
              c = 0

              product_batch_number.each do |record|
                content_row = [c+=1, record.number]

                (session[:date_begin].to_date..session[:date_end].to_date).each do |date|
                  
                  sum_unit_price = 0
                  direct_labors.where(:date=> date).each do |header|
                    header.direct_labor_items.where(:product_batch_number_id=> record.id, :status=> 'active').each do |item|
                      sum_unit_price += item.unit_price.to_f
                    end
                  end
                  content_row += [number_with_precision(sum_unit_price, precision: 0, delimiter: ".", separator: ",")]

                end


                sheet.add_row content_row
              end
            end            
          when "operator"
            # direct_labor
            direct_labors = records
            direct_labor_workers = DirectLaborWorker.where(:status=> 'active')
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No.", "PIC", "Total"]
              (session[:date_begin].to_date..session[:date_end].to_date).each do |date|
                header_row += [date.to_date.strftime("%d %B")] 
              end
              sheet.add_row header_row
              c = summary_total = summary_date1 = summary_date2 = summary_date3 = summary_date4 = summary_date5 = summary_date6 = summary_date7 = summary_date8 = summary_date9 = summary_date10 = summary_date11 = summary_date12 = summary_date13 = summary_date14 = summary_date15 = 0

              direct_labor_workers.each do |pic|
                content_row = [c+=1, pic.name]
                content_row_price = []
                total = c_date = 0
                (session[:date_begin].to_date..session[:date_end].to_date).each do |date|
                  c_date += 1
                  sum_unit_price = 0
                  direct_labors.where(:direct_labor_worker_id=> pic.id, :date=> date).each do |header|
                    header.direct_labor_items.where(:status=> 'active').each do |item|
                      sum_unit_price += item.unit_price.to_f
                      total += item.unit_price.to_f
                    end
                  end

                  case c_date
                  when 1
                    summary_date1 += sum_unit_price
                  when 2
                    summary_date2 += sum_unit_price
                  when 3
                    summary_date3 += sum_unit_price
                  when 4
                    summary_date4 += sum_unit_price
                  when 5
                    summary_date5 += sum_unit_price
                  when 6
                    summary_date6 += sum_unit_price
                  when 7
                    summary_date7 += sum_unit_price
                  when 8
                    summary_date8 += sum_unit_price
                  when 9
                    summary_date9 += sum_unit_price
                  when 10
                    summary_date10 += sum_unit_price
                  when 11
                    summary_date11 += sum_unit_price
                  when 12
                    summary_date12 += sum_unit_price
                  when 13
                    summary_date13 += sum_unit_price
                  when 14
                    summary_date14 += sum_unit_price
                  when 15
                    summary_date15 += sum_unit_price
                  end
                  
                  content_row_price += [number_with_precision(sum_unit_price, precision: 0, delimiter: ".", separator: ",")]

                end
                summary_total += total

                content_row += [number_with_precision(total, precision: 0, delimiter: ".", separator: ",")]
                content_row += content_row_price

                sheet.add_row content_row
              end

              sheet.add_row ["", "Total", 
                number_with_precision(summary_total, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date1, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date2, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date3, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date4, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date5, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date6, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date7, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date8, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date9, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date10, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date11, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date12, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date13, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date14, precision: 0, delimiter: ".", separator: ","),
                number_with_precision(summary_date15, precision: 0, delimiter: ".", separator: ",")

              ]
            end
          when "item"
            case controller_name
            when "direct_labor_prices"
              items = "#{controller_name.singularize}_detail".camelize.constantize.where("#{controller_name.singularize}_id".to_sym=> records, :status=> 'active')
            else
              items = "#{controller_name.singularize}_item".camelize.constantize.where("#{controller_name.singularize}_id".to_sym=> records, :status=> 'active')
            end 

            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No."]
              items.columns.each do |column|
                header_row += [column.name.humanize] if column.name != "id"
              end
              sheet.add_row header_row
              c = 0
              items.each do |item|
                content_row = [c+=1]
                items.columns.each do |column|
                  if column.name != "id"
                    if "#{column.name}".include? "_id"
                      case column.name
                      when "part_id"
                        content_value = item["#{column.name}"]
                      else
                        f_name = "#{column.name}".remove("_id")
                        if item.try("#{f_name}").class.method_defined? "name"
                          content_value = item.try("#{f_name}")&.name
                        elsif item.try("#{f_name}").class.method_defined? "number"
                          content_value = item.try("#{f_name}")&.number
                        elsif item.try("#{f_name}").class.method_defined? "product_id"
                          content_value = item.try("#{f_name}")&.product.name
                        end
                        content_row += [content_value.present? ? content_value : ""]
                      end
                    elsif "#{column.name}".include? "_by"
                      content_row += [account_name(item["#{column.name}"])]
                    else
                      content_row += [item["#{column.name}"]]
                    end
                  end
                end
                sheet.add_row content_row
              end
            end
          else
            wb.add_worksheet(name: filename) do |sheet|
              header_row = ["No."]
              header_row += spreadsheet_contents.map { |e| e.name.humanize  } 
              sheet.add_row header_row
              c = 0
              records.each do |record|
                content_row = [c+=1]
                spreadsheet_contents.each do |e|
                  if "#{e.name}".include? "_id"
                    case e.name
                    when "part_id"
                      content_value = record["#{e.name}"]
                    else
                      f_name = "#{e.name}".remove("_id")
                      if record.try("#{f_name}").class.method_defined? "name"
                        content_value = record.try("#{f_name}")&.name
                      elsif record.try("#{f_name}").class.method_defined? "number"
                        content_value = record.try("#{f_name}")&.number
                      end
                    end
                    content_row += [content_value.present? ? content_value : ""]                
                  elsif "#{e.name}".include? "_by"
                    content_row += [account_name(record["#{e.name}"])]
                  else
                    content_row += [record["#{e.name}"]]
                  end
                end
                sheet.add_row content_row
              end
            end
          end
          
          filename_original = "#{user_id}_#{SecureRandom.hex(10)}_#{filename}.xlsx"
          path    = "#{Rails.root}/tmp/export/#{filename_original}"

          filename_xlsx = filename.upcase+"_"+DateTime.now.strftime(" %Y%m%d_%H%M%S")+".xlsx"
          send_data p.to_stream.read, :type => "application/vnd.ms-excel", :filename => filename_xlsx, :stream => true
        else   
          respond_to do |format|
            format.html { redirect_to my_path, alert: "Export #{controller_name.humanize} not Available." }
            format.json { head :no_content }
          end        
        end      
      else   
        respond_to do |format|
          format.html { redirect_to my_path, alert: "Export #{controller_name.humanize} not Available." }
          format.json { head :no_content }
        end        
      end
    end
  end
end