class DirectLaborOutstanding < ApplicationRecord
	belongs_to :direct_labor
	belongs_to :product_batch_number
	belongs_to :product
	belongs_to :direct_labor_price_detail
end
