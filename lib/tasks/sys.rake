namespace :sys do
  desc "Rake file 2020-06-20" 
  task :update_do_salah_so => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    # yg digunakan item.sales_order_item.sales_order_id
    so_selected = Array.new()
    DeliveryOrder.where(:number=> 'DO20110003').each do |record|
      puts "#{record.number}"
      DeliveryOrderItem.where(:delivery_order_id=> record.id, :status=> 'active').each do |item|
        puts " picking slip: #{item.picking_slip_item.picking_slip.number}"
        puts " Header SO: #{item.picking_slip_item.picking_slip.sales_order.number}"
        puts " so item id: #{item.picking_slip_item.sales_order_item_id}"
        puts " Item so : #{item.picking_slip_item.sales_order_item.sales_order.number}"
        if item.picking_slip_item.sales_order_item.sales_order_id != item.picking_slip_item.picking_slip.sales_order_id
          item.picking_slip_item.picking_slip.update_columns(:sales_order_id=> item.picking_slip_item.sales_order_item.sales_order_id)
          so_selected.push(item.picking_slip_item.sales_order_item.sales_order_id) unless so_selected.include?(item.picking_slip_item.sales_order_item.sales_order_id)
          so_selected.push(item.picking_slip_item.picking_slip.sales_order_id) unless so_selected.include?(item.picking_slip_item.picking_slip.sales_order_id)
        end
        puts " ------------------------------"
        puts " Header so : #{record.sales_order.number}"
        puts " so item id: #{item.sales_order_item_id}"
        puts " Item SO: #{item.sales_order_item.sales_order.number}"
        puts " #{item.product.part_id} #{item.quantity}"
        if item.sales_order_item.sales_order_id != record.sales_order_id
          record.update_columns(:sales_order_id=> item.sales_order_item.sales_order_id)
          so_selected.push(item.sales_order_item.sales_order_id) unless so_selected.include?(item.sales_order_item.sales_order_id)
          so_selected.push(record.sales_order_id) unless so_selected.include?(record.sales_order_id)        
        end
      end
      
    end
    SalesOrderItem.where(:sales_order_id=> so_selected).each do |so_item|
      puts "#{so_item.sales_order.number} => #{so_item.quantity} outstanding: #{so_item.outstanding}"
      sum_do = 0
      DeliveryOrderItem.where(:sales_order_item_id=> so_item.id, :status=> 'active').each do |do_item|
        if do_item.delivery_order.status == 'approved3'
          sum_do += do_item.quantity
        end
      end
      puts "DO Qty: #{sum_do}"
      if (so_item.quantity - sum_do ) != so_item.outstanding
        puts "outstanding SO tidak sesuai, seharusnya: #{(so_item.quantity - sum_do )}"
        so_item.update_columns(:outstanding=> (so_item.quantity - sum_do ))
      end
    end

    SalesOrder.where(:id=> so_selected).each do |so_header|
      puts "#{so_header.number} outstanding: #{so_header.outstanding}"
      sum_outstanding_so = 0
      SalesOrderItem.where(:sales_order_id=> so_header.id, :status=> 'active').each do |so_item|
        sum_outstanding_so += so_item.outstanding
      end
      if sum_outstanding_so != so_header.outstanding
        puts "outstanding SO header tidak sesuai, seharusnya: #{sum_outstanding_so}"
        so_header.update_columns(:outstanding=> sum_outstanding_so)
      end
    end
  end


  task :update_batch_number_picking_slip => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    OutgoingInspectionItem.all.each do |item|
    	item.update_columns(:product_batch_number_id=> item.picking_slip_item.product_batch_number_id)
    end
  end


  task :update_outstanding_direct_labor => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    ProductBatchNumber.where(:number=> ['KAAA20001', 'KAAA20002', 'KAAA20003', 'KAAA20004', 'KAAA20005', 'AAAZ20005', 'AABN20002', 'AAAL20001', 'AABK20003', 'AABL20004', 'AABN20003', 'AAAK20007', 'AAAL20004', 'AABA20007', 'AABA20008', 'AAAZ20007', 'AABK20004', 'AABL20005', 'AABM20001', 'AAAZ20008', 'AAAZ20009', 'AAAZ20010', 'AAAZ20011', 'AAAZ20012', 'AACZ20001', 'AADA20001', 'AADY20001', 'AADY20002', 'AABK20005', 'AABL20006', 'AABM20002', 'AACZ20003', 'AADY20003', 'AADA20004', 'AADB20001', 'AADB20002', 'AACZ20004', 'AAAV20002', 'AAAW20014', 'AABK20006', 'AABL20007', 'AABM20003', 'AABA20011', 'AABZ20004', 'AADY20004', 'AEAD21001', 'AAAY21001', 'AAAZ21001', 'ADAG21001', 'AAEU21001', 'AAEV21001', 'AAEW21001', 'AAAS21001', 'AAAT21001', 'AAAU21001', 'AABY21001', 'AABZ21001', 'AACT21001', 'AAAZ21002', 'AAFD21001', 'AAFE21001', 'AAFF21001', 'AABW21001', 'AABD21001', 'AABC21001', 'AAAZ21003', 'AABX21001', 'AABY21002', 'AABZ21002', 'AABY21003', 'ADAG21002', 'AABD21002', 'AABC21002', 'AABD21003', 'AEAG21001', 'AABD21004', 'AABI21001', 'AABJ21001', 'AADA21001', 'AADB21001']).each do |item|
      if item.shop_floor_order_item.present?
        sfo_quantity = item.shop_floor_order_item.quantity
        sum_quantity = 0
        DirectLaborItem.where(:product_batch_number_id=> item.id, :status=> 'active').each do |direct_item|
          sum_quantity += direct_item.quantity if direct_item.direct_labor.status == 'approved3'
        end
        result = (sfo_quantity.to_f-sum_quantity.to_f)

        puts "sfo_quantity: #{sfo_quantity}; qty direct labor: #{sum_quantity}; bn outstanding direct labor: #{result}"
      	item.update_columns(:outstanding_direct_labor=> result)
      end
    end
  end


  task :update_moq => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    my_arr = [{:part_id=> "A010", :moq=> "6", :unit=> "rim"},
        {:part_id=> "A023", :moq=> "6", :unit=> "rim"},
        {:part_id=> "A048", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B001", :moq=> "55000", :unit=> "Pcs"},
        {:part_id=> "B007", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B008", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B009", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B010", :moq=> "55000", :unit=> "Pcs"},
        {:part_id=> "B021", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B022", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B026", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B046", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B047", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B048", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B049", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B050", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B051", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B068", :moq=> "500", :unit=> "pcs"},
        {:part_id=> "B070", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B071", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B072", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B081", :moq=> "500", :unit=> "pcs"},
        {:part_id=> "B082", :moq=> "420", :unit=> "Roll"},
        {:part_id=> "B083", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B084", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B085", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B089", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B090", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B091", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B095", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B096", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B097", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B101", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B102", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B105", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B106", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B107", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B111", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B113", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B118", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B119", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B120", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B124", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B126", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B128", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B129", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B130", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B134", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B137", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B138", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B139", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B144", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B145", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B146", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B157", :moq=> "100", :unit=> "Kg"},
        {:part_id=> "A085", :moq=> "204", :unit=> "Roll"},
        {:part_id=> "A086", :moq=> "136", :unit=> "Roll"},
        {:part_id=> "B162", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B163", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B164", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B166", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B167", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B168", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B170", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B171", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B172", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B173", :moq=> "100", :unit=> "Kg"},
        {:part_id=> "B177", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B178", :moq=> "6", :unit=> "rim"},
        {:part_id=> "B179", :moq=> "6", :unit=> "rim"},
      ]
    my_arr.each do |record|
      unit = Unit.find_by(:name=> record[:unit])
      if unit.present?
        material = Material.find_by(:part_id=> record[:part_id])
        if material.present?
          material.update_columns({
            :minimum_order_quantity=> record[:moq].to_f,
            :unit_id=> unit.id,
          })
          puts "#{record[:part_id]} => #{record[:moq]} #{record[:unit]}"
        else
          puts "#{record[:part_id]} => #{record[:moq]} #{record[:unit]} tidak ada part id"
        end
      else
        puts "#{record[:part_id]} => #{record[:moq]} #{record[:unit]} tidak ada unit"
      end
    end
  end


  task :update_outstanding_picking_slip => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    PickingSlip.where(:number=> 'PS20090041').each do |header|
      sum_outstanding = 0
        PickingSlipItem.where(:picking_slip_id=> header.id, :status=> 'active').each do |item|
          sum_outstanding += item.outstanding
        end
      if sum_outstanding != header.outstanding
        puts "#{header.number} tidak sesuai"
        header.update_columns(:outstanding=> sum_outstanding)
      end
    end
  end

  task :update_employee_contract => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    
    EmployeeContract.where(:company_profile_id => 1).each do |contract|
      contract.employee.update_columns({
        :begin_of_contract=> contract.begin_of_contract,
        :end_of_contract=> contract.end_of_contract
      })
    end
  end



end