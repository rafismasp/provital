class SemiFinishGoodOutgoingItem < ApplicationRecord
	belongs_to :semi_finish_good_outgoing
	belongs_to :product_batch_number
	belongs_to :product
end
