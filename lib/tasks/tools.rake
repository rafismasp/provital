namespace :tools do

  task :new_batch_number => :environment do |t, args|
    list_bn = ['B084-20L02', 'B085-20L02', 'B085-20L01', 'B118-20D02', 'B119-20F01', 'B120-20D02', 'B126-20D02', 'B138-20E01', 'B151-21C02', 'B190-20H01', 'B192-20J01', 'B193-20K01', 'B195-21G01', 'B195-21G03', 'B195-21G04', 'B219-20J01', 'B289-21E01', 'B297-21E01', 'B342-21L01', 'B350-21M01', 'A023-18J01', 'A044-20C01', 'A045-20C01', 'A048-20C01', 'A055-20D01', 'A058-20H01', 'A069-20E03', 'A070-20K04', 'A086-20F01']
    list_bn.each do |bn|
      part_id = bn.to_s[0,4]

      material = Material.find_by(:part_id=> part_id)
      if material.present?
        record = MaterialBatchNumber.find_by(:number=> bn)
        if record.present?
          puts "  [#{material.id}] #{record.id} => #{record.number} exists"
          inventory_batch_numbers = InventoryBatchNumber.where(:material_batch_number_id=> record.id)
          if inventory_batch_numbers.present?
            # inventory_batch_numbers.each do |inv_bn|
            #   puts "[#{inv_bn.periode}] #{inv_bn.end_stock}"
            # end
          else
            puts "tidak ada stock"
            inventory_batch_number = InventoryBatchNumber.new({
              :company_profile_id=> 1,
              :material_id=> material.id,
              :material_batch_number_id=> record.id,
              :periode=> '202212',
              :begin_stock=> 0, :trans_in=> 0, :trans_out=> 0, :end_stock=> 0,
              :created_at=> DateTime.now(),
              :updated_at=> DateTime.now()
            })
            inventory_batch_number.save
          end
        else

          case bn.to_s[7,1]
          when 'A'
            periode_mm = '01'
          when 'B'
            periode_mm = '02'
          when 'C'
            periode_mm = '03'
          when 'D'
            periode_mm = '04'
          when 'E'
            periode_mm = '05'
          when 'F'
            periode_mm = '06'
          when 'G'
            periode_mm = '07'
          when 'H'
            periode_mm = '08'
          when 'J'
            periode_mm = '09'
          when 'K'
            periode_mm = '10'
          when 'L'
            periode_mm = '11'
          when 'M'
            periode_mm = '12'
        end

          puts "  [#{material.id}] #{bn} not exists"
          rcv_item = MaterialReceivingItem.find_by(:material_receiving_id=> 958, :material_id=> material.id)
          if rcv_item.blank?
            puts "rcv item blank"
            rcv_item = MaterialReceivingItem.new({
              :material_receiving_id=> 958, 
              :material_id=> material.id,
              :quantity=> 0, 
              :remarks=> '-',
              :status=> 'active',
              :created_by=> 1, :created_at=> DateTime.now()
            })
            rcv_item.save
            record = MaterialBatchNumber.new({
              :company_profile_id=> 1,
              :material_receiving_id=> rcv_item.material_receiving_id,
              :material_receiving_item_id=> rcv_item.id,
              :material_id=> material.id,
              :number=> bn,
              :periode_yyyy=> "20#{bn.to_s[5,2]}",
              :periode_mm=> periode_mm,
              :status=> 'active',
              :created_at=> DateTime.now(),
              :updated_at=> DateTime.now()
            })
            record.save
            
            inventory_batch_number = InventoryBatchNumber.new({
              :company_profile_id=> 1,
              :material_id=> material.id,
              :material_batch_number_id=> record.id,
              :periode=> '202212',
              :begin_stock=> 0, :trans_in=> 0, :trans_out=> 0, :end_stock=> 0,
              :created_at=> DateTime.now(),
              :updated_at=> DateTime.now()
            })
            inventory_batch_number.save
          end
        end
      else
        puts "#{part_id} not exists!"

      end
    end
  end

  task :check_stock, [:kind] => :environment do |t, args|
    case args[:kind]
    when 'P'
      records = Product.where(:company_profile_id=> 1, :part_id=> 'AACP')
      all_count = records.count(:id)
      c=1
      records.each do |product|
        ['202001','202002','202003','202004','202005','202006','202007','202008','202009','202010','202011','202012',
          '202101','202102','202103','202104','202105','202106','202107','202108','202109','202110','202111','202112','202201','202202','202203','202204','202205','202206','202207','202208','202209','202210','202211','202212'].each do |period|
          puts "[#{period}] (#{c}/#{all_count})"
          Rake::Task["tools:update_stock_products"].reenable
          Rake::Task["tools:update_stock_products"].invoke(period, product)
        end
        product.update_columns(:remarks_system=> 'update_stocks')
        c+=1
      end
    when 'M'
      list_part = ['B039','B053','B068','B161','B162','B167','B173','B177','B178','B183','A090','B229','A119','A122','A131','A132','A133','B267','B270','B273','A134','B295','A139','B323','A147','B339','A158','B345','A162','B375','B376','B401','B433','B445','A084','B094','B110','B198','A123','A166']
      # A090
      records = Material.where(:company_profile_id=> 1, :part_id=> 'B356', :remarks_system=> nil)
      all_count = records.count(:id)
      c=1
      records.each do |material|
        ['202101','202102','202103','202104','202105','202106','202107','202108','202109','202110','202111','202112','202201','202202','202203','202204','202205','202206','202207','202208','202209','202210','202211','202212'].each do |period|
          puts "#{material.part_id} [#{period}] (#{c}/#{all_count})"
          Rake::Task["tools:update_stocks"].reenable
          Rake::Task["tools:update_stocks"].invoke(period, material)
        end
        material.update_columns(:remarks_system=> 'update_stocks')
        c+=1
      end
    end
  end

  task :update_stock_products, [:periode, :product_id] => :environment do |t, args|
    # product only
    company_profile_id = 1
    records = Inventory.where(:periode=> args[:periode], :product_id=> args[:product_id]).includes(:product)
    period_begin = "#{args[:periode]}01".to_date.at_beginning_of_month()
    period_end = "#{args[:periode]}01".to_date.at_end_of_month()
    records.each do |inventory|
      puts "#{inventory.periode};[#{inventory.product.part_id}] Stok Awal: #{inventory.begin_stock}; Trans In: #{inventory.trans_in}; Trans Out: #{inventory.trans_out}; End of Stock: #{inventory.end_stock}"


      FinishGoodReceivingItem.where(:status=> 'active', :product_id=> inventory.product_id).includes(:finish_good_receiving).where(:finish_good_receivings=> {:company_profile_id=> company_profile_id, :date=> period_begin .. period_end, :status=> 'approved3'}).each do |item|
        inventory_log = InventoryLog.find_by(:company_profile_id=> company_profile_id, :inventory_id=> inventory.id, :periode=> inventory.periode, :finish_good_receiving_item_id=> item.id)
        if inventory_log.present?
        else
          inventory_log = InventoryLog.new({
            :company_profile_id=> company_profile_id, 
            :inventory_id=> inventory.id, 
            :periode=> inventory.periode, 
            :finish_good_receiving_item_id=> item.id,
            :quantity=> item.quantity,
            :kind=> 'in',
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> item.created_by
          })
          inventory_log.save
        end
      end


      DeliveryOrderItem.where(:status=> 'active', :product_id=> inventory.product_id).includes(:delivery_order).where(:delivery_orders=> {:company_profile_id=> company_profile_id, :date=> period_begin .. period_end, :status=> 'approved3'}).each do |item|
        inventory_log = InventoryLog.find_by(:company_profile_id=> company_profile_id, :inventory_id=> inventory.id, :periode=> inventory.periode, :delivery_order_item_id=> item.id)
        if inventory_log.present?
        else
          inventory_log = InventoryLog.new({
            :company_profile_id=> company_profile_id, 
            :inventory_id=> inventory.id, 
            :periode=> inventory.periode, 
            :delivery_order_item_id=> item.id,
            :quantity=> item.quantity,
            :kind=> 'out',
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> item.created_by
          })
          inventory_log.save
        end
      end

      sum_trans_in = 0
      sum_trans_out = 0
      arry = {}
      InventoryLog.where(:inventory_id=> inventory.id).includes(inventory_adjustment_item: [:inventory_adjustment, :product_batch_number]).each do |log|
        stock_process = true
        if log.sterilization_product_receiving_item.present?
          stock_process = false
        elsif log.semi_finish_good_receiving_item.present?
          stock_process = false
        elsif log.semi_finish_good_outgoing_item.present?
          stock_process = false
        end
            
        if stock_process == true
          product_batch_number_id = nil

          if log.sterilization_product_receiving_item.present?
            product_batch_number_id = log.sterilization_product_receiving_item.product_batch_number_id
          elsif log.inventory_adjustment_item.present?
            product_batch_number_id = log.inventory_adjustment_item.product_batch_number_id
          elsif log.material_outgoing_item.present?
            product_batch_number_id = log.material_outgoing_item.product_batch_number_id
          elsif log.material_receiving_item.present?
            product_batch_number_id = log.material_receiving_item.product_batch_number_id
          elsif log.semi_finish_good_outgoing_item.present?
            product_batch_number_id = log.semi_finish_good_outgoing_item.product_batch_number_id
          elsif log.semi_finish_good_receiving_item.present?
            product_batch_number_id = log.semi_finish_good_receiving_item.product_batch_number_id
          elsif log.finish_good_receiving_item.present?
            product_batch_number_id = log.finish_good_receiving_item.product_batch_number_id
          elsif log.internal_transfer_item.present?
            product_batch_number_id = log.internal_transfer_item.product_batch_number_id
          elsif log.delivery_order_item.present?
            product_batch_number_id = log.delivery_order_item.product_batch_number_id
          end

          puts "   log --- #{log.status} => #{log.kind} #{log.quantity};  product_batch_number_id: #{product_batch_number_id}"
          if log.status =='active'
            if log.kind == 'in'
              sum_trans_in += log.quantity
              arry["#{product_batch_number_id}"] ||= {}
              if arry["#{product_batch_number_id}"]["trans_in"].present?
                arry["#{product_batch_number_id}"]["trans_in"] += log.quantity.to_f
              else
                arry["#{product_batch_number_id}"]["trans_in"] = log.quantity.to_f
              end
            end
            if log.kind == 'out'
              sum_trans_out += log.quantity
              arry["#{product_batch_number_id}"] ||= {}
              if arry["#{product_batch_number_id}"]["trans_out"].present?
                arry["#{product_batch_number_id}"]["trans_out"] += log.quantity.to_f
              else
                arry["#{product_batch_number_id}"]["trans_out"] = log.quantity.to_f
              end
            end
          end
        end
      end

      InventoryBatchNumber.where(:product_id=> inventory.product_id, :periode=> inventory.periode).includes(:product_batch_number).each do |inv_bn|
        if arry["#{inv_bn.product_batch_number_id}"].present?
          puts "   [#{inv_bn.product_batch_number_id}] #{inv_bn.product_batch_number.number}; Stok Awal: #{inv_bn.begin_stock}; Trans In: #{inv_bn.trans_in}; Trans Out: #{inv_bn.trans_out}; End of Stock: #{inv_bn.end_stock}"
          
          inv_bn.update(:trans_in=> arry["#{inv_bn.product_batch_number_id}"]["trans_in"], :trans_out=> arry["#{inv_bn.product_batch_number_id}"]["trans_out"])
        else
          # puts "[#{inv_bn.material_batch_number_id}] #{inv_bn.material_batch_number.number}"
          puts " tidak ada transkasi IN dan atau OUT"
          inv_bn.update(:trans_in=> 0, :trans_out=> 0)
        end
      end

      # puts "arry: #{arry}"
      inventory.update(:trans_in=> sum_trans_in, :trans_out=> sum_trans_out, :updated_at=> DateTime.now)
      puts "[#{inventory.id}] IN: #{sum_trans_in}; OUT: #{sum_trans_out}"
      puts "----------------------------------"
    end

  end
  task :update_stocks, [:periode, :material_id] => :environment do |t, args|
    # material only
    records = Inventory.where(:periode=> args[:periode], :material_id=> args[:material_id]).includes(:material)
    records.each do |inventory|
      puts "#{inventory.periode}; Stok Awal: #{inventory.begin_stock}; Trans In: #{inventory.trans_in}; Trans Out: #{inventory.trans_out}; End of Stock: #{inventory.end_stock}"

      sum_trans_in = 0
      sum_trans_out = 0
      arry = {}
      InventoryLog.where(:inventory_id=> inventory.id).includes(inventory_adjustment_item: [:inventory_adjustment, :material_batch_number]).each do |log|
        
        material_batch_number_id = nil
        if log.inventory_adjustment_item.present?
          material_batch_number_id = log.inventory_adjustment_item.material_batch_number_id
        elsif log.material_outgoing_item.present?
          material_batch_number_id = log.material_outgoing_item.material_batch_number_id
        elsif log.material_return_item.present?
          material_batch_number_id = log.material_return_item.material_batch_number_id
        elsif log.material_additional_item.present?
          material_batch_number_id = log.material_additional_item.material_batch_number_id
        elsif log.material_receiving_item.present?
          material_batch_number_id = log.material_receiving_item.material_batch_number_id 
        elsif log.delivery_order_supplier_item.present?
          material_batch_number_id = log.delivery_order_supplier_item.material_batch_number_id
        end

        puts "   log --- #{log.status} => #{log.kind} #{log.quantity};  material_batch_number_id: #{material_batch_number_id}"
        if log.status =='active'
          if log.kind == 'in'
            sum_trans_in += log.quantity
            arry["#{material_batch_number_id}"] ||= {}
            if arry["#{material_batch_number_id}"]["trans_in"].present?
              arry["#{material_batch_number_id}"]["trans_in"] += log.quantity.to_f
            else
              arry["#{material_batch_number_id}"]["trans_in"] = log.quantity.to_f
            end
          end
          if log.kind == 'out'
            sum_trans_out += log.quantity
            arry["#{material_batch_number_id}"] ||= {}
            if arry["#{material_batch_number_id}"]["trans_out"].present?
              arry["#{material_batch_number_id}"]["trans_out"] += log.quantity.to_f
            else
              arry["#{material_batch_number_id}"]["trans_out"] = log.quantity.to_f
            end
          end
          arry["#{material_batch_number_id}"]["inv_bn_status"] = 'no'
        end
      end

      InventoryBatchNumber.where(:material_id=> inventory.material_id, :periode=> inventory.periode).includes(:material_batch_number).each do |inv_bn|
        if arry["#{inv_bn.material_batch_number_id}"].present?
          puts "   [#{inv_bn.material_batch_number_id}] #{inv_bn.material_batch_number.number}; Stok Awal: #{inv_bn.begin_stock}; Trans In: #{inv_bn.trans_in}; Trans Out: #{inv_bn.trans_out}; End of Stock: #{inv_bn.end_stock}"
          
          inv_bn.update(:trans_in=> arry["#{inv_bn.material_batch_number_id}"]["trans_in"], :trans_out=> arry["#{inv_bn.material_batch_number_id}"]["trans_out"])
          arry["#{inv_bn.material_batch_number_id}"]["inv_bn_status"] = 'exists'
        else
          # puts "[#{inv_bn.material_batch_number_id}] #{inv_bn.material_batch_number.number}"
          puts " tidak ada transkasi IN dan atau OUT"
          inv_bn.update(:trans_in=> 0, :trans_out=> 0)
        end
      end
      arry.each do |bn_id, value|
        # puts "#{bn_id}=> #{value}"
        case value["inv_bn_status"]
        when 'no'
          check_bn = InventoryBatchNumber.find_by(:company_profile_id=> 1, :material_id=> inventory.material_id, :periode=> inventory.periode, :material_batch_number_id=> bn_id)
          if check_bn.blank?
            check_bn = InventoryBatchNumber.new({
              :company_profile_id=> 1, 
              :material_id=> inventory.material_id, 
              :periode=> inventory.periode, 
              :material_batch_number_id=> bn_id,
              :trans_in=> value["trans_in"], 
              :trans_out=> value["trans_out"]
            })
            check_bn.save
            puts "not exists"
          end
        end
      end
      # puts "arry: #{arry}"
      inventory.update(:trans_in=> sum_trans_in, :trans_out=> sum_trans_out, :updated_at=> DateTime.now)
      puts "IN: #{sum_trans_in}; OUT: #{sum_trans_out}"
      puts "----------------------------------"
    end

  end
  task :update_outstanding_po_supplier, [:plant] => :environment do |t, args|
    PurchaseOrderSupplierItem.where(:status=> 'active').where("outstanding < 0").each do |po_item|
      outstanding = po_item.quantity
      po_item.material_receiving_items.each do |grn_item|
        puts "grn material: [#{grn_item.material_receiving.status}] [#{grn_item.id}] => qty (#{grn_item.quantity})"
        outstanding -=  grn_item.quantity
      end
      po_item.product_receiving_items.each do |grn_item|
        puts "grn product: [#{grn_item.product_receiving.status}] [#{grn_item.id}] => qty (#{grn_item.quantity})"
        outstanding -=  grn_item.quantity
      end
      po_item.consumable_receiving_items.each do |grn_item|
        puts "grn consumable: [#{grn_item.consumable_receiving.status}] [#{grn_item.id}] => qty (#{grn_item.quantity})"
        outstanding -=  grn_item.quantity
      end
      po_item.equipment_receiving_items.each do |grn_item|
        puts "grn equipment: [#{grn_item.equipment_receiving.status}] [#{grn_item.id}] => qty (#{grn_item.quantity})"
        outstanding -=  grn_item.quantity
      end
      po_item.general_receiving_items.each do |grn_item|
        puts "grn general: [#{grn_item.general_receiving.status}] [#{grn_item.id}] => qty (#{grn_item.quantity})"
        outstanding -=  grn_item.quantity
      end
      puts "po_item_id [#{po_item.id}] => qty (#{po_item.quantity}) outstanding (#{po_item.outstanding}) => #{po_item.outstanding == outstanding}"
    end

  end

  task :update_bn, [:plant] => :environment do |t, args|
    ProductBatchNumber.where(:status=> 'active').each do |bn|
      bn.update({:updated_at=> DateTime.now()})
    end
  end

  task :update_outstanding_sterilization_product_receiving, [:plant] => :environment do |t, args|
    puts "Start"
    SterilizationProductReceivingItem.where(:status=> 'active').includes(:sterilization_product_receiving)
    .where(:sterilization_product_receivings=> {:company_profile_id=> args[:plant]}).order("sterilization_product_receivings.id asc").each do |item|
      puts "SPR: #{item.sterilization_product_receiving.number} => qty: #{item.quantity}; outstanding: #{item.outstanding}"
      puts "Batch Number: #{item.product_batch_number.number}"

        records = ShopFloorOrderSterilizationItem.where(:status=> 'active').includes(:shop_floor_order_sterilization)
        .where(:shop_floor_order_sterilizations => {:company_profile_id=> args[:plant], :kind=> 'external', :status=> 'approved3'})
        .where(:product_batch_number_id=> item.product_batch_number_id)
        .order("shop_floor_order_sterilizations.id asc")
        sum_sfo_external = 0
        records.each do |sfo_external|
          puts "#{sfo_external.shop_floor_order_sterilization.number} => #{sfo_external.quantity}"
        sum_sfo_external += sfo_external.quantity
        end
      puts "sum_sfo_external: #{sum_sfo_external}"
      puts "Outstanding SPR Seharusnya: #{item.quantity - sum_sfo_external}"
      item.update_columns({:outstanding=> item.quantity - sum_sfo_external})
      puts "---------------------------------"
    end
  end 

  task :task1 => :environment do |t, args|
    Inventory.where(:company_profile_id=> 1, :periode=> ['202112','202201']).includes(:product)
    .where(:products => {:part_id=> 'SOAA'})
    .order("periode asc").each do |inventory|
      puts "[#{inventory.product.part_id}] periode: #{inventory.periode}=> begin: #{inventory.begin_stock}; in: #{inventory.trans_in}; out: #{inventory.trans_out}; end: #{inventory.end_stock};"
      bn_sum_begin = bn_sum_trans_in = bn_sum_trans_out = bn_sum_end = 0
      InventoryBatchNumber.where(:periode=> inventory.periode, :product_id=> inventory.product_id).includes(:product_batch_number).each do |bn_stock|
        puts "  #{bn_stock.product_batch_number.number} => begin: #{bn_stock.begin_stock}; in: #{bn_stock.trans_in}; out: #{bn_stock.trans_out}; end: #{bn_stock.end_stock};"
        bn_sum_begin += bn_stock.begin_stock.to_f
        bn_sum_trans_in += bn_stock.trans_in.to_f
        bn_sum_trans_out += bn_stock.trans_out.to_f
        bn_sum_end += bn_stock.end_stock.to_f
        bn_stock.update(:updated_at=> DateTime.now())
      end
      puts "[#{inventory.product.part_id}] periode: #{inventory.periode}=> begin: #{bn_sum_begin} (#{inventory.begin_stock == bn_sum_begin}); in: #{bn_sum_trans_in} (#{inventory.trans_in == bn_sum_trans_in}); out: #{bn_sum_trans_out} (#{inventory.trans_out == bn_sum_trans_out}); end: #{bn_sum_end} (#{inventory.end_stock == bn_sum_end});"
      puts "-------------------------------------------------"
    end
  end

  task :perbaikan_stock, [:plant, :prefix] => :environment do |t, args|
  	part_id = ['A010' ]
    # current_period = DateTime.now()
    current_period = '2021-12-01'.to_date
  	case args[:prefix]
  	when 'P'
      batch_numbers = ProductBatchNumber.where(:company_profile_id=> args[:plant], :status=> 'active').includes(:product).where(:products=> {:part_id=> part_id})
    	inventory_batch_numbers = InventoryBatchNumber.where(:company_profile_id=> args[:plant]).includes(:product).where(:products=> {:part_id=> part_id})
    	inventories = Inventory.where(:company_profile_id=> args[:plant]).where("periode like ? ", DateTime.now().at_beginning_of_year.strftime("%Y%m")).order("periode asc").includes(:product).where(:products=> {:part_id=> part_id})
    when 'M'
      batch_numbers = MaterialBatchNumber.where(:company_profile_id=> args[:plant], :status=> 'active').includes(:material).where(:materials=> {:part_id=> part_id})
    	inventory_batch_numbers = InventoryBatchNumber.where(:company_profile_id=> args[:plant] ).includes(:material).where(:materials=> {:part_id=> part_id})
    	inventories = Inventory.where(:company_profile_id=> args[:plant] ).where("periode like ? ", DateTime.now().at_beginning_of_year.strftime("%Y%m")).order("periode asc").includes(:material).where(:materials=> {:part_id=> part_id})
    end

    prev_stock = {}
    prev_periode = nil

    ( ((current_period.at_beginning_of_year-1.month).to_date) .. current_period.at_end_of_month).each do |dt|
      if dt.to_date.strftime("%d") == '01'
        periode = dt.to_date.strftime("%Y%m")
        # batch_numbers.where(:periode_yyyy=> periode.to_s[0..3]).each do |bn|
        batch_numbers.each do |bn|
          puts "[#{periode}] #{bn.number} "
  		  	case args[:prefix]
  		  	when 'P'
          	ibn = inventory_batch_numbers.find_by(:periode=> periode, :product_batch_number_id=> bn.id)
          when 'M'
          	ibn = inventory_batch_numbers.find_by(:periode=> periode, :material_batch_number_id=> bn.id)
          else
          	ibn = nil
          end

          if ibn.present?
          	case args[:prefix]
  	        when 'P'
  	          puts "[#{ibn.periode}] #{ibn.product.part_id} => #{ibn.product_batch_number.number} => created_at: #{bn.created_at}"
  	        when 'M'
  	          puts "[#{ibn.periode}] #{ibn.material.part_id} => #{ibn.material_batch_number.number} => created_at: #{bn.created_at}"
            end
            puts "#{prev_stock[ibn.id][:stock]}" if prev_stock.present? and prev_stock[ibn.id].present?

            ibn.update({:updated_at=> DateTime.now()})
            prev_stock[ibn.id] ||= {}
            prev_stock[ibn.id][:stock] = ibn.end_stock
          else
          	case args[:prefix]
  	        when 'P'
  	          ibn = InventoryBatchNumber.new({
  	            :product_id=> bn.product_id, 
  	            :product_batch_number_id=> bn.id,
  	            :periode=> periode, 
  	            :company_profile_id=> args[:plant],
  	            :begin_stock=> 0, 
  	            :trans_in=> 0, 
  	            :trans_out=> 0, 
  	            :end_stock=> 0, 
  	            :created_at=> DateTime.now()
  	          })
  	          ibn.save
              puts "create!"
  	        when 'M'
              # ada batch number dibuat tahun depan tapi digunakan untuk dokumen tahun sebelumnya
              # puts "#{periode.to_s[0,4]}.to_i == #{bn.periode_yyyy}"
              # puts "#{periode.to_s[0,4]}".to_i == "#{bn.periode_yyyy}".to_i
              # if "#{periode.to_s[0,4]}".to_i == "#{bn.periode_yyyy}".to_i
    	          ibn = InventoryBatchNumber.new({
    	            :material_id=> bn.material_id, 
    	            :material_batch_number_id=> bn.id,
    	            :periode=> periode, 
    	            :company_profile_id=> args[:plant],
    	            :begin_stock=> 0, 
    	            :trans_in=> 0, 
    	            :trans_out=> 0, 
    	            :end_stock=> 0, 
    	            :created_at=> DateTime.now()
    	          })
    	          ibn.save
                puts "create!"
              # end
  	        end
          end
        end
        puts "----------------------------- #{periode}"
      end
    end

    puts "------------------"
    inventories.each do |bn|
      bn.update({:updated_at=> DateTime.now()})
    end
  end


  task :check_batch_number => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    ShopFloorOrder.where(:number=> 'SFO/20/07/014').each do |header|
      puts "SFO: #{header.number}"
      ShopFloorOrderItem.where(:shop_floor_order_id=> header.id, :status=> 'active').each do |item|
        ProductBatchNumber.where(:shop_floor_order_item_id=> item.id, :status=> 'active').each do |bn|
          bn.update(:updated_at=> DateTime.now())
        end

        # outstanding = item.quantity
        # if item.product.present? and item.product.sterilization
        #   outstanding_sterilization = item.quantity
        #   outstanding_sterilization_out = item.quantity
        #   puts "produk sterilization"
        # else
        #   puts "bukan produk sterilization"
        #   outstanding_sterilization = 0
        #   outstanding_sterilization_out = 0
        # end
        # ProductBatchNumber.where(:shop_floor_order_item_id=> item.id, :status=> 'active').each do |bn|

        #   puts "   #{bn.product.part_id} | #{bn.number} | #{item.quantity}    | sterilization #{bn.product.sterilization} => #{bn.outstanding} and #{bn.outstanding_sterilization} and #{bn.outstanding_sterilization_out}"
        #   ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfos|
        #     puts "   sfos: #{sfos.shop_floor_order_sterilization.number} => #{sfos.quantity}"
        #   end
        #   FinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |whfg|
        #     puts "   fg: #{whfg.finish_good_receiving.number} => #{whfg.quantity}"
        #     if item.product.present? and whfg.finish_good_receiving.status == 'approved3'
        #       outstanding -= whfg.quantity
        #     end
        #   end
        #   SemiFinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgin|
        #     puts "   semi fg: #{sfgin.semi_finish_good_receiving.number} => #{sfgin.quantity}"
        #     if item.product.present? and item.product.sterilization and sfgin.semi_finish_good_receiving.status == 'approved3'
        #       outstanding_sterilization -= sfgin.quantity
        #     end
        #   end
        #   SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgout|
        #     puts "   sterilization: #{sfgout.semi_finish_good_outgoing.number} => #{sfgout.quantity}"
        #     if item.product.present? and item.product.sterilization and sfgout.semi_finish_good_outgoing.status == 'approved3'
        #       outstanding_sterilization_out -= sfgout.quantity
        #     end
        #   end
        #   puts "Qty SFO: #{item.quantity}"
        #   puts "outstanding_sterilization_in: #{outstanding_sterilization}"
        #   puts "outstanding_sterilization_out: #{outstanding_sterilization_out}"
        #   puts "outstanding: #{outstanding}"

        #   # ga boleh di 0 kan, karena dokumen Semi FG receving partial pembuatan dokumennya
        #   # kasus ini terjadi pada tanggal 2020/09/03
        #   # outstanding_sterilization_out = 0 if outstanding < item.quantity
        #   # outstanding_sterilization = 0 if outstanding < item.quantity

        #   puts "  outstanding whfg: seharusnya #{outstanding} | actual #{bn.outstanding} => #{outstanding == bn.outstanding}"
        #   puts "  outstanding semi fg receiving note: seharusnya #{outstanding_sterilization} | actual #{bn.outstanding_sterilization} => #{outstanding_sterilization == bn.outstanding_sterilization}"
        #   puts "  outstanding semi fg for sterilization: seharusnya #{outstanding_sterilization_out} | actual #{bn.outstanding_sterilization_out} => #{outstanding_sterilization_out == bn.outstanding_sterilization_out}"

        #   puts "--------------------------------------------------------------------"
        #   bn.update(:outstanding=> outstanding, :outstanding_sterilization=> outstanding_sterilization, :outstanding_sterilization_out=> outstanding_sterilization_out, :updated_at=> DateTime.now())
          
        #   # if header.status == 'approved3'
        #   #   periode = header.approved3_at.strftime("%Y%m")
        #   #   inventory_batch_number = InventoryBatchNumber.find_by(:company_profile_id=> bn.company_profile_id, 
        #   #     :product_batch_number_id => bn.id, 
        #   #     :product_id=> bn.product_id, :periode=> periode)

        #   #   if inventory_batch_number.blank?
        #   #     inventory_batch_number = InventoryBatchNumber.create({
        #   #       :company_profile_id=> bn.company_profile_id, 
        #   #       :product_batch_number_id=> bn.id,
        #   #       :product_id=> bn.product_id,
        #   #       :periode=> periode,
        #   #       :trans_in => trans_in,
        #   #       :created_at=> DateTime.now()
        #   #     })
        #   #   end
        #   # end

        # end

      end
    end
  end

  
  task :check_batch_number_spr => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    SterilizationProductReceiving.where(:status=> 'approved3', :date=> '2022-01-01' .. '2022-12-31').each do |header|
      puts "SPR: #{header.number}"
      SterilizationProductReceivingItem.where(:sterilization_product_receiving_id=> header.id, :status=> 'active').each do |item|
        outstanding = item.quantity

        # SPR tanpa dibuatkan Semi FG receiving
        outstanding_sterilization = 0
        if item.product.present? and item.product.sterilization
          # outstanding_sterilization = item.quantity
          outstanding_sterilization_out = item.quantity
        else
          # outstanding_sterilization = 0
          outstanding_sterilization_out = 0
        end
        ProductBatchNumber.where(:sterilization_product_receiving_item_id=> item.id, :status=> 'active').each do |bn|
          puts "   #{bn.product.part_id} | #{bn.number} | #{item.quantity}    | sterilization #{bn.product.sterilization} => #{bn.outstanding} and #{bn.outstanding_sterilization} and #{bn.outstanding_sterilization_out}"
          ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfos|
            puts "   sfos: #{sfos.shop_floor_order_sterilization.number} => #{sfos.quantity}"
          end
          SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgout|
            puts "   sterilization: #{sfgout.semi_finish_good_outgoing.number} => #{sfgout.quantity}"
            if item.product.present? and item.product.sterilization and sfgout.semi_finish_good_outgoing.status == 'approved3'
              outstanding_sterilization_out -= sfgout.quantity
            end
          end
          FinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |whfg|
            puts "   fg: #{whfg.finish_good_receiving.number} => #{whfg.quantity}"
            if item.product.present? and whfg.finish_good_receiving.status == 'approved3'
              outstanding -= whfg.quantity
            end
          end
          # SemiFinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgin|
          #   puts "   semi fg: #{sfgin.semi_finish_good_receiving.number} => #{sfgin.quantity}"
          #   if item.product.present? and item.product.sterilization and sfgin.semi_finish_good_receiving.status == 'approved3'
          #     outstanding_sterilization -= sfgin.quantity
          #   end
          # end


          puts "  outstanding whfg: seharusnya #{outstanding} | actual #{bn.outstanding} => #{outstanding == bn.outstanding}"
          # puts "  outstanding semi fg receiving note: seharusnya #{outstanding_sterilization} | actual #{bn.outstanding_sterilization} => #{outstanding_sterilization == bn.outstanding_sterilization}"
          puts "  outstanding semi fg for sterilization: seharusnya #{outstanding_sterilization_out} | actual #{bn.outstanding_sterilization_out} => #{outstanding_sterilization_out == bn.outstanding_sterilization_out}"

          puts "--------------------------------------------------------------------"
          bn.update_columns(:outstanding=> outstanding, :outstanding_sterilization_out=> outstanding_sterilization_out, :outstanding_sterilization=> outstanding_sterilization)
          
        end

      end
    end
  end
end