class GeneralBatchNumber < ApplicationRecord
	belongs_to :company_profile
	belongs_to :general_receiving, optional: true
	belongs_to :general_receiving_item, optional: true
	belongs_to :general
end
