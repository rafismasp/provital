class ProductType < ApplicationRecord
	belongs_to :product_sub_category
	belongs_to :customer, optional: true
end
