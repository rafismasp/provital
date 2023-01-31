class InvoiceCustomerItem < ApplicationRecord
	belongs_to :invoice_customer
	belongs_to :sales_order_item
	belongs_to :delivery_order_item
	belongs_to :product_batch_number
	belongs_to :product

	has_many :invoice_customer_price_logs
end
