class InternalTransferItem < ApplicationRecord
	belongs_to :internal_transfer
	belongs_to :product, optional: true
	belongs_to :material, optional: true
end
