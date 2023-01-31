class InvoiceCustomerPriceLog < ApplicationRecord
	extend OrderAsSpecified
	belongs_to :invoice_customer
	belongs_to :invoice_customer_item

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved, :class_name => "User", foreign_key: "approved_by", optional: true

end
