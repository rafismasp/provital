class VirtualReceiving < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	
	belongs_to :company_profile
	belongs_to :purchase_order_supplier
	belongs_to :department
	belongs_to :employee_section
	belongs_to :purchase_request, optional: true

	has_many :virtual_receiving_items, -> { where status: 'active' }
end
