class SupplierBank < ApplicationRecord
	belongs_to :supplier
	belongs_to :dom_bank
	belongs_to :currency
	belongs_to :country_code
end
