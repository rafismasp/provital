class GeneralReceivingItem < ApplicationRecord
	belongs_to :general_receiving
	belongs_to :general
	belongs_to :purchase_order_supplier_item
	belongs_to :general_batch_number, optional: true
end
