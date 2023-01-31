namespace :prf do
  desc "Rake file PRF" 

  task :check_pdm_item => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    PdmItem.where(:pdm_id=> 173, :status=> 'active').each do |item|
      purchase_request_used_pdm = PurchaseRequestUsedPdm.find_by(:pdm_item_id=> item.id)
      if purchase_request_used_pdm.present?
        puts item.id
      else
        puts "#{item.id} belum dibuat PRF"
        item.update({
          :outstanding_prf=> item.quantity
        })
      end
    end
  end

  task :update_signature => :environment do |t, args|
    ActiveRecord::Base.establish_connection :development
    PurchaseRequest.all.each do |record|
      puts record.number
      if record.status == 'approved3'
        user2 = User.find_by(:id=> record.approved3_by)
        if user2.present?
          puts "approved by: #{record.approved3_by} => #{user2.signature}"
          record.update_columns({:img_approved3_by=> user2.signature})
        end
      end
      user1 = User.find_by(:id=> record.created_by)
      puts "created_by: #{record.created_by} => #{user1.signature}"
      record.update_columns({:img_created_by=> user1.signature })

    end
  end

  task :summary_production_order => :environment do |t, args|
    # update qty kebutuhan spp
    ActiveRecord::Base.establish_connection :development
    PurchaseRequest.where(:number=> 'PRF/03A/20/11/002').each do |record|
      PurchaseRequestItem.where(:purchase_request_id=> record.id, :status=> 'active').each do |item|
        spp_sum =  ProductionOrderUsedPrf.find_by(:purchase_request_item_id=> item.id)
        if spp_sum.present?
          moq = item.summary_production_order.to_f+item.moq_quantity.to_f
          puts "Qty SPP: #{item.summary_production_order}; seharusnya: #{spp_sum.production_order_detail_material.quantity};"
          puts "Qty PRF: #{item.quantity}"
          puts "Ost PRF: #{item.outstanding}"
          puts "Moq PRF: #{item.moq_quantity}; seharusnya: #{moq-spp_sum.production_order_detail_material.quantity.to_f}"
          item.update_columns({
            :quantity=> spp_sum.production_order_detail_material.quantity,
            :outstanding=> spp_sum.production_order_detail_material.quantity,
            :moq_quantity=> (moq-spp_sum.production_order_detail_material.quantity.to_f),
            :summary_production_order=> spp_sum.production_order_detail_material.quantity
          })
        end
        puts "-------------------------"
      end
      record.update_columns(:outstanding=> PurchaseRequestItem.where(:purchase_request_id=> record.id, :status=> 'active').sum(:outstanding))
    end
  end

  task :check_spp => :environment do |t, args|
    # update qty kebutuhan spp
    ActiveRecord::Base.establish_connection :development
    ProductionOrder.where(:number=> ['SPP22040010']).order("created_at asc").each do |spp|
      c = 1
      ProductionOrderItem.where(:production_order_id=> spp.id, :status=> 'active').includes(:product).each do |spp_item|
        puts "[#{spp.number}] part_id: #{spp_item.product.part_id}; Qty: #{spp_item.quantity}"

        ProductionOrderDetailMaterial.where(:production_order_id=> spp.id, :status=> 'active', :production_order_item_id=> spp_item.id).each do |spp_item_material|
          if spp_item_material.material.present?
            puts "  [#{c}] #{spp_item_material.prf_kind}: #{spp_item_material.material.part_id}; Qty: #{spp_item_material.quantity}"
          else
            if spp_item_material.product.present?
              puts "  [#{c}] #{spp_item_material.prf_kind}: #{spp_item_material.product.part_id}; Qty: #{spp_item_material.quantity}"
            
            end
          end
          c+=1
        end
      end
    end
  end
end