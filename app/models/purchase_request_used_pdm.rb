class PurchaseRequestUsedPdm < ApplicationRecord
	belongs_to :purchase_request_item, optional: true
	belongs_to :pdm_item, optional: true
end
