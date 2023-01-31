class CostProjectFinancePoItem < ApplicationRecord
	belongs_to :cost_project_finance
	belongs_to :cost_project_finance_prf_item
	belongs_to :purchase_order_supplier, optional: true
	belongs_to :purchase_order_supplier_item, optional: true
end