class OutgoingInspectionItem < ApplicationRecord
	extend OrderAsSpecified
	belongs_to :outgoing_inspection
	belongs_to :picking_slip_item
	belongs_to :product
	belongs_to :product_batch_number
end
