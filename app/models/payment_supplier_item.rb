class PaymentSupplierItem < ApplicationRecord
	belongs_to :payment_supplier
	belongs_to :invoice_supplier
	belongs_to :payment_request_supplier
	belongs_to :payment_request_supplier_item
	belongs_to :tax_rate, optional: true
end
