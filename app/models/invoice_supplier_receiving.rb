class InvoiceSupplierReceiving < ApplicationRecord
	belongs_to :company_profile
	belongs_to :supplier
	
	def sum_total
		return InvoiceSupplierReceivingItem.where(:invoice_supplier_receiving_id=> self.id, :status=> 'active').sum(:total)
	end
end
