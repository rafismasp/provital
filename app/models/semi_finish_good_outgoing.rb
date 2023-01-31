class SemiFinishGoodOutgoing < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }

	belongs_to :company_profile
end
