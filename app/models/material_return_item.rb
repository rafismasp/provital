class MaterialReturnItem < ApplicationRecord
	belongs_to :material_return
	belongs_to :material_outgoing_item
	belongs_to :material_batch_number, optional: true
	belongs_to :material, optional: true
	belongs_to :product_batch_number, optional: true
	belongs_to :product, optional: true
end
