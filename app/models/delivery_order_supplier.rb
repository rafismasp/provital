class DeliveryOrderSupplier < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	has_many :delivery_order_supplier_items

	belongs_to :company_profile
	belongs_to :supplier
	belongs_to :tax
	belongs_to :term_of_payment
	belongs_to :currency
end
