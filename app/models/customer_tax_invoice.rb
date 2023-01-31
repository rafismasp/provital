class CustomerTaxInvoice < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "cannot be duplicate per customer" }
	belongs_to :company_profile
	belongs_to :customer
end
