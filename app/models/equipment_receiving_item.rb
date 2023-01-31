class EquipmentReceivingItem < ApplicationRecord
	belongs_to :equipment_receiving
	belongs_to :equipment
	belongs_to :purchase_order_supplier_item
	belongs_to :equipment_batch_number, optional: true
end
