class ShopFloorOrderSterilization < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	
	belongs_to :company_profile
	belongs_to :sales_order, optional: true
  
  has_many :shop_floor_order_sterilization_items, -> { where status: 'active' }

	after_save :update_outstanding_spr

	private
		def update_outstanding_spr
			case self.kind
			when 'external'
				case self.status
				when 'approved3','canceled3' 
					self.shop_floor_order_sterilization_items.each do |item|
						if self.status == 'approved3'
							if item.product_batch_number.present? and item.product_batch_number.sterilization_product_receiving_item.present?
								item.product_batch_number.sterilization_product_receiving_item.update({
									:outstanding=> item.product_batch_number.sterilization_product_receiving_item.outstanding - item.quantity
								})
							end
						elsif self.status == 'canceled3'
							if item.product_batch_number.present? and item.product_batch_number.sterilization_product_receiving_item.present?
								item.product_batch_number.sterilization_product_receiving_item.update({
									:outstanding=> item.product_batch_number.sterilization_product_receiving_item.outstanding + item.quantity
								})
							end
						end
					end
				end
			when 'internal'
			end
		end
end
