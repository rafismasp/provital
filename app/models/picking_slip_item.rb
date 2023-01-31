class PickingSlipItem < ApplicationRecord
	extend OrderAsSpecified
	belongs_to :picking_slip
	belongs_to :product
	belongs_to :product_batch_number
	belongs_to :sales_order_item

	after_save :update_outstanding_batch_number

	private
		def update_outstanding_batch_number
			if self.product_batch_number.present?
				self.product_batch_number.update({:updated_at=> DateTime.now()})
			end
		end
end
