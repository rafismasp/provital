class Customer < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "code cannot be duplicate" }

	belongs_to :company_profile
	belongs_to :currency
	belongs_to :term_of_payment
	belongs_to :tax
end
