class CostProjectFinancePrfItem < ApplicationRecord
	belongs_to :cost_project_finance
	belongs_to :purchase_request, optional: true
	belongs_to :purchase_request_item, optional: true
	belongs_to :pdm, optional: true
	belongs_to :pdm_item, optional: true
end