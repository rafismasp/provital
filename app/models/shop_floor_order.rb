class ShopFloorOrder < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	
	belongs_to :company_profile
	belongs_to :sales_order, optional: true
	belongs_to :material_outgoing, optional: true
end
