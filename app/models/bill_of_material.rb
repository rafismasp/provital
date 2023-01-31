class BillOfMaterial < ApplicationRecord
	validates :product_id, uniqueness: { scope: :company_profile_id, message: "Product already exist" }
	has_many :bill_of_material_items

	belongs_to :company_profile
	belongs_to :product

	belongs_to :product_wip1, :class_name => "Product", foreign_key: "product_wip1_id", optional: true
	belongs_to :product_wip2, :class_name => "Product", foreign_key: "product_wip2_id", optional: true
end
