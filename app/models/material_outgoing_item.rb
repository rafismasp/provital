class MaterialOutgoingItem < ApplicationRecord
	belongs_to :material_outgoing
	belongs_to :material_batch_number, optional: true
	belongs_to :material, optional: true
	belongs_to :product_batch_number, optional: true
	belongs_to :product, optional: true
end
