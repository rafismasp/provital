class VehicleInspection < ApplicationRecord
	belongs_to :delivery_order
	has_many :vehicle_inspection_items
end
