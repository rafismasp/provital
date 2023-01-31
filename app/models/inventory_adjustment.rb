class InventoryAdjustment < ApplicationRecord
	validates :number, uniqueness: { scope: :company_profile_id, message: "cannot be duplicate" }
	has_many :inventory_adjustment_items
	belongs_to :company_profile
end
