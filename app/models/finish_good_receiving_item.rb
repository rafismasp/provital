class FinishGoodReceivingItem < ApplicationRecord
	belongs_to :finish_good_receiving
	belongs_to :product_batch_number
	belongs_to :product
end
