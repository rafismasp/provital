class InvoiceSupplierReceivingItem < ApplicationRecord
	belongs_to :invoice_supplier_receiving
	belongs_to :currency
	belongs_to :tax_rate
end
