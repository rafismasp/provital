class ProductReceivingItem < ApplicationRecord
	belongs_to :product_receiving
	belongs_to :product
	belongs_to :purchase_order_supplier_item
	belongs_to :product_batch_number, optional: true
end
