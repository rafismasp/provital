class VirtualReceivingItem < ApplicationRecord
	belongs_to :virtual_receiving
	belongs_to :purchase_order_supplier_item

	belongs_to :product, optional: true
	belongs_to :material, optional: true
	belongs_to :consumable, optional: true
	belongs_to :equipment, optional: true
	belongs_to :general, optional: true
end
