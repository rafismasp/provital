class DirectLaborPriceDetail < ApplicationRecord
	scope :status_active, -> { where(:status=> 'active').order('activity_name ASC') }
	belongs_to :direct_labor_price
end
