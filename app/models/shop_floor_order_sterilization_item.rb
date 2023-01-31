class ShopFloorOrderSterilizationItem < ApplicationRecord
	belongs_to :shop_floor_order_sterilization
	belongs_to :product
	belongs_to :product_batch_number
end
