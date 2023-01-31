class FinishGoodReceiving < ApplicationRecord
	validates :number, uniqueness: { scope: :company_profile_id, message: "cannot be duplicate" }

	belongs_to :company_profile
end
