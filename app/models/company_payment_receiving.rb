class CompanyPaymentReceiving < ApplicationRecord
	belongs_to :company_profile
	belongs_to :currency
end
