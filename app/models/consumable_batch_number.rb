class ConsumableBatchNumber < ApplicationRecord
	belongs_to :company_profile
	belongs_to :consumable_receiving, optional: true
	belongs_to :consumable_receiving_item, optional: true
	belongs_to :consumable
end
