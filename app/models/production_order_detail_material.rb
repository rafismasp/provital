class ProductionOrderDetailMaterial < ApplicationRecord
	belongs_to :production_order
	belongs_to :production_order_item
	belongs_to :sales_order, optional: true
	belongs_to :sales_order_item, optional: true
	belongs_to :product
	belongs_to :material, optional: true
	
	has_many :production_order_used_prves, -> { where status: 'active' }
end
