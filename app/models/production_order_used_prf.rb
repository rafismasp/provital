class ProductionOrderUsedPrf < ApplicationRecord
	belongs_to :purchase_request_item, optional: true
	belongs_to :production_order_item, optional: true
	belongs_to :production_order_detail_material, optional: true
end
