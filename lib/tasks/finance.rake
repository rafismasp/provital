namespace :finance do
  desc "Rake file 2020-06-20" 

  task :update_pi => :environment do |t, args|
    ProformaInvoiceCustomer.where(:number=> 'PI-22K013').includes(:tax).each do |record|
      ppn_total = record.tax.value.to_f

      total = 0
      discount = 0
      dp_percent = record.down_payment.to_f
      record.proforma_invoice_customer_items.each do |item|
        if item.status == 'active'
          amount = item.sales_order_item.unit_price.to_f * item.sales_order_item.quantity.to_f
          total += amount
          discount += item.amountdisc
          puts "[#{item.id}] amount: #{item.amount} => #{amount} [#{amount == item.amount}]"
          item.update_columns({:amount=> amount})
        end

      end
      total_dp = total.to_f * (dp_percent /100)
      amount   = 0

      if dp_percent.to_i == 0
        discount_total = discount
        amount = grand_total
      else
        discount_total = discount * (dp_percent / 100)
        amount = total_dp
      end
      
      # PPN
      total_ppn = (amount - discount_total) * ppn_total ;
      # Grand Total
      total_gt = (amount - discount_total + total_ppn);

      puts "#{record.id} #{record.number}"
      puts "=== total   : #{record.total} => #{total} [#{total == record.total}]"
      puts "=== total DP: #{record.down_payment_total} => #{total_dp} [#{total_dp == record.down_payment_total}]"
      puts "=== Ttl.DIsc: #{record.discount_total} => #{discount_total} [#{discount_total == record.discount_total}]"
      puts "=== TotalPPN: #{record.ppn_total} => #{total_ppn} [#{total_ppn == record.ppn_total}]"
      puts "=== GrandTtl: #{record.grand_total} => #{total_gt} [#{total_gt == record.grand_total}]"
      record.update_columns({
        :total => total,
        :down_payment_total=> total_dp,
        :discount_total=> discount_total,
        :ppn_total=> total_ppn,
        :grand_total=> total_gt
      })
    end
  end

  task :update_voucher_number => :environment do |t, args|
    VoucherPayment.where(:company_profile_id=> 1, :status=> 'approved3').includes(:voucher_payment_items).order("id asc").each do |vp|
      items = vp.voucher_payment_items.where(:status=> 'active').includes(:routine_cost_payment, :proof_cash_expenditure, :cash_settlement)
      puts "VP: #{vp.number} - #{vp.date} - #{vp.status}"
      items.each do |item|
        if item.routine_cost_payment.present?
          case item.routine_cost_payment.voucher_number
          when '', nil
            puts "#{item.routine_cost_payment.number} voucher_number is blank!"
            item.routine_cost_payment.update_columns(:voucher_number=> vp.number)
          end
        end

        if item.proof_cash_expenditure.present?
          case item.proof_cash_expenditure.voucher_number
          when '', nil
            puts "#{item.proof_cash_expenditure.number} voucher_number is blank!"
            item.proof_cash_expenditure.update_columns(:voucher_number=> vp.number)
          end
        end

        if item.cash_settlement.present?
          case item.cash_settlement.voucher_number
          when '', nil
            puts "#{item.cash_settlement.number} voucher_number is blank!"
            item.cash_settlement.update_columns(:voucher_number=> vp.number)
          end
        end
      end
      puts "------------------------------------------------------"
    end
  end


  task :check_invoice_after_update_ppn11 => :environment do |t, args|
    periode_begin = '2022-04-01 00:00:00'
    periode_end   = '2022-12-31 23:59:59'

    InvoiceCustomer.where(:updated_at=> periode_begin .. periode_end).includes(:customer).order("date asc").each do |inv|
      puts "#{inv.number}"
      tax_value = inv.tax.value

      if inv.date.to_date.strftime("%Y-%m-%d") < '2022-04-01'
        if tax_value == 0.11
          tax_value = 0.10

          new_ppntotal   = inv.subtotal.to_f * tax_value
          new_grandtotal = ( (inv.subtotal.to_f - inv.discount.to_f ) - new_ppntotal.to_f)
          puts " --> #{inv.ppntotal} => #{new_ppntotal}"
        end
      end
    end

  end

  task :updated_ppn11 => :environment do |t, args|
    puts "Current: #{DateTime.now().strftime("%Y-%m-%d")}"
    puts "upadte PPN 10% to 11%"

    account_mail = ['aden.pribadi@gmail.com']
    subject_mail = "[SIP] - Change PPN - Provital"
    note_mail    = "Mulai 1 April 2022, PPN berubah jadi 11%"
    content_mail = "Master Customer: #{note_mail} <br />"

    puts content_mail
    customer_id  = []
    Customer.where(:tax_id=> 2, :status=> 'active').order("name asc").each do |customer|
      content_mail += "
        [#{customer.id}] #{customer.name}, #{customer.tax.value if customer.tax.present?}% => 11% <br />
      "
      if DateTime.now().strftime("%Y-%m-%d") == '2022-04-01'
        puts "[#{customer.id}] #{customer.name} "
        puts "update to ppn11%"
        customer_id << customer.id
        customer.update_columns({:tax_id=> 5, :updated_at=> DateTime.now(), :updated_by=> 1, :remarks=> "#{note_mail}"})
      end
    end
    content_mail += "customer_id: #{customer_id}"

    if customer_id.present?
      UserMailer.tiki(account_mail, subject_mail, content_mail.html_safe, nil).deliver!
    end

    content_mail = "Master Supplier: #{note_mail} <br />"

    puts content_mail
    supplier_id  = []
    Supplier.where(:tax_id=> 2, :status=> 'active').order("name asc").each do |supplier|
      content_mail += "
        [#{supplier.id}] #{supplier.name}, #{supplier.tax.value if supplier.tax.present?}% => 11% <br />
      "
      if DateTime.now().strftime("%Y-%m-%d") == '2022-04-01'
        puts "[#{supplier.id}] #{supplier.name} "
        puts "update to ppn11%"
        supplier_id << supplier.id
        supplier.update_columns({:tax_id=> 5, :updated_at=> DateTime.now(), :updated_by=> 1, :remarks=> "#{note_mail}"})
      end
    end
    content_mail += "supplier_id: #{supplier_id}"

    if supplier_id.present?
      UserMailer.tiki(account_mail, subject_mail, content_mail.html_safe, nil).deliver!
    end

    content_mail = "Invoice Customer: #{note_mail} <br />"
    periode_begin = DateTime.now().strftime("%Y-%m-%d")
    # periode_begin = "2022-03-01"
    periode_end = periode_begin.to_date.at_end_of_month.strftime("%Y-%m-%d")
    puts content_mail
    invoice_id  = []

    InvoiceCustomer.where(:date=> periode_begin .. periode_end, :status=> 'approved3').includes(:customer).order("date asc").each do |inv|
      customer = inv.customer
      if customer.present?
        top_day = customer.top_day.to_i
        term_of_payment_id = customer.term_of_payment_id
        tax = (sales_order.present? ? sales_order.tax : customer.tax)
        tax_id = tax.id
        cus_ppn = tax.value
      
        if inv.date.to_date.strftime("%Y-%m-%d") >= '2022-04-01'
          puts "[#{inv.id}] - #{inv.number} - #{inv.date} - PPN#{cus_ppn}% => #{inv.ppntotal}"
          sum_ppn = sum_grandtotal = 0
          inv.fin_customer_invoice_items.where(:status=> 'active').each do |inv_item|
            new_ppn = (inv_item.total_price * cus_ppn)
            new_grandtotal = inv_item.total_price + new_ppn

            sum_ppn += new_ppn
            sum_grandtotal += new_grandtotal
          end

          inv.update_columns({
            :ppntotal=> sum_ppn,
            :grand_total=> sum_grandtotal,
            :updated_at=> DateTime.now(), :updated_by=> 1
          })
          puts "[#{inv.id}] - #{inv.number} - #{inv.date} - PPN#{cus_ppn}% => #{inv.ppntotal}"
          puts "   ppn_total: #{inv.ppntotal} => #{sum_ppn}"
          puts "   grand_total: #{inv.grand_total} => #{sum_grandtotal}"
          invoice_id << inv.id
        end

        content_mail += "
          [#{inv.id}] - #{inv.number} - #{inv.date} - PPN#{cus_ppn}% => #{inv.ppntotal} <br />
        "
      end
    end
    content_mail += "invoice_id: #{invoice_id}"
    if invoice_id.present?
      UserMailer.tiki(account_mail, subject_mail, content_mail.html_safe, nil).deliver!
    end


    # content_mail = "Jenis Pajak: #{note_mail} <br />"
    # tidak di suspend karena masih ada yg pake PPN 10%
    # puts content_mail
    # if DateTime.now().strftime("%Y-%m-%d") == '2022-04-01'
    #   tax10 = Tax.find_by(:name=> 'PPN 10%')
    #   if tax10.present?
    #     tax10.update_columns({:status=> 'suspend', :updated_at=> DateTime.now()})
    #     puts "PPN 10 suspend!"
    #   end

    #   tax11 = Tax.find_by(:name=> 'PPN 11%')
    #   if tax11.blank?
    #     tax11 = Tax.new({
    #       :name=> 'PPN 11%',
    #       :value=> 0.11,
    #       :status=> 'active',
    #       :created_at=> DateTime.now(),
    #       :created_by=> 1
    #     })
    #     tax11.save!
    #     puts "PPN 11 Created!"
    #   end
    # end
    
  end

  task :cost_projects => :environment do |t, args|
    # begin_date = '2021-01-01'
    # end_date   = '2022-07-30'
    begin_date = (DateTime.now().at_beginning_of_month()-1.month).strftime("%Y-%m-%d") 
    puts begin_date 
    end_date   = begin_date.to_date.at_end_of_month().strftime("%Y-%m-%d")
    records = SalesOrder.where(:company_profile_id=> 1, :date => begin_date .. end_date)
          .includes(:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3, customer:[:currency])
          .includes(sales_order_items:[ 
            production_order_items: [
              production_order_used_prves: [
                purchase_request_item: [
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
                    ], purchase_order_supplier: [:currency, :purchase_order_supplier_items]]]]]])#.where(:sales_orders=> {:number=> ['PP/PIF/14/X/2021']})

    count_so = 0
    records.each do |record|
      so_currency = "#{record.customer.currency.name if record.customer.present? and record.customer.currency.present?}"
      po_currency = ""
      
      count_so += 1
      so_amount = summary_po_amount = summary_grn_amount = 0
      cost_project = 0
      prf_item_group = []

      puts "------------------ prf_item_group start"
      record.sales_order_items.each do |so_item|
        so_amount += so_item.quantity*so_item.unit_price
        so_item.production_order_items.each do |spp_item|
          prf_item_group+= spp_item.production_order_used_prves.group(:purchase_request_item_id).map { |e| e.purchase_request_item_id }
        end
      end
      puts "------------------ prf_item_group end"
      # pdf.text "#{prf_item_group.uniq.as_json}"

      cost_project_finance = CostProjectFinance.find_by(:company_profile_id=> record.company_profile_id, :sales_order_id=> record.id)
      if cost_project_finance.present?
        if cost_project_finance.status == 'approved3'
          # ga bisa diedit
        else
          # bisa diedit
        end
      else
        cost_project_finance = CostProjectFinance.new({
          :company_profile_id=> record.company_profile_id, 
          :sales_order_id=> record.id,
          :customer_id=> record.customer_id,
          :date=> record.date,
          :amount_so=> 0, :amount_po=> 0, :amount_grn=> 0,
          :remarks=> '',
          :status=> 'new',
          :created_at=> record.created_at, 
          :created_by=> record.created_by
        })
        cost_project_finance.save
      end
      
      c = 0
      c_prf = 0

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
        puts "------------------ purchase_request_item_id #{spp_used.purchase_request_item_id} start"
        # pdf.text "  production_order_item_id: #{spp_used.production_order_item_id}; purchase_request_item_id: #{spp_used.purchase_request_item_id}; "
        sum_spp_quantity = 0
        sum_po_quantity = 0
        sum_grn_quantity = 0
        prf_quantity = spp_used.purchase_request_item.quantity
        if prf_quantity > 0
          prf_header = spp_used.purchase_request_item.purchase_request 
          pdm = Pdm.find_by(:purchase_request_id=> prf_header.id)
          pdm_item = nil

          if spp_used.purchase_request_item.product.present? 
            part = spp_used.purchase_request_item.product 
          elsif spp_used.purchase_request_item.material.present? 
            part = spp_used.purchase_request_item.material 
            pdm_item = PdmItem.find_by(:pdm_id=> pdm.id, :material_id=> spp_used.purchase_request_item.material_id) if pdm.present?
          elsif spp_used.purchase_request_item.consumable.present? 
            part = spp_used.purchase_request_item.consumable 
          elsif spp_used.purchase_request_item.equipment.present? 
            part = spp_used.purchase_request_item.equipment 
          elsif spp_used.purchase_request_item.general.present? 
            part = spp_used.purchase_request_item.general 
          end
          unit_name = (part.present? ? part.unit_name : nil)
          # if pdf.y.round(1) < 110
          #   pdf.start_new_page
          # end

          cost_project_finance_prf_item = CostProjectFinancePrfItem.find_by(
            :cost_project_finance_id=> cost_project_finance.id, 
            :purchase_request_id=> prf_header.id,
            :purchase_request_item_id=> spp_used.purchase_request_item_id)

          if cost_project_finance_prf_item.present?
            cost_project_finance_prf_item.update_columns({
              :pdm_id=> pdm.id,
              :pdm_item_id=> pdm_item.present? ? pdm_item.id : nil
            }) if pdm.present? and pdm_item.present?
          else
            cost_project_finance_prf_item = CostProjectFinancePrfItem.new(
              :cost_project_finance_id=> cost_project_finance.id, 
              :purchase_request_id=> prf_header.id,
              :purchase_request_item_id=> spp_used.purchase_request_item_id,
              :pdm_id=> pdm.present? ? pdm.id : nil,
              :pdm_item_id=> pdm_item.present? ? pdm_item.id : nil,
              :quantity=> prf_quantity,
              :status=> 'active',
              :created_at=> spp_used.purchase_request_item.created_at, 
              :created_by=> spp_used.purchase_request_item.created_by
            )
            cost_project_finance_prf_item.save
          end

          po_amount  = 0
          grn_amount = 0

          c_po = 0
          if spp_used.purchase_request_item.purchase_order_supplier_items.present?
            
            # PRF
            spp_used.purchase_request_item.purchase_order_supplier_items.each do |po_item|
              puts "------------------ purchase_order_supplier_item_id #{po_item.id} start"
              # po_currency = "#{po_item.purchase_order_supplier.currency.name if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
              cost_project_finance_po_item = CostProjectFinancePoItem.find_by(
                  :cost_project_finance_id=> cost_project_finance.id, 
                  :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                  :purchase_order_supplier_id=> po_item.purchase_order_supplier_id, 
                  :purchase_order_supplier_item_id=> po_item.id
                )
              if cost_project_finance_po_item.present?
              else
               cost_project_finance_po_item = CostProjectFinancePoItem.new(
                  :cost_project_finance_id=> cost_project_finance.id, 
                  :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                  :purchase_order_supplier_id=> po_item.purchase_order_supplier_id, 
                  :purchase_order_supplier_item_id=> po_item.id,
                  :quantity=> po_item.quantity,
                  :unit_price=> po_item.unit_price,
                  :status=> 'active',
                  :created_at=> po_item.created_at, 
                  :created_by=> po_item.created_by
                )
               cost_project_finance_po_item.save
              end
             
              sum_po_quantity += po_item.quantity
              po_amount += po_item.unit_price*po_item.quantity

              c_grn = 0
              
              if po_item.material_receiving_items.present?
                po_item.material_receiving_items.each do |grn_item|
                  cost_project_finance_grn_item = CostProjectFinanceGrnItem.find_by(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :material_receiving_item_id=> grn_item.id
                    )
                  if cost_project_finance_grn_item.present?
                    cost_project_finance_grn_item.update({
                      :status=> 'active'
                    })
                  else
                    cost_project_finance_grn_item = CostProjectFinanceGrnItem.new(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :material_receiving_id=> grn_item.material_receiving_id,
                      :material_receiving_item_id=> grn_item.id,
                      :quantity=> grn_item.quantity,
                      :status=> 'active',
                      :created_at=> grn_item.created_at, 
                      :created_by=> grn_item.created_by
                    )
                    cost_project_finance_grn_item.save
                  end

                  sum_grn_quantity += grn_item.quantity
                  grn_amount += grn_item.quantity*po_item.unit_price
                end
              end
              if po_item.product_receiving_items.present?
                po_item.product_receiving_items.each do |grn_item|
                  cost_project_finance_grn_item = CostProjectFinanceGrnItem.find_by(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :product_receiving_item_id=> grn_item.id
                    )
                  if cost_project_finance_grn_item.present?
                    cost_project_finance_grn_item.update({
                      :status=> 'active'
                    })
                  else
                    cost_project_finance_grn_item = CostProjectFinanceGrnItem.new(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :product_receiving_id=> grn_item.product_receiving_id,
                      :product_receiving_item_id=> grn_item.id,
                      :quantity=> grn_item.quantity,
                      :status=> 'active',
                      :created_at=> grn_item.created_at, 
                      :created_by=> grn_item.created_by
                    )
                    cost_project_finance_grn_item.save
                  end

                  sum_grn_quantity += grn_item.quantity
                  grn_amount += grn_item.quantity*po_item.unit_price
                end
              end
              if po_item.consumable_receiving_items.present?
                po_item.consumable_receiving_items.each do |grn_item|
                  cost_project_finance_grn_item = CostProjectFinanceGrnItem.find_by(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :consumable_receiving_item_id=> grn_item.id
                    )
                  if cost_project_finance_grn_item.present?
                    cost_project_finance_grn_item.update({
                      :status=> 'active'
                    })
                  else
                    cost_project_finance_grn_item = CostProjectFinanceGrnItem.new(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :consumable_receiving_id=> grn_item.consumable_receiving_id,
                      :consumable_receiving_item_id=> grn_item.id,
                      :quantity=> grn_item.quantity,
                      :status=> 'active',
                      :created_at=> grn_item.created_at, 
                      :created_by=> grn_item.created_by
                    )
                    cost_project_finance_grn_item.save
                  end

                  sum_grn_quantity += grn_item.quantity
                  grn_amount += grn_item.quantity*po_item.unit_price
                end
              end
              if po_item.equipment_receiving_items.present?
                po_item.equipment_receiving_items.each do |grn_item|
                  cost_project_finance_grn_item = CostProjectFinanceGrnItem.find_by(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :equipment_receiving_item_id=> grn_item.id
                    )
                  if cost_project_finance_grn_item.present?
                    cost_project_finance_grn_item.update({
                      :status=> 'active'
                    })
                  else
                    cost_project_finance_grn_item = CostProjectFinanceGrnItem.new(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :equipment_receiving_id=> grn_item.equipment_receiving_id,
                      :equipment_receiving_item_id=> grn_item.id,
                      :quantity=> grn_item.quantity,
                      :status=> 'active',
                      :created_at=> grn_item.created_at, 
                      :created_by=> grn_item.created_by
                    )
                    cost_project_finance_grn_item.save
                  end

                  sum_grn_quantity += grn_item.quantity
                  grn_amount += grn_item.quantity*po_item.unit_price
                end
              end
              if po_item.general_receiving_items.present?
                po_item.general_receiving_items.each do |grn_item|
                  cost_project_finance_grn_item = CostProjectFinanceGrnItem.find_by(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :general_receiving_item_id=> grn_item.id
                    )
                  if cost_project_finance_grn_item.present?
                    cost_project_finance_grn_item.update({
                      :status=> 'active'
                    })
                  else
                    cost_project_finance_grn_item = CostProjectFinanceGrnItem.new(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :general_receiving_id=> grn_item.general_receiving_id,
                      :general_receiving_item_id=> grn_item.id,
                      :quantity=> grn_item.quantity,
                      :status=> 'active',
                      :created_at=> grn_item.created_at, 
                      :created_by=> grn_item.created_by
                    )
                    cost_project_finance_grn_item.save
                  end

                  sum_grn_quantity += grn_item.quantity
                  grn_amount += grn_item.quantity*po_item.unit_price
                end
              end
              
              puts "------------------ purchase_order_supplier_item_id #{po_item.id} end"
            end

          end

          if pdm_item.present?
            # PDM
            pdm_item.purchase_order_supplier_items.each do |po_item|
              puts "------------------ purchase_order_supplier_item_id #{po_item.id} start"
              # po_currency = "#{po_item.purchase_order_supplier.currency.name if po_item.purchase_order_supplier.present? and po_item.purchase_order_supplier.currency.present?}"
              cost_project_finance_po_item = CostProjectFinancePoItem.find_by(
                  :cost_project_finance_id=> cost_project_finance.id, 
                  :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                  :purchase_order_supplier_id=> po_item.purchase_order_supplier_id, 
                  :purchase_order_supplier_item_id=> po_item.id
                )
              if cost_project_finance_po_item.present?
              else
               cost_project_finance_po_item = CostProjectFinancePoItem.new(
                  :cost_project_finance_id=> cost_project_finance.id, 
                  :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                  :purchase_order_supplier_id=> po_item.purchase_order_supplier_id, 
                  :purchase_order_supplier_item_id=> po_item.id,
                  :quantity=> po_item.quantity,
                  :unit_price=> po_item.unit_price,
                  :status=> 'active',
                  :created_at=> po_item.created_at, 
                  :created_by=> po_item.created_by
                )
               cost_project_finance_po_item.save
              end

              sum_po_quantity += po_item.quantity
              po_amount += po_item.unit_price*po_item.quantity

              c_grn = 0
              if po_item.material_receiving_items.present?
                po_item.material_receiving_items.each do |grn_item|
                  cost_project_finance_grn_item = CostProjectFinanceGrnItem.find_by(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :material_receiving_item_id=> grn_item.id
                    )
                  if cost_project_finance_grn_item.present?
                    cost_project_finance_grn_item.update({
                      :status=> 'active'
                    })
                  else
                    cost_project_finance_grn_item = CostProjectFinanceGrnItem.new(
                      :cost_project_finance_id=> cost_project_finance.id, 
                      :cost_project_finance_prf_item_id=> cost_project_finance_prf_item.id, 
                      :cost_project_finance_po_item_id=> cost_project_finance_po_item.id,
                      :material_receiving_id=> grn_item.material_receiving_id,
                      :material_receiving_item_id=> grn_item.id,
                      :quantity=> grn_item.quantity,
                      :status=> 'active',
                      :created_at=> grn_item.created_at, 
                      :created_by=> grn_item.created_by
                    )
                    cost_project_finance_grn_item.save
                  end

                  sum_grn_quantity += grn_item.quantity
                  grn_amount += grn_item.quantity*po_item.unit_price
                end
              end
            end

          end

          cost_project += grn_amount
          summary_po_amount += po_amount
          summary_grn_amount += grn_amount

          cost_project_finance.update({
            :amount_po=> po_amount,
            :amount_grn=> grn_amount
          })



        end
        puts "------------------ purchase_request_item_id #{spp_used.purchase_request_item_id} end"
      end

      cost_project_finance.update({
        :amount_so=> so_amount,
        :amount_po=> summary_po_amount,
        :amount_grn=> summary_grn_amount
      })
      # if cost_project > 0
        # cost_project = (so_amount - summary_grn_amount)
        # pdf.table([
        #   [
        #     {:content=> "Customer", :width=> 80, :font_style=> :bold}, {:content=> ":", :width=> 10},
        #     {:content=> "#{record.customer.name if record.customer.name}", :width=> 180, :colspan=> 9}
            
        #   ], [
        #     {:content=> "SO Number", :font_style=> :bold}, {:content=> ":"},
        #     {:content=> record.number, :width=> 100}, {:content=> " ", :width=> 30},
        #     {:content=> "Project Name", :width=> 80, :font_style=> :bold}, {:content=> ":"},
        #     {:content=> record.remarks, :colspan=> 5, :width=> 250}
        #   ], [
        #     {:content=> "Tgl. Number", :font_style=> :bold}, {:content=> ":"},
        #     {:content=> "#{record.date}"}
        #   ] 
        # ], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})

        # pdf.move_down 20
        # pdf.table([
        #   [
        #     {:content=> "SO Amount", :font_style=> :bold}, {:content=> ":"},
        #     {:content=> "#{so_currency} #{number_with_precision(so_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right}
        #   ], [
        #     {:content=> "PO Amount", :font_style=> :bold}, {:content=> ":"},
        #     {:content=> "#{po_currency} #{number_with_precision(summary_po_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
        #   ], [
        #     {:content=> "GRN Amount", :font_style=> :bold}, {:content=> ":"},
        #     {:content=> "#{po_currency} #{number_with_precision(summary_grn_amount, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
        #   ], [
        #     {:content=> "Cost Project", :font_style=> :bold}, {:content=> ":"},
        #     {:content=> "#{po_currency} #{number_with_precision(cost_project, precision: 2, delimiter: ".", separator: ",")}", :align=> :right},
        #   ] 
        # ], :column_widths=> [80, 10, 140], :cell_style => {:border_width => 0, :padding=> [3,2, 2, 3]})
        # pdf.move_down 20

        # pdf.text "note: *Cost Project = SO Amount - GRN Amount"
        # pdf.start_new_page
      # else
      #   pdf.text ""
      # end
      puts "------------------#{record.number}"
    end
  end

  task :tax_check => :environment  do |t, args|  
    ActiveRecord::Base.establish_connection :development

    InvoiceCustomer.where(:number=> '21A001').each do |invoice|
    	puts "Number: #{invoice.number}"
    	puts "Subtotal: #{invoice.subtotal}"
    	puts "Discount: #{invoice.discount}"
    	puts "PPN: #{invoice.ppntotal}"
    	puts "Grand Total: #{invoice.grandtotal}"
    	subtotal = 0
    	ppntotal = 0
    	discount = invoice.discount
    	top_day = invoice.customer.top_day.to_i
    	term_of_payment_id = invoice.customer.term_of_payment_id
    	puts "top: #{top_day} #{term_of_payment_id}"
    	InvoiceCustomerItem.where(:invoice_customer_id=> invoice.id, :status=> 'active').each do |item|
    		# puts "  SO Number: #{item.sales_order_item.sales_order.number}"
    		# puts "  Product: #{item.product.name}"
    		# puts "  Qty: #{item.quantity}"
    		# puts "  Unit Price: #{item.unit_price}"
        item.update_columns({
          :total_price=> (item.quantity.to_f* item.unit_price.to_f)
        })

    		subtotal += item.total_price
    		
    		if item.sales_order_item.sales_order.present? 
    			top_day = item.sales_order_item.sales_order.top_day.to_i
    			term_of_payment_id = item.sales_order_item.sales_order.term_of_payment_id

    			puts "top by so: #{top_day} #{term_of_payment_id}"
	    		if item.sales_order_item.sales_order.tax.present?
	    			puts "  #{item.sales_order_item.sales_order.tax.name}"
		    		ppntotal += (item.total_price.to_f * 0.10) if item.sales_order_item.sales_order.tax.name == 'PPN 10%' 
		    	end
	    	end
    	end



    	grandtotal = ((subtotal-discount)+ppntotal)
    	if subtotal != invoice.subtotal
    		puts "!! subtotal tidak sesuai !!"
    	end

    	if ppntotal != invoice.ppntotal
    		puts "!! ppntotal tidak sesuai !! seharusnya: #{ppntotal}"
    	end
    	if grandtotal != invoice.grandtotal
    		puts "!! grandtotal tidak sesuai !! seharusnya: #{grandtotal}"
    	end

    	# if subtotal != invoice.subtotal or ppntotal != invoice.ppntotal or grandtotal != invoice.grandtotal
	    	invoice.update_columns({
	    		:subtotal=> subtotal, 
	    		:ppntotal=> ppntotal,
	    		:grandtotal=> grandtotal,
	    		:top_day=> top_day, :term_of_payment_id=> term_of_payment_id
	    	})
	    # end


    	puts "-------------------------------------"

    end
  end

  task :invoice_receipt => :environment do

    include ApplicationHelper
    InvoiceSupplierReceivingItem.where(:status=> 'active').each do |item|
      invoice_item = InvoiceSupplierReceivingItem.find_by(:id=> item["id"])
      if invoice_item.present?
        case item["status"]
        when 'deleted'
          invoice_item.update_columns({
            :status=> item["status"],
            :deleted_at=> DateTime.now(), :deleted_by=> 1
          })
        else

          invoice_supplier_receiving = item.invoice_supplier_receiving
          company_profile_id = invoice_supplier_receiving.company_profile_id

          supplier_id = invoice_supplier_receiving.supplier_id
          supplier_tax_invoice = SupplierTaxInvoice.find_by(:company_profile_id=> company_profile_id, :supplier_id=> supplier_id, :number=> item["fp_number"])

          invoice_item.update_columns({
            :erp_system=> (item["erp_system"].present? ? 1 : nil),
            :supplier_tax_invoice_id=> (supplier_tax_invoice.present? ? supplier_tax_invoice.id : nil),
            :currency_id=> item["currency_id"],
            :tax_rate_id=> item["tax_rate_id"],
            :invoice_number=> item["invoice_number"],
            :invoice_date=> item["invoice_date"],
            :fp_number=> item["fp_number"],
            :dpp=> item["dpp"],
            :ppn=> item["ppn"],
            :total=> item["total"],
            :remarks=> item["remarks"],
            :updated_at=> DateTime.now(), :updated_by=> 1
          })
          amount_payment = 0
          create_supplier_ap_recap(item["invoice_date"].to_date.strftime("%Y%m"), invoice_supplier_receiving.supplier, amount_payment, item, (supplier_tax_invoice.present? ? supplier_tax_invoice.id : nil), invoice_item.id)
    
        end
      end
    end
  end

end