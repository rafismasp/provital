class MaterialReceivingItem < ApplicationRecord
	belongs_to :material_receiving
	belongs_to :purchase_order_supplier_item
	belongs_to :material_batch_number, optional: true
	belongs_to :material
end
