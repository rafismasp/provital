class SemiFinishGoodReceivingItem < ApplicationRecord
	belongs_to :semi_finish_good_receiving
	belongs_to :product_batch_number
	belongs_to :product
end
