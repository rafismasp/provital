class ShopFloorOrderItem < ApplicationRecord
	belongs_to :shop_floor_order
	belongs_to :sales_order, optional: true
	belongs_to :product

  before_update :update_outstanding_batch_number

	def edit_quantity
    # jika true maka SFO bisa diedit
    result = true
    product_batch_number =  ProductBatchNumber.find_by(:shop_floor_order_item_id=> self.id, :status=> 'active')
    if product_batch_number.present?
      if self.product.sterilization == true
        if SemiFinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> product_batch_number.id).present?
          result = false
        end
      else
        if FinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> product_batch_number.id).present?
          result = false
        end
      end
    end
    return result
	end
  private
  	def update_outstanding_batch_number
  		if self.quantity_was != self.quantity
	  		logger.info "old value: #{self.quantity_was}"
	  		logger.info "new value: #{self.quantity}"
	  		outstanding = self.quantity
        if self.product.present? and self.product.sterilization
          outstanding_sterilization = self.quantity
          outstanding_sterilization_out = self.quantity
        else
          outstanding_sterilization = 0
          outstanding_sterilization_out = 0
        end
	  		ProductBatchNumber.where(:shop_floor_order_item_id=> self.id, :status=> 'active').each do |bn|
          sfo_quantity = self.quantity
          sum_quantity = 0
          DirectLaborItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |direct_item|
            sum_quantity += direct_item.quantity if direct_item.direct_labor.status == 'approved3'
          end
          outstanding_direct_labor = (sfo_quantity.to_f-sum_quantity.to_f)

          puts "sfo_quantity: #{sfo_quantity}; qty direct labor: #{sum_quantity}; bn outstanding direct labor: #{outstanding_direct_labor}"
          
          ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfos|
            puts "   SFOS: #{sfos.shop_floor_order_sterilization.number} => #{sfos.quantity}"
          end
          FinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |whfg|
            puts "[IN] fg: #{whfg.finish_good_receiving.number} => #{whfg.quantity}"
            if self.product.present? and whfg.finish_good_receiving.status == 'approved3'
              outstanding -= whfg.quantity
            end
          end
          SemiFinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgin|
            puts "[IN] Semi FG: #{sfgin.semi_finish_good_receiving.number} => #{sfgin.quantity}"
            if self.product.present? and self.product.sterilization and sfgin.semi_finish_good_receiving.status == 'approved3'
              outstanding_sterilization -= sfgin.quantity
            end
          end
          SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgout|
            puts "[OUT] sterilization: #{sfgout.semi_finish_good_outgoing.number} => #{sfgout.quantity}"
            if self.product.present? and self.product.sterilization and sfgout.semi_finish_good_outgoing.status == 'approved3'
              outstanding_sterilization_out -= sfgout.quantity
            end
          end
          puts "Qty SFO: #{self.quantity}"
          puts "outstanding_sterilization_in: #{outstanding_sterilization}"
          puts "outstanding_sterilization_out: #{outstanding_sterilization_out}"
          puts "outstanding: #{outstanding}"

          # ga boleh di 0 kan, karena dokumen Semi FG receving partial pembuatan dokumennya
          # kasus ini terjadi pada tanggal 2020/09/03
          # outstanding_sterilization_out = 0 if outstanding < self.quantity
          # outstanding_sterilization = 0 if outstanding < self.quantity

          puts "  outstanding whfg: seharusnya #{outstanding} | actual #{bn.outstanding} => #{outstanding == bn.outstanding}"
          puts "  outstanding semi fg receiving note: seharusnya #{outstanding_sterilization} | actual #{bn.outstanding_sterilization} => #{outstanding_sterilization == bn.outstanding_sterilization}"
          puts "  outstanding semi fg for sterilization: seharusnya #{outstanding_sterilization_out} | actual #{bn.outstanding_sterilization_out} => #{outstanding_sterilization_out == bn.outstanding_sterilization_out}"

          puts "--------------------------------------------------------------------"
          bn.update_columns(:outstanding=> outstanding, :outstanding_sterilization=> outstanding_sterilization, :outstanding_sterilization_out=> outstanding_sterilization_out, :outstanding_direct_labor=> outstanding_direct_labor)
          
	  		end
  		end
  	end
end
