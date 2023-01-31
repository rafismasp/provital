class ProductionOrderItem < ApplicationRecord
	extend OrderAsSpecified
	belongs_to :production_order
	belongs_to :sales_order_item, optional: true
	belongs_to :product

	has_many :production_order_used_prves, -> { where status: 'active' }
end
