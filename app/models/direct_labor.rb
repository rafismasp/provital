class DirectLabor < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	has_many :direct_labor_items

	belongs_to :company_profile
	belongs_to :direct_labor_worker
end
