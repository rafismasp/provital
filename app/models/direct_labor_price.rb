class DirectLaborPrice < ApplicationRecord
	has_many :direct_labor_price_details, -> { status_active }

	belongs_to :product
	belongs_to :currency
end
