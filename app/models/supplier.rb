class Supplier < ApplicationRecord
	validates :number, uniqueness: { scope: :company_profile_id, message: "code cannot be duplicate" }
	
	belongs_to :company_profile
	belongs_to :tax
	belongs_to :term_of_payment
	belongs_to :currency

	has_many :supplier_banks, -> { where status: 'active' }
	has_many :payment_suppliers
	has_many :payment_request_suppliers
end
