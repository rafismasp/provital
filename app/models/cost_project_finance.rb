class CostProjectFinance < ApplicationRecord
	belongs_to :company_profile
	belongs_to :customer
	belongs_to :sales_order

	has_many :cost_project_finance_prf_items, -> { where status: 'active' }
	has_many :cost_project_finance_po_items, -> { where status: 'active' }

	def po_supplier_number
		self.cost_project_finance_po_items.group(:purchase_order_supplier_id).map { |e| e.purchase_order_supplier.number }.join(", ")
	end
end