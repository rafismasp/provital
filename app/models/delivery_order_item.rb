class DeliveryOrderItem < ApplicationRecord
	extend OrderAsSpecified
	belongs_to :delivery_order
	belongs_to :product
	belongs_to :product_batch_number
	belongs_to :sales_order_item
	belongs_to :picking_slip_item
end
