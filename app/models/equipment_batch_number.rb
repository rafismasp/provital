class EquipmentBatchNumber < ApplicationRecord
	belongs_to :company_profile
	belongs_to :equipment_receiving, optional: true
	belongs_to :equipment_receiving_item, optional: true
	belongs_to :equipment
end
