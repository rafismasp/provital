module ApplicationHelper
  def document_number(ctrl_name, period, kind, kind2, kind3)
    case ctrl_name
    when "inventory_adjustments"
      prefix_code = "ADJ"
      i = 10
      ctrl = "inventory_adjustment"
    when "internal_transfers"

      # WHFG-PRD/20/06/0028
      # WHFG-2ND/20/06/0028
      # WHFG-QCT/20/06/0028

      # WHRM-PRD/20/06/0028
      # WHRM-2ND/20/06/0028
      # WHRM-QCT/20/06/0028

      # PRD-WHFG/20/06/0028
      # QCT-WHFG/20/06/0028

      # WH-INT/20/06/0028


      prefix_code = "#{internal_transfer_kind_defined(kind2)}-#{internal_transfer_kind_defined(kind3)}"
      ctrl = "internal_transfer"
      i = 15
    when "delivery_order_suppliers"
      prefix_code = "DS"
      ctrl = "delivery_order_supplier"
      i = 6
    when "delivery_orders"
      prefix_code = "DO"
      ctrl = "delivery_order"
      i = 6
      # DO2006001
    when "direct_labors"
      prefix_code = "BR"
      ctrl = "direct_labor"
      i = 6
      # BR20060001
    when "production_orders"
      prefix_code = "SPP"
      ctrl = "production_order"
      i = 6
      # SPP20060001
    when "pdms"
      prefix_code = "PDM"
      ctrl = "pdm"
      i = 6
      # PDM20060001
    when "picking_slips"
      prefix_code = "PS"
      ctrl = "picking_slip"
      i = 6
      # PS20060001
    when "purchase_requests"
      # PRF/01A/20/VI/001
      section = EmployeeSection.find_by(:id=> kind)
      if section.present?
        section_code = "#{section.department.code}#{section.code}"
        prefix_code = "PRF/#{section_code}"
      else
        prefix_code = "PRF/03B"
      end
      ctrl = "purchase_request"
      i = 14
    when "purchase_order_suppliers"
      # PP/PO/20/VI/012
      prefix_code = "PP/PO"
      ctrl = "purchase_order_supplier"
      i = 12
    when "sales_orders"
      prefix_code = "PP/PIF"
      ctrl = "sales_order"
      i = 7
      # PP/PIF/01/VI/2020
    when "sterilization_product_receivings"
      prefix_code = "SPR"
      i = 10
      ctrl = "sterilization_product_receiving"
    when "product_receivings"
      prefix_code = "PR"
      i = 6
      ctrl = "product_receiving"
    when "general_receivings"
      prefix_code = "SR"
      i = 6
      ctrl = "general_receiving"
    when "equipment_receivings"
      prefix_code = "ER"
      i = 6
      ctrl = "equipment_receiving"
    when "consumable_receivings"
      prefix_code = "CR"
      i = 6
      ctrl = "consumable_receiving"
    when "shop_floor_orders"
      prefix_code = "SFO"
      i = 10
      ctrl = "shop_floor_order"
    when "shop_floor_order_sterilizations"
      prefix_code = "SFOS"
      i = 11
      ctrl = "shop_floor_order_sterilization"
      # SFOS/AA/BB/XXX
    when "material_additionals"
      prefix_code = "AM"
      i = 9

      ctrl = "material_additional"
      # AM/20/06/001
    when "material_returns"
      prefix_code = "RM"
      i = 9

      ctrl = "material_return"
      # RM/20/06/001
    when "material_outgoings"
      prefix_code = "MI"
      i = 9

      ctrl = "material_outgoing"
      # MI/20/06/001
    when "virtual_receivings"
      prefix_code = "VRN"
      i = 10

      ctrl = "virtual_receiving"
      # VRN/20/06/001
    when "material_receivings"
      prefix_code = "GRN"
      i = 10

      ctrl = "material_receiving"
      # GRN/20/06/001
    when "finish_good_receivings"
      prefix_code = "FGR"
      i = 10
      ctrl = "finish_good_receiving"
      # FGR/20/01/001
    when "semi_finish_good_receivings"
      prefix_code = "SFG"
      i = 10
      ctrl = "semi_finish_good_receiving"
      # SFG/20/01/001
    when "semi_finish_good_outgoings"
      prefix_code = "SFS"
      i = 10
      ctrl = "semi_finish_good_outgoing"
      # SFS/20/01/001
    when "invoice_customers"
      prefix_code = ""
      ctrl = "invoice_customer"   
      i = 3   
      # 16B123
    when "invoice_supplier_receivings"
      prefix_code = "1"
      ctrl = "invoice_supplier_receiving"   
      i = 4
      # 1/18/05/0003
    when "payment_request_suppliers"
      prefix_code = "VPR.SUP"
      ctrl = "payment_request_supplier"   
      i = 3
      # VPR.SUP/2016/H/001
    when "vehicle_inspections"
      #VI/YY/MM/xxxx
      prefix_code = "VI"
      ctrl = "vehicle_inspection"
      i = 9
    when "outgoing_inspections"
      #OI/YY/MM/xxxx
      prefix_code = "OI"
      ctrl = "outgoing_inspection"
      i = 9
    when "rejected_materials"
      #NG-RM/YY/MM/xxxx
      prefix_code = "NG-RM"
      ctrl = "rejected_material"
      i = 9
    when 'routine_costs'
      ctrl = 'routine_cost'
      prefix_code = "RE"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'routine_cost_payments'
      ctrl = 'routine_cost_payment'
      prefix_code = "BPKBR"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'cash_submissions'
      ctrl = 'cash_submission'
      prefix_code = "KASBON"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'cash_settlements'
      ctrl = 'cash_settlement'
      prefix_code = "KASBON-#{kind2}"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'proof_cash_expenditures'

      ctrl = 'proof_cash_expenditure'
      prefix_code = "BPK"

      dept = Department.find(kind)
      dept_prefix = dept.hrd_contract_abbreviation if dept.present?
    when 'voucher_payment_receivings'

      ctrl = 'voucher_payment_receiving'
      internal_bank = ListInternalBankAccount.find_by(:id=> kind)
      prefix_code = "#{internal_bank.code_voucher if internal_bank.present?}"
    when 'voucher_payments'
      
      ctrl = 'voucher_payment'
      internal_bank = ListInternalBankAccount.find_by(:id=> kind)
      prefix_code = "#{internal_bank.code_voucher if internal_bank.present?}"
    when 'proforma_invoice_customers'
      ctrl = 'proforma_invoice_customer'
      prefix_code = 'PI'
    when 'material_check_sheets'
      ctrl = ctrl_name.singularize
      prefix_code = 'MCS'
    end

    month_to_letter = {}
    ('A'..'Z').each_with_index{|w, i| month_to_letter[i+1] = w } 
    year_yyyy = period.strftime("%Y")
    year_yy = period.strftime("%y")
    month_mm = period.strftime("%m")
    records = ctrl.camelize.constantize.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", period.to_date.at_beginning_of_month(), period.to_date.at_end_of_month())
  
    case ctrl 
      # 20200701 : sfo dipisah table
      # when "shop_floor_order"
      #   records = records.where(:kind=> kind)
      # 20200623 : PO Supplier penomorannya tidak pisah berdasarkan request_kind
    when "purchase_request"
      records = records.where(:employee_section_id=> kind)
    when "internal_transfer"
      records = records.where(:transfer_kind=> kind, :transfer_from=> kind2, :transfer_to=> kind3)
    end

    case ctrl
    when "material_check_sheet", "purchase_request","material_outgoing","virtual_receiving","material_receiving","sterilization_product_receiving","finish_good_receiving","invoice_supplier_receiving"
      search = "#{prefix_code}/#{year_yy}/#{month_mm}/" 
      records = records.where("number LIKE ?", "#{search}%")
    when "delivery_order","picking_slip","direct_labor", "production_order","pdm","product_receiving","delivery_order_supplier","general_receiving","consumable_receiving","equipment_receiving"
      search = "#{prefix_code}#{year_yy}#{month_mm}"
      records = records.where("number LIKE ?", "#{search}%") 
    when 'routine_cost','routine_cost_payment','cash_submission','proof_cash_expenditure'
      search = "#{prefix_code}/#{dept_prefix}/#{year_yy}/#{month_mm}/"
      records = records.where("number LIKE ?", "#{search}%")
    when 'cash_settlement' 
      search = "/#{dept_prefix}/#{year_yy}/#{month_mm}/"
      records = records.where("number LIKE ?", "%#{search}%").order("id asc")
    when "voucher_payment_receiving", "voucher_payment"
      search = "#{prefix_code} #{year_yy}-#{month_mm}"
      records = records.where("number LIKE ?", "#{search}%")
    when 'proforma_invoice_customer'
      search = "#{prefix_code}-#{year_yy}"
      records = records.where("number LIKE ?", "#{search}%")
    end
    records = records.order("number asc")

    case ctrl 
    when "sales_order"
      # seq 2 digit
      seq = (records.present? ? records.last.number.to_s[i,2].to_i+1 : 1)
      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
    when "proforma_invoice_customer", "payment_request_supplier", "inventory_adjustment","sterilization_product_receiving","virtual_receiving","material_receiving","material_outgoing", "finish_good_receiving", "semi_finish_good_receiving", "semi_finish_good_outgoing", "shop_floor_order", "shop_floor_order_sterilization", "invoice_customer","purchase_order_supplier", "purchase_request","routine_cost",'routine_cost_payment','cash_submission','cash_settlement','proof_cash_expenditure'
      # seq 3 digit
      case ctrl
      when "purchase_order_supplier", "payment_request_supplier","routine_cost",'routine_cost_payment','cash_submission','cash_settlement','proof_cash_expenditure', 'proforma_invoice_customer'
        seq = (records.present? ? "#{records.last.number}".last(3).to_i+1 : 1)
      else
        seq = (records.present? ? records.last.number.to_s[i,3].to_i+1 : 1)
      end

      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "00"+seq.to_s
      elsif length_seq == 2 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
    else
      # seq 4 digit
      case ctrl
      when "material_check_sheet","invoice_supplier_receiving", "direct_labor", "production_order","pdm", "voucher_payment_receiving", "voucher_payment"
        seq = (records.present? ? "#{records.last.number}".last(4).to_i+1 : 1)
      else
        seq = (records.present? ? records.last.number.to_s[i,4].to_i+1 : 1)
      end
      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "000"+seq.to_s
      elsif length_seq == 2 
        number = "00"+seq.to_s
      elsif length_seq == 3 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
    end

    case ctrl 
    when "delivery_order","picking_slip","direct_labor", "production_order","pdm","product_receiving","delivery_order_supplier","general_receiving","consumable_receiving","equipment_receiving"
      seq_number = "#{prefix_code}#{year_yy}#{month_mm}#{number}"
    when "purchase_request","material_outgoing","virtual_receiving","material_receiving","sterilization_product_receiving","finish_good_receiving","invoice_supplier_receiving"
      seq_number = "#{prefix_code}/#{year_yy}/#{month_mm}/#{number}" 
    when "purchase_order_supplier"
      seq_number = "#{prefix_code}/#{year_yy}/#{RomanNumerals.to_roman(period.strftime("%m").to_i)}/#{number}" 
    when "invoice_customer"
      case period.strftime("%m")
      when '01'
        alphabet_month = 'A'
      when '02'
        alphabet_month = 'B'
      when '03'
        alphabet_month = 'C'
      when '04'
        alphabet_month = 'D'
      when '05'
        alphabet_month = 'E'
      when '06'
        alphabet_month = 'F'
      when '07'
        alphabet_month = 'G'
      when '08'
        alphabet_month = 'H'
      when '09'
        alphabet_month = 'I'
      when '10'
        alphabet_month = 'J'
      when '11'
        alphabet_month = 'K'
      when '12'
        alphabet_month = 'L'
      end
      seq_number = "#{year_yy}#{alphabet_month}#{number}" 
    when "sales_order"
      seq_number = "#{prefix_code}/#{number}/#{RomanNumerals.to_roman(period.strftime("%m").to_i)}/#{year_yyyy}"
    when "payment_request_supplier"
      seq_number = "#{prefix_code}/#{year_yyyy}/#{month_to_letter[month_mm.to_i]}/#{number}"
    when 'routine_cost','routine_cost_payment','cash_submission','cash_settlement','proof_cash_expenditure'
      seq_number = "#{prefix_code}/#{dept_prefix}/#{year_yy}/#{month_mm}/#{number}"
    when 'voucher_payment_receiving', 'voucher_payment'
      seq_number = "#{prefix_code} #{year_yy}-#{month_mm}#{number}"
    when 'proforma_invoice_customer'
      case period.strftime("%m")
      when '01'
        alphabet_month = 'A'
      when '02'
        alphabet_month = 'B'
      when '03'
        alphabet_month = 'C'
      when '04'
        alphabet_month = 'D'
      when '05'
        alphabet_month = 'E'
      when '06'
        alphabet_month = 'F'
      when '07'
        alphabet_month = 'G'
      when '08'
        alphabet_month = 'H'
      when '09'
        alphabet_month = 'I'
      when '10'
        alphabet_month = 'J'
      when '11'
        alphabet_month = 'K'
      when '12'
        alphabet_month = 'L'
      end
      seq_number = "#{prefix_code}-#{year_yy}#{alphabet_month}#{number}"
    else
      seq_number = prefix_code+"/"+year_yy+"/"+month_mm+"/"+number
    end
    puts "new number: #{seq_number}"
    return seq_number
  end

  def invoice_supplier_receiving_index_number(id, efaktur_number, invoice_date, tax_rate_currency_value, currency_id, dpp, remarks)
    record = InvoiceSupplierReceiving.find_by(:id=> id)
    if record.present?
      result = {}
      receipt_date = record.date
      tax_invoice = SupplierTaxInvoice.find_by(:company_profile_id=> current_user.company_profile_id, :supplier_id=> record.supplier_id, :number=> efaktur_number)
      if currency_id == 1 
        my_dpp = dpp.to_f
      else
        my_dpp = (dpp.to_f*tax_rate_currency_value.to_f)
      end

      if efaktur_number.present? and efaktur_number.to_s[0, 2] == '01'
        my_ppn = (my_dpp*0.1)
      else
        my_ppn = 0
      end

      if efaktur_number.present?
        if tax_rate_currency_value.to_f > 0
          supplier_tax_invoice_id = nil
          if tax_invoice.present?
            supplier_tax_invoice_id = tax_invoice.id
            tax_invoice.update({
              :date=> invoice_date, :periode=> invoice_date.to_date.strftime("%Y%m"),
              :dpptotal=> my_dpp.to_f+tax_invoice.dpptotal.to_f, 
              :ppntotal=> my_ppn.to_f+tax_invoice.ppntotal.to_f})
          else
            tax_invoice = SupplierTaxInvoice.create({
              :company_profile_id=> current_user.company_profile_id,
              :date=> invoice_date, :periode=> invoice_date.to_date.strftime("%Y%m"),
              :supplier_id=> record.supplier_id,
              :number=> efaktur_number, 
              :dpptotal=> my_dpp,
              :ppntotal=> my_ppn,
              :remarks=> remarks,
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            supplier_tax_invoice_id = tax_invoice.id
          end
        end
      end

      
      last_record = InvoiceSupplierReceivingItem.where(:status=> 'active').includes(:invoice_supplier_receiving).where(:invoice_supplier_receivings => {:company_profile_id => current_user.company_profile_id }).where("invoice_supplier_receivings.date between ? and ?", receipt_date.to_date.at_beginning_of_month(), receipt_date.to_date.at_end_of_month()).order("invoice_supplier_receiving_items.index_number desc").limit(1)
      
      case receipt_date.to_date.strftime("%m")
      when '01'
        month_alfabet = 'A'
      when '02'
        month_alfabet = 'B'
      when '03'
        month_alfabet = 'C'
      when '04'
        month_alfabet = 'D'
      when '05'
        month_alfabet = 'E'
      when '06'
        month_alfabet = 'F'
      when '07'
        month_alfabet = 'G'
      when '08'
        month_alfabet = 'H'
      when '09'
        month_alfabet = 'I'
      when '10'
        month_alfabet = 'J'
      when '11'
        month_alfabet = 'K'
      when '12'
        month_alfabet = 'L'
      end
      plant_code = 'M'
      if last_record.present?
        last_number_right = "#{last_record.last.index_number}".last(3)
        last_number_length = "#{last_number_right.to_i+1}".length()

        if last_number_right.present?
          if last_number_length.to_i == 1  
            last_number_digit = '00'
          elsif last_number_length.to_i == 2
            last_number_digit = '0'
          else
            last_number_digit = ''
          end

          last_number = "#{last_number_digit}#{last_number_right.to_i+1}"
          index_number = "#{receipt_date.to_date.strftime("%y")}#{month_alfabet}#{plant_code}#{last_number}"
        else
          index_number = "#{receipt_date.to_date.strftime("%y")}#{month_alfabet}#{plant_code}001"
        end
      else
        index_number = "#{receipt_date.to_date.strftime("%y")}#{month_alfabet}#{plant_code}001"
      end
    end
    return {:supplier_tax_invoice_id=> supplier_tax_invoice_id, :index_number=> index_number}
  end

  def create_supplier_ap_recap(period, supplier, amount_payment, item, supplier_tax_invoice_id, invoice_supplier_receiving_item_id)
    
    supplier_id = (supplier.present? ? supplier.id : nil)
    erp_system = item["erp_system"]
    invoice_number = item["invoice_number"]
    invoice_date = item["invoice_date"]
    dpp = item["dpp"]
    ppn = item["ppn"]
    total = item["total"]
    remarks = item["remarks"]
    fp_number = item["fp_number"]
    currency_id = item["currency_id"]
    tax_id = (supplier.present? ? supplier.tax_id : nil)
    term_of_payment_id = (supplier.present? ? supplier.term_of_payment_id : nil)
    top_day = (supplier.present? ? supplier.top_day : nil)
    tax_rate_id = item["tax_rate_id"]

    logger.info "period => #{period}"
    logger.info "supplier_id => #{supplier.present? ? supplier.id : nil}"
    logger.info "amount_payment => #{amount_payment}"
    logger.info "erp_system => #{erp_system}"
    logger.info "invoice_number => #{invoice_number}"
    logger.info "invoice_date => #{invoice_date}"
    logger.info "dpp => #{dpp}, ppn => #{ppn}, total => #{total}"
    logger.info "remarks => #{remarks}"
    logger.info "supplier_tax_invoice_id => #{supplier_tax_invoice_id}"
    logger.info "fp_number => #{fp_number}"
    logger.info "invoice_supplier_receiving_item_id => #{invoice_supplier_receiving_item_id}"
    logger.info "tax_id => #{tax_id}"
    logger.info "tax_rate_id => #{tax_rate_id}"
    logger.info "top_day => #{top_day}"
    logger.info "term_of_payment_id => #{term_of_payment_id}"
    # period = YYYYMM
    invoice_supplier = InvoiceSupplier.find_by(:company_profile_id=> current_user.company_profile_id, :number=> invoice_number, :supplier_id=> supplier_id)
    check_ap = SupplierApRecap.find_by(:company_profile_id=> current_user.company_profile_id, :supplier_id=> supplier_id, :periode=> period)
    if check_ap.present?
      check_ap.update_columns({
        :debt=> (check_ap.debt.to_f + total.to_f),
        :payment=> (check_ap.payment.to_f + amount_payment.to_f),
        :remaining_debt=> (total.to_f - amount_payment.to_f),
        :updated_by=> current_user.id, :updated_at=> DateTime.now()
      })
    else
      SupplierApRecap.create({
        :company_profile_id=> current_user.company_profile_id, 
        :supplier_id=> supplier_id, 
        :periode=> period,
        :debt=> total,
        :payment=> amount_payment,
        :remaining_debt=> (total.to_f - amount_payment.to_f),
        :status=> 'active',
        :created_by=> current_user.id, :created_at=> DateTime.now()
      })
    end

    if erp_system.to_i == 1
      if invoice_supplier.present?
        invoice_supplier.update_columns({:invoice_supplier_receiving_item_id=> invoice_supplier_receiving_item_id})
      else
        if ppn.to_f > 0
          subtotal = (dpp.to_f / ppn.to_f)
        else
          subtotal = dpp.to_f
        end
        logger.info "subtotal => #{subtotal}"
        invoice_supplier = InvoiceSupplier.new({
          :company_profile_id=> current_user.company_profile_id, 
          :currency_id=> currency_id,
          :tax_id=> tax_id,
          :tax_rate_id=> tax_rate_id,
          :top_day=> top_day,
          :term_of_payment_id=> term_of_payment_id,
          :supplier_tax_invoice_id=> supplier_tax_invoice_id,
          :invoice_supplier_receiving_item_id=> invoice_supplier_receiving_item_id,
          :fp_number=> fp_number,
          :number=> invoice_number, 
          :supplier_id=> supplier_id,
          :date=> invoice_date,
          :subtotal=> subtotal.to_f,
          :ppntotal=> ppn.to_f,
          :grandtotal=> total.to_f,
          :remarks=> remarks,
          :status=> 'new',
          :created_by=> current_user.id, :created_at=> DateTime.now()
        })
        invoice_supplier.save!
      end
    end

  end

  def inventory(ctrl_name, tbl_id, periode, prev_periode, kind)
    puts "#{ctrl_name}, #{tbl_id}, #{periode}, #{prev_periode}, #{kind}"
    process_stock = true
    case ctrl_name
    when 'internal_transfers'
      tbl_name = 'internal_transfer'
      tbl_record = tbl_name.camelize.constantize.find_by(:id=> tbl_id)
      if tbl_record.present?
        if tbl_record.transfer_from == 'Warehouse FG' or tbl_record.transfer_from == 'Warehouse RM'
          tbl_kind = 'out'
        else
          tbl_kind = 'in'
        end
      end
    when 'material_returns', 'material_receivings', 'product_receivings', 'general_receivings', 'consumable_receivings', 'equipment_receivings'
      tbl_name = ctrl_name.singularize
      tbl_kind = 'in'
    when 'sterilization_product_receivings'
      tbl_name = 'sterilization_product_receiving'
      tbl_kind = 'in'
      process_stock = false
      # produk WIP tidak diproses untuk nambah stok
    when 'finish_good_receivings'
      tbl_name = 'finish_good_receiving'
      tbl_kind = 'in'
    when 'semi_finish_good_receivings'
      tbl_name = 'semi_finish_good_receiving'
      tbl_kind = 'in'
      process_stock = false
      # produk WIP tidak diproses untuk nambah stok
    when 'semi_finish_good_outgoings'
      tbl_name = 'semi_finish_good_outgoing'
      tbl_kind = 'out'
      process_stock = false
      # produk WIP tidak diproses untuk kurangi stok
    when 'delivery_order_suppliers'
      tbl_name = 'delivery_order_supplier'
      tbl_kind = 'out'
    when 'delivery_orders'
      tbl_name = 'delivery_order'
      tbl_kind = 'out'
    when 'material_outgoings','material_additionals'
      tbl_name = ctrl_name.singularize
      tbl_kind = 'out'
    when 'inventory_adjustments'
      tbl_name = 'inventory_adjustment'
    end

    tbl_id_name = "#{tbl_name}_id"
    tbl_item_id_name = "#{tbl_name}_item_id"
    ("#{tbl_name}_item").camelize.constantize.where("#{tbl_id_name}".to_sym => tbl_id, :status=> 'active').each do |item|
      if ctrl_name == 'material_returns' and item.category == 'Not Good'
        # masuknya ke rejected material storage
        
        if item.has_attribute?(:product_id) and item.product.present?
          inventory      = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :product_id=> item.product_id, :periode=> periode)
          prev_inventory = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :product_id=> item.product_id, :periode=> prev_periode)
          if item.has_attribute?(:product_batch_number_id)
            inventory_batch_number = TemporaryInventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :product_batch_number_id => item.product_batch_number_id, :product_id=> item.product_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:material_id) and item.material.present?
          inventory      = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :material_id=> item.material_id, :periode=> periode)
          prev_inventory = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :material_id=> item.material_id, :periode=> prev_periode)
          if item.has_attribute?(:material_batch_number_id)
            inventory_batch_number = TemporaryInventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :material_batch_number_id => item.material_batch_number_id, :material_id=> item.material_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:general_id) and item.general.present?
          inventory      = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :general_id=> item.general_id, :periode=> periode)
          prev_inventory = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :general_id=> item.general_id, :periode=> prev_periode)
          if item.has_attribute?(:general_batch_number_id)
            inventory_batch_number = TemporaryInventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :general_batch_number_id => item.general_batch_number_id, :general_id=> item.general_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:consumable_id) and item.consumable.present?
          inventory      = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :consumable_id=> item.consumable_id, :periode=> periode)
          prev_inventory = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :consumable_id=> item.consumable_id, :periode=> prev_periode)
          if item.has_attribute?(:consumable_batch_number_id)
            inventory_batch_number = TemporaryInventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :consumable_batch_number_id => item.consumable_batch_number_id, :consumable_id=> item.consumable_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:equipment_id) and item.equipment.present?
          inventory      = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :equipment_id=> item.equipment_id, :periode=> periode)
          prev_inventory = TemporaryInventory.find_by(:company_profile_id=> current_user.company_profile_id, :equipment_id=> item.equipment_id, :periode=> prev_periode)
          if item.has_attribute?(:equipment_batch_number_id)
            inventory_batch_number = TemporaryInventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :equipment_batch_number_id => item.equipment_batch_number_id, :equipment_id=> item.equipment_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        else
          inventory      = nil
          prev_inventory = nil
          inventory_batch_number = nil
        end
        
        inventory_log = TemporaryInventoryLog.find_by("#{tbl_item_id_name}".to_sym => item.id, :company_profile_id=> current_user.company_profile_id, :periode=> periode, :status=> 'active')

        if inventory_log.present?
          inventory_log.update({
            :status=> 'delete'
          })
        end
        if inventory.present?
          case tbl_kind
          when 'in'
            case kind
            when 'approved'
              trans_in = (inventory.trans_in.to_f+item.quantity.to_f)
            when 'canceled' 
              trans_in = (inventory.trans_in.to_f-item.quantity.to_f)
            end
            if item.has_attribute?(:product_id) and item.product.present?
              inventory.update({
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_id) and item.material.present?
              inventory.update({
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_id) and item.general.present?
              inventory.update({
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_id) and item.consumable.present?
              inventory.update({
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_id) and item.equipment.present?
              inventory.update({
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            end
          when 'out'
            case kind
            when 'approved'
              trans_out = (inventory.trans_out.to_f+item.quantity.to_f)
            when 'canceled' 
              trans_out = (inventory.trans_out.to_f-item.quantity.to_f)
            end
            if item.has_attribute?(:product_id) and item.product.present?
              inventory.update({
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_id) and item.material.present?
              inventory.update({
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_id) and item.general.present?
              inventory.update({
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_id) and item.consumable.present?
              inventory.update({
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_id) and item.equipment.present?
              inventory.update({
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            end
          end
        else
          case tbl_kind
          when 'in'
            case kind
            when 'approved'
              trans_in = item.quantity.to_f
            when 'canceled' 
              trans_in = item.quantity.to_f
            end
            if item.has_attribute?(:product_id) and item.product.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_id) and item.material.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_id) and item.general.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_id) and item.consumable.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_id) and item.equipment.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            end
          when 'out'
            case kind
            when 'approved'
              trans_out = item.quantity.to_f
            when 'canceled' 
              trans_out = item.quantity.to_f
            end
            if item.has_attribute?(:product_id) and item.product.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_id) and item.material.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_id) and item.general.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_id) and item.consumable.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_id) and item.equipment.present?
              inventory = TemporaryInventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            end
          end
        end

        if inventory_batch_number.present?
          case tbl_kind
          when 'in'
            case kind
            when 'approved'
              trans_in = (inventory_batch_number.trans_in.to_f+item.quantity.to_f)
            when 'canceled' 
              trans_in = (inventory_batch_number.trans_in.to_f-item.quantity.to_f)
            end
            if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
              inventory_batch_number.update({
                :product_batch_number_id=> item.product_batch_number_id,
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
              inventory_batch_number.update({
                :material_batch_number_id=> item.material_batch_number_id,
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
              inventory_batch_number.update({
                :general_batch_number_id=> item.general_batch_number_id,
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
              inventory_batch_number.update({
                :consumable_batch_number_id=> item.consumable_batch_number_id,
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
              inventory_batch_number.update({
                :equipment_batch_number_id=> item.equipment_batch_number_id,
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            end
          when 'out'
            case kind
            when 'approved'
              trans_out = (inventory_batch_number.trans_out.to_f+item.quantity.to_f)
            when 'canceled' 
              trans_out = (inventory_batch_number.trans_out.to_f-item.quantity.to_f)
            end
            if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
              inventory_batch_number.update({
                :product_batch_number_id=> item.product_batch_number_id,
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
              inventory_batch_number.update({
                :material_batch_number_id=> item.material_batch_number_id,
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
              inventory_batch_number.update({
                :general_batch_number_id=> item.general_batch_number_id,
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
              inventory_batch_number.update({
                :consumable_batch_number_id=> item.consumable_batch_number_id,
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
              inventory_batch_number.update({
                :equipment_batch_number_id=> item.equipment_batch_number_id,
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            end
          end
        else
          case tbl_kind
          when 'in'
            case kind
            when 'approved'
              trans_in = item.quantity.to_f
            when 'canceled' 
              trans_in = item.quantity.to_f
            end
            if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :product_batch_number_id=> item.product_batch_number_id,
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :material_batch_number_id=> item.material_batch_number_id,
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :general_batch_number_id=> item.general_batch_number_id,
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_in => trans_in,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :consumable_batch_number_id=> item.consumable_batch_number_id,
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :equipment_batch_number_id=> item.equipment_batch_number_id,
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_in => trans_in,
                :updated_at=> DateTime.now()
              })
            end
          when 'out'
            case kind
            when 'approved'
              trans_out = item.quantity.to_f
            when 'canceled' 
              trans_out = item.quantity.to_f
            end
            if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :product_batch_number_id=> item.product_batch_number_id,
                :product_id=> item.product_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :material_batch_number_id=> item.material_batch_number_id,
                :material_id=> item.material_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :general_batch_number_id=> item.general_batch_number_id,
                :general_id=> item.general_id,
                :periode=> periode,
                :trans_out => trans_out,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :consumable_batch_number_id=> item.consumable_batch_number_id,
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
              inventory_batch_number = TemporaryInventoryBatchNumber.create({
                :company_profile_id=> current_user.company_profile_id, 
                :equipment_batch_number_id=> item.equipment_batch_number_id,
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :trans_out => trans_out,
                :updated_at=> DateTime.now()
              })
            end
          end
        end

        if kind == 'approved'
          inventory_log = TemporaryInventoryLog.create({
            :company_profile_id=> current_user.company_profile_id, 
            :temporary_inventory_id=> inventory.id,
            "#{tbl_item_id_name}".to_sym => item.id,
            :periode=> periode,
            :kind=> tbl_kind, :status=> 'active',
            :quantity=> item.quantity,
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          logger.info inventory_log.errors.full_messages
        end
      else
        if ctrl_name == 'inventory_adjustments'
          if item.quantity > 0 
            puts "Positive number: #{item.quantity}"
            tbl_kind = 'in'
            item.quantity = item.quantity.abs
          else 
            if item.quantity == 0
              puts "Zero"
              tbl_kind = ''
              item.quantity = item.quantity
            else
              puts "Negative number: #{item.quantity}"
              tbl_kind = 'out'
              item.quantity = item.quantity.abs
            end
          end
        end

        if item.has_attribute?(:product_id) and item.product.present?
          inventory      = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :product_id=> item.product_id, :periode=> periode)
          prev_inventory = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :product_id=> item.product_id, :periode=> prev_periode)
          if item.has_attribute?(:product_batch_number_id)
            inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :product_batch_number_id => item.product_batch_number_id, :product_id=> item.product_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:material_id) and item.material.present?
          inventory      = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :material_id=> item.material_id, :periode=> periode)
          prev_inventory = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :material_id=> item.material_id, :periode=> prev_periode)
          if item.has_attribute?(:material_batch_number_id)
            inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :material_batch_number_id => item.material_batch_number_id, :material_id=> item.material_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:general_id) and item.general.present?
          inventory      = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :general_id=> item.general_id, :periode=> periode)
          prev_inventory = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :general_id=> item.general_id, :periode=> prev_periode)
          if item.has_attribute?(:general_batch_number_id)
            inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :general_batch_number_id => item.general_batch_number_id, :general_id=> item.general_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:consumable_id) and item.consumable.present?
          inventory      = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :consumable_id=> item.consumable_id, :periode=> periode)
          prev_inventory = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :consumable_id=> item.consumable_id, :periode=> prev_periode)
          if item.has_attribute?(:consumable_batch_number_id)
            inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :consumable_batch_number_id => item.consumable_batch_number_id, :consumable_id=> item.consumable_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        elsif item.has_attribute?(:equipment_id) and item.equipment.present?
          inventory      = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :equipment_id=> item.equipment_id, :periode=> periode)
          prev_inventory = Inventory.find_by(:company_profile_id=> current_user.company_profile_id, :equipment_id=> item.equipment_id, :periode=> prev_periode)
          if item.has_attribute?(:equipment_batch_number_id)
            inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> current_user.company_profile_id, :equipment_batch_number_id => item.equipment_batch_number_id, :equipment_id=> item.equipment_id, :periode=> periode)
          else
            inventory_batch_number = nil
          end
        else
          inventory      = nil
          prev_inventory = nil
          inventory_batch_number = nil
        end
        
        inventory_log = InventoryLog.find_by("#{tbl_item_id_name}".to_sym => item.id, :company_profile_id=> current_user.company_profile_id, :periode=> periode, :status=> 'active')

        if inventory_log.present?
          inventory_log.update({
            :status=> 'delete'
          })
        end

        if process_stock == true
          if inventory.present?
            case tbl_kind
            when 'in'
              case kind
              when 'approved'
                trans_in = (inventory.trans_in.to_f+item.quantity.to_f)
              when 'canceled' 
                trans_in = (inventory.trans_in.to_f-item.quantity.to_f)
              end
              if item.has_attribute?(:product_id) and item.product.present?
                inventory.update({
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_id) and item.material.present?
                inventory.update({
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_id) and item.general.present?
                inventory.update({
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_id) and item.consumable.present?
                inventory.update({
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_id) and item.equipment.present?
                inventory.update({
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              end
            when 'out'
              case kind
              when 'approved'
                trans_out = (inventory.trans_out.to_f+item.quantity.to_f)
              when 'canceled' 
                trans_out = (inventory.trans_out.to_f-item.quantity.to_f)
              end
              if item.has_attribute?(:product_id) and item.product.present?
                inventory.update({
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_id) and item.material.present?
                inventory.update({
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_id) and item.general.present?
                inventory.update({
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_id) and item.consumable.present?
                inventory.update({
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_id) and item.equipment.present?
                inventory.update({
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              end
            end
          else
            case tbl_kind
            when 'in'
              case kind
              when 'approved'
                trans_in = item.quantity.to_f
              when 'canceled' 
                trans_in = item.quantity.to_f
              end
              if item.has_attribute?(:product_id) and item.product.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_id) and item.material.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_id) and item.general.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_id) and item.consumable.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_id) and item.equipment.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              end
            when 'out'
              case kind
              when 'approved'
                trans_out = item.quantity.to_f
              when 'canceled' 
                trans_out = item.quantity.to_f
              end
              if item.has_attribute?(:product_id) and item.product.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_id) and item.material.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_id) and item.general.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_id) and item.consumable.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_id) and item.equipment.present?
                inventory = Inventory.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              end
            end
          end

          if inventory_batch_number.present?
            case tbl_kind
            when 'in'
              case kind
              when 'approved'
                trans_in = (inventory_batch_number.trans_in.to_f+item.quantity.to_f)
              when 'canceled' 
                trans_in = (inventory_batch_number.trans_in.to_f-item.quantity.to_f)
              end
              if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
                inventory_batch_number.update({
                  :product_batch_number_id=> item.product_batch_number_id,
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
                inventory_batch_number.update({
                  :material_batch_number_id=> item.material_batch_number_id,
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
                inventory_batch_number.update({
                  :general_batch_number_id=> item.general_batch_number_id,
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
                inventory_batch_number.update({
                  :consumable_batch_number_id=> item.consumable_batch_number_id,
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
                inventory_batch_number.update({
                  :equipment_batch_number_id=> item.equipment_batch_number_id,
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              end
            when 'out'
              case kind
              when 'approved'
                trans_out = (inventory_batch_number.trans_out.to_f+item.quantity.to_f)
              when 'canceled' 
                trans_out = (inventory_batch_number.trans_out.to_f-item.quantity.to_f)
              end
              if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
                inventory_batch_number.update({
                  :product_batch_number_id=> item.product_batch_number_id,
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
                inventory_batch_number.update({
                  :material_batch_number_id=> item.material_batch_number_id,
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
                inventory_batch_number.update({
                  :general_batch_number_id=> item.general_batch_number_id,
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
                inventory_batch_number.update({
                  :consumable_batch_number_id=> item.consumable_batch_number_id,
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
                inventory_batch_number.update({
                  :equipment_batch_number_id=> item.equipment_batch_number_id,
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              end
            end
          else
            case tbl_kind
            when 'in'
              case kind
              when 'approved'
                trans_in = item.quantity.to_f
              when 'canceled' 
                trans_in = item.quantity.to_f
              end
              if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :product_batch_number_id=> item.product_batch_number_id,
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :material_batch_number_id=> item.material_batch_number_id,
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :general_batch_number_id=> item.general_batch_number_id,
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :consumable_batch_number_id=> item.consumable_batch_number_id,
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :equipment_batch_number_id=> item.equipment_batch_number_id,
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_in => trans_in,
                  :updated_at=> DateTime.now()
                })
              end
            when 'out'
              case kind
              when 'approved'
                trans_out = item.quantity.to_f
              when 'canceled' 
                trans_out = item.quantity.to_f
              end
              if item.has_attribute?(:product_batch_number_id) and item.product_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :product_batch_number_id=> item.product_batch_number_id,
                  :product_id=> item.product_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:material_batch_number_id) and item.material_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :material_batch_number_id=> item.material_batch_number_id,
                  :material_id=> item.material_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:general_batch_number_id) and item.general_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :general_batch_number_id=> item.general_batch_number_id,
                  :general_id=> item.general_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :created_at=> DateTime.now()
                })
              elsif item.has_attribute?(:consumable_batch_number_id) and item.consumable_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :consumable_batch_number_id=> item.consumable_batch_number_id,
                  :consumable_id=> item.consumable_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              elsif item.has_attribute?(:equipment_batch_number_id) and item.equipment_batch_number.present?
                inventory_batch_number = InventoryBatchNumber.create({
                  :company_profile_id=> current_user.company_profile_id, 
                  :equipment_batch_number_id=> item.equipment_batch_number_id,
                  :equipment_id=> item.equipment_id,
                  :periode=> periode,
                  :trans_out => trans_out,
                  :updated_at=> DateTime.now()
                })
              end
            end
          end
        else
          if inventory.blank?
            if item.has_attribute?(:product_id) and item.product.present?
              inventory = Inventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :product_id=> item.product_id,
                :periode=> periode,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:material_id) and item.material.present?
              inventory = Inventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :material_id=> item.material_id,
                :periode=> periode,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:general_id) and item.general.present?
              inventory = Inventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :general_id=> item.general_id,
                :periode=> periode,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:consumable_id) and item.consumable.present?
              inventory = Inventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :consumable_id=> item.consumable_id,
                :periode=> periode,
                :created_at=> DateTime.now()
              })
            elsif item.has_attribute?(:equipment_id) and item.equipment.present?
              inventory = Inventory.create({
                :company_profile_id=> current_user.company_profile_id, 
                :equipment_id=> item.equipment_id,
                :periode=> periode,
                :created_at=> DateTime.now()
              })
            end
          end
        end

        if kind == 'approved' and tbl_kind.present?
          inventory_log = InventoryLog.create({
            :company_profile_id=> current_user.company_profile_id, 
            :inventory_id=> inventory.id,
            "#{tbl_item_id_name}".to_sym => item.id,
            :periode=> periode,
            :kind=> tbl_kind, :status=> 'active',
            :quantity=> item.quantity,
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          logger.info inventory_log.errors.full_messages
        end
      end
    end
  end

  def internal_transfer_kind_defined(kind)
    case kind
    when 'Warehouse FG'
      prefix_1 = 'WHFG'
    when 'Warehouse RAW Material'
      prefix_1 = 'WHRM'
    when 'Production'
      prefix_1 = 'PRD'
    when '2nd Process'
      prefix_1 = '2ND'
    when 'Quality Control'
      prefix_1 = 'QCT'
    end
    return prefix_1
  end


  def gen_product_batch_number(product_id, periode)
    # 20200903: jika sfo item didelete maka batch number diubah menjadi suspend, dan penomorannya bisa digunakan dengan SFO lain
    # ABCC20001
    product = Product.find_by(:id=> product_id)
    periode_yyyy = periode.to_date.strftime("%Y")
    periode_yy   = periode.to_date.strftime("%y")

    if product.present?
      batch_number =  ProductBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :product_id=> product.id, :periode_yyyy=> periode_yyyy, :status=> 'active').order("number asc")
      if batch_number.present?
        last_batch_number = batch_number.last.number
        
        # seq 3 digit
        seq = (batch_number.present? ? batch_number.last.number.to_s[6,3].to_i+1 : 1)
        length_seq = seq.to_s.length

        if length_seq == 1 
          seq_number = "00"+seq.to_s
        elsif length_seq == 2 
          seq_number = "0"+seq.to_s
        else
          seq_number = seq.to_s
        end

        result = "#{product.part_id}#{periode_yy}#{seq_number}"
      else
        result = "#{product.part_id}#{periode_yy}001"
      end
    end
    return result
  end
  def gen_material_batch_number(material_id, periode)
    # A00120F01
    # beda bulan balik lagi ke 01
    material = Material.find_by(:id=> material_id)
    periode_yyyy = periode.to_date.strftime("%Y")
    periode_yy   = periode.to_date.strftime("%y")
    periode_mm   = periode.to_date.strftime("%m")

    case periode_mm
    when '01'
      alphabet_month = 'A'
    when '02'
      alphabet_month = 'B'
    when '03'
      alphabet_month = 'C'
    when '04'
      alphabet_month = 'D'
    when '05'
      alphabet_month = 'E'
    when '06'
      alphabet_month = 'F'
    when '07'
      alphabet_month = 'G'
    when '08'
      alphabet_month = 'H'
    when '09'
      alphabet_month = 'J'
    when '10'
      alphabet_month = 'K'
    when '11'
      alphabet_month = 'L'
    when '12'
      alphabet_month = 'M'
    end

    if material.present?
      batch_number =  MaterialBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :material_id=> material.id, :periode_yyyy=> periode_yyyy, :periode_mm=> periode_mm, :status=> 'active').order("number asc")
      if batch_number.present?
        last_batch_number = batch_number.last.number
        # contoh
        # B089-20D01
        # seq 2 digit
        seq = (batch_number.present? ? batch_number.last.number.to_s[8,2].to_i+1 : 1)
        length_seq = seq.to_s.length

        if length_seq == 1 
          seq_number = "0"+seq.to_s
        else
          seq_number = seq.to_s
        end

        result = "#{material.part_id}-#{periode_yy}#{alphabet_month}#{seq_number}"
      else
        result = "#{material.part_id}-#{periode_yy}#{alphabet_month}01"
      end
    end
    puts result
    return result
  end

  def gen_general_batch_number(general_id, periode)
    # ABCC20001
    general = General.find_by(:id=> general_id)
    periode_yyyy = periode.to_date.strftime("%Y")
    periode_yy   = periode.to_date.strftime("%y")

    if general.present?
      batch_number =  GeneralBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :general_id=> general.id, :periode_yyyy=> periode_yyyy, :status=> 'active').order("number asc")
      if batch_number.present?
        last_batch_number = batch_number.last.number
        
        # seq 3 digit
        seq = (batch_number.present? ? batch_number.last.number.to_s[6,3].to_i+1 : 1)
        length_seq = seq.to_s.length

        if length_seq == 1 
          seq_number = "00"+seq.to_s
        elsif length_seq == 2 
          seq_number = "0"+seq.to_s
        else
          seq_number = seq.to_s
        end

        result = "#{general.part_id}#{periode_yy}#{seq_number}"
      else
        result = "#{general.part_id}#{periode_yy}001"
      end
    end
    return result
  end
  def gen_consumable_batch_number(consumable_id, periode)
    # ABCC20001
    consumable = Consumable.find_by(:id=> consumable_id)
    periode_yyyy = periode.to_date.strftime("%Y")
    periode_yy   = periode.to_date.strftime("%y")

    if consumable.present?
      batch_number =  ConsumableBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :consumable_id=> consumable.id, :periode_yyyy=> periode_yyyy, :status=> 'active').order("number asc")
      if batch_number.present?
        last_batch_number = batch_number.last.number
        
        # seq 3 digit
        seq = (batch_number.present? ? batch_number.last.number.to_s[6,3].to_i+1 : 1)
        length_seq = seq.to_s.length

        if length_seq == 1 
          seq_number = "00"+seq.to_s
        elsif length_seq == 2 
          seq_number = "0"+seq.to_s
        else
          seq_number = seq.to_s
        end

        result = "#{consumable.part_id}#{periode_yy}#{seq_number}"
      else
        result = "#{consumable.part_id}#{periode_yy}001"
      end
    end
    return result
  end
  def gen_equipment_batch_number(equipment_id, periode)
    # ABCC20001
    equipment = Equipment.find_by(:id=> equipment_id)
    periode_yyyy = periode.to_date.strftime("%Y")
    periode_yy   = periode.to_date.strftime("%y")

    if equipment.present?
      batch_number =  EquipmentBatchNumber.where(:company_profile_id=> current_user.company_profile_id, :equipment_id=> equipment.id, :periode_yyyy=> periode_yyyy, :status=> 'active').order("number asc")
      if batch_number.present?
        last_batch_number = batch_number.last.number
        
        # seq 3 digit
        seq = (batch_number.present? ? batch_number.last.number.to_s[6,3].to_i+1 : 1)
        length_seq = seq.to_s.length

        if length_seq == 1 
          seq_number = "00"+seq.to_s
        elsif length_seq == 2 
          seq_number = "0"+seq.to_s
        else
          seq_number = seq.to_s
        end

        result = "#{equipment.part_id}#{periode_yy}#{seq_number}"
      else
        result = "#{equipment.part_id}#{periode_yy}001"
      end
    end
    return result
  end

  def feature(field)
    if controller_name == 'accounts'
      permission_base_link = 'users' 
    else
      permission_base_link = controller_name
    end
    link_param = (params[:q].present? ? "?q=#{params[:q]}" : nil)
    link_param += "&q1=#{params[:q1]}" if params[:q1].present?
    link_param += "&q2=#{params[:q2]}" if params[:q2].present?
    if link_param.present?
      link_param += "&tbl_kind=#{params[:tbl_kind]}" if params[:tbl_kind].present?
    else
      link_param = "?tbl_kind=#{params[:tbl_kind]}" if params[:tbl_kind].present?
    end

    permission_base = PermissionBase.find_by(:link=> "/#{permission_base_link}", :link_param=> link_param )
    return (permission_base.present? ? permission_base["#{field}"] : nil)
  end


  def account_name(user_id)
    account = User.find_by(:id=> user_id)
    if account.present?
      result = account.first_name 
    else
      result = nil
    end
    return result
  end

  def row_tooltip(record)
    case record.status
    when 'new','active'
      if record.has_attribute?('created_by')
        result = "created by #{account_name(record.created_by)} <p> created at #{record.created_at.strftime("%Y-%m-%d %H:%M:%S")}"
      else
        result = "created at #{record.created_at.strftime("%Y-%m-%d %H:%M:%S")}"
      end
    when 'deleted'
      process_by = (record["#{record.status}_by"].present? ? account_name(record["#{record.status}_by"]) : "User not Found")
      process_at = (record["#{record.status}_at"].present? ? record["#{record.status}_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") : "-")
      result = "#{record.status} by #{process_by} <p> #{record.status} at #{process_at}"
    when 'approved1','canceled1','approved2','canceled2','approved3','canceled3'
      # process_by = (record["#{record.status}_by"].present? ? account_name(record["#{record.status}_by"]) : "User not Found")
      # process_at = (record["#{record.status}_at"].present? ? record["#{record.status}_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") : "-")
      # result = "#{record.status} by #{process_by} <p> #{record.status} at #{process_at}"
      result_status = " Status: #{record.status}"
      result_create = result_app1 = result_app2 = result_app3 = nil
      case controller_name
      when 'outgoing_inspections'
        result_create = " Created by: #{record&.created&.first_name if record&.created.present?} at: #{record["created_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["created_at"].present?}"
        result_app1   = " approved1 by: #{record&.approved1&.first_name if record&.approved1.present?} at: #{record["approved1_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved1_at"].present?}"
      when 'payment_suppliers','production_orders', 'sales_orders', 'purchase_requests', 'purchase_order_suppliers','delivery_orders','picking_slips','sterilization_product_receivings'
        result_create = " Created by: #{record&.created&.first_name if record&.created.present?} at: #{record["created_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["created_at"].present?}"
        result_app1   = " approved1 by: #{record&.approved1&.first_name if record&.approved1.present?} at: #{record["approved1_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved1_at"].present?}"
        result_app2   = " approved2 by: #{record&.approved2&.first_name if record&.approved2.present?} at: #{record["approved2_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved2_at"].present?}"
        result_app3   = " approved3 by: #{record&.approved3&.first_name if record&.approved3.present?} at: #{record["approved3_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved3_at"].present?}"
      else
        result_create = " Created by: #{account_name(record["created_by"])} at: #{record["created_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["created_at"].present?}"
        result_app1   = " approved1 by: #{account_name(record["approved1_by"])} at: #{record["approved1_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved1_at"].present?}"
        result_app2   = " approved2 by: #{account_name(record["approved2_by"])} at: #{record["approved2_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved2_at"].present?}"
        result_app3   = " approved3 by: #{account_name(record["approved3_by"])} at: #{record["approved3_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") if record["approved3_at"].present?}"
      end
      result = "#{result_status} <br> #{result_create} <br> #{result_app1} <br> #{result_app2} <br> #{result_app3}"
    end

    return result
  end
  def form_tooltip(record)
    case record.status
    when 'new','active'
      result = "created by #{account_name(record.created_by)} at #{record.created_at.strftime("%Y-%m-%d %H:%M:%S")}"
    when 'approved1','canceled1','approved2','canceled2','approved3','canceled3','deleted'
      process_by = (record["#{record.status}_by"].present? ? account_name(record["#{record.status}_by"]) : "User not Found")
      process_at = (record["#{record.status}_at"].present? ? record["#{record.status}_at"].to_datetime.strftime("%Y-%m-%d %H:%M:%S") : "-")
      result = "status <i><b>#{record.status}</b></i> by <b>#{process_by}</b> at #{process_at}"
    end

    return result.html_safe
  end


  # aden - 20160304 - angka -> kalimat
    def number_to_words(num)
      arr_terbilang = ["", "satu","dua", "tiga", "empat", "lima", "enam", "tujuh", "delapan", "sembilan", "sepuluh", "sebelas"]
      num = num.to_i
      
      if num < 12
        result = "#{arr_terbilang[num]}"
      elsif num < 20
        result = "#{number_to_words(num - 10)} belas"
      elsif num < 100
        result = "#{number_to_words(num/10)} puluh #{number_to_words(num % 10)}" 
      elsif num < 200
        result = "seratus #{number_to_words(num- 100)}"
      elsif num < 1000
        result = "#{number_to_words(num/100)} ratus #{number_to_words(num % 100)}"
      elsif num < 2000
        result = "seribu #{number_to_words(num - 1000)}"
      elsif num < 1000000
        result = "#{number_to_words(num/1000)} ribu #{number_to_words(num % 1000)}"
      elsif num < 1000000000
        result = "#{number_to_words(num/1000000)} juta #{number_to_words(num % 1000000)}"
      elsif num < 1000000000000
        result = "#{number_to_words(num/1000000000)} miliar #{number_to_words(num % 1000000000)}"
      end 
    end
    
    def subhundred(number)
      ones = %w{zero one two three four five six seven eight nine
            ten eleven twelve thirteen fourteen fifteen
            sixteen seventeen eighteen nineteen}
      tens = %w{zero ten twenty thirty fourty fifty sixty seventy eighty ninety}

      subhundred = number % 100
      return [ones[subhundred]] if subhundred < 20
      return [tens[subhundred / 10], ones[subhundred % 10]]
    end

    def subthousand(number)
      hundreds = (number % 1000) / 100
      tens = number % 100
      s = []
      s = subhundred(hundreds) + ["hundred"] unless hundreds == 0
      s = s + [""] if hundreds == 0 or tens == 0
      s = s + [subhundred(tens)] unless tens == 0
      s
    end

    def decimals(number)
      return [] unless number.to_s['.']
      number = number.to_s.split('.')[1]  
      puts "num ---> #{number}"
      digits = number_to_word_eng(number.to_i) if number.to_i > 0
      digits.present? ? ["dollar and"] +  [digits] + ["cents"] : ["dollar"]  
    end

    def number_to_word_eng(number)
      steps = [""] + %w{thousand million billion trillion quadrillion quintillion sextillion}
      result = []
      n = number.to_i
      steps.each do |step|
        x = n % 1000
        unit = (step == "") ? [] : [step]
        result = subthousand(x) + unit  + result unless x == 0
        n = n / 1000
      end
      result = ["zero"] if result.empty?
      result = result+ decimals(number)

      result.join(' ').gsub('zero','').strip
    end


  def aql_value(actual_qty)
    case actual_qty
    when 2..8
      result = 2
    when 9..15
      result = 3
    when 16..25
      result = 5
    when 26..50
      result = 8
    when 51..90
      result = 13
    when 91..150
      result = 20
    when 151..280
      result = 32
    when 281..500
      result = 50
    when 501..1200
      result = 80
    when 1201..3200
      result = 125
    when 3201..10000
      result = 200
    when 10001..35000
      result = 315
    when 35001..150000
      result = 500
    when 150001..500000
      result = 800
    when 500001..9999999
      result = 1250
    else
      result = 0          
    end 
    return result
  end

end