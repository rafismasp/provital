class SupplierTaxInvoice < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "cannot be duplicate per supplier" }
	belongs_to :company_profile
	belongs_to :supplier
end
