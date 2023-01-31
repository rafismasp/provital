class InventoryAdjustmentItem < ApplicationRecord
	belongs_to :inventory_adjustment
	belongs_to :product_batch_number, optional: true
	belongs_to :product, optional: true
	belongs_to :material_batch_number, optional: true
	belongs_to :material, optional: true
end
