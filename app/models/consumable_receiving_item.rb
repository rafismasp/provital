class ConsumableReceivingItem < ApplicationRecord
	belongs_to :consumable_receiving
	belongs_to :consumable
	belongs_to :purchase_order_supplier_item
	belongs_to :consumable_batch_number, optional: true
end
