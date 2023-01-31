class SterilizationProductReceivingItem < ApplicationRecord
	belongs_to :sterilization_product_receiving
	belongs_to :product
	belongs_to :sales_order_item, optional: true
	belongs_to :product_batch_number, optional: true

  before_update :update_outstanding_batch_number

	def edit_quantity
		product_batch_number =	ProductBatchNumber.where(:sterilization_product_receiving_item_id=> self.id, :status=> 'active')
		if product_batch_number.present?
			if self.quantity > product_batch_number.sum(:outstanding_sterilization_out)
				return false
			end
		end
		return true
	end

  private
  	def update_outstanding_batch_number
  		if self.quantity_was != self.quantity
	  		logger.info "old value: #{self.quantity_was}"
	  		logger.info "new value: #{self.quantity}"
	 			outstanding = self.quantity

	      # SPR tanpa dibuatkan Semi FG receiving
	      outstanding_sterilization = 0
	      if self.product.present? and self.product.sterilization
	        outstanding_sterilization_out = self.quantity
	      else
	        outstanding_sterilization_out = 0
	      end

	      ProductBatchNumber.where(:sterilization_product_receiving_item_id=> self.id, :status=> 'active').each do |bn|
	      	sfo_quantity = self.quantity
	        sum_quantity = 0
	        DirectLaborItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |direct_item|
	          sum_quantity += direct_item.quantity if direct_item.direct_labor.status == 'approved3'
	        end
	        outstanding_direct_labor = (sfo_quantity.to_f-sum_quantity.to_f)

	        puts "sfo_quantity: #{sfo_quantity}; qty direct labor: #{sum_quantity}; bn outstanding direct labor: #{outstanding_direct_labor}"
	      	
	        ShopFloorOrderSterilizationItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfos|
	          puts "   sfos: #{sfos.shop_floor_order_sterilization.number} => #{sfos.quantity}"
	        end
	        SemiFinishGoodOutgoingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |sfgout|
	          puts "   sterilization: #{sfgout.semi_finish_good_outgoing.number} => #{sfgout.quantity}"
	          if self.product.present? and self.product.sterilization and sfgout.semi_finish_good_outgoing.status == 'approved3'
	            outstanding_sterilization_out -= sfgout.quantity
	          end
	        end
	        FinishGoodReceivingItem.where(:product_batch_number_id=> bn.id, :status=> 'active').each do |whfg|
	          puts "   fg: #{whfg.finish_good_receiving.number} => #{whfg.quantity}"
	          if self.product.present? and whfg.finish_good_receiving.status == 'approved3'
	            outstanding -= whfg.quantity
	          end
	        end

	        puts "  outstanding whfg: seharusnya #{outstanding} | actual #{bn.outstanding} => #{outstanding == bn.outstanding}"
	        puts "  outstanding semi fg for sterilization: seharusnya #{outstanding_sterilization_out} | actual #{bn.outstanding_sterilization_out} => #{outstanding_sterilization_out == bn.outstanding_sterilization_out}"

	        puts "--------------------------------------------------------------------"
	        bn.update_columns(:outstanding=> outstanding, :outstanding_sterilization_out=> outstanding_sterilization_out, :outstanding_sterilization=> outstanding_sterilization, :outstanding_direct_labor=> outstanding_direct_labor)
	        
	      end
	    end
    end
end
