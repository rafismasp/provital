class InvoiceSupplier < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id, :supplier_id], message: "cannot be duplicate per supplier" }
	belongs_to :company_profile
	belongs_to :supplier
	belongs_to :tax_rate
	belongs_to :supplier_tax_invoice, optional: true
	belongs_to :payment_request_supplier, optional: true
	belongs_to :tax
	belongs_to :term_of_payment
	belongs_to :currency
	has_many :invoice_supplier_items, -> { where status: 'active' }
	has_many :invoice_supplier_files, -> { where status: 'active' }
end
