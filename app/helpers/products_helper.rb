module ProductsHelper

	def product_code(category_id, sub_category_id, type_id)
		
		category = ProductCategory.find_by(:id=> category_id)
		category_code = (category.present? ? category.code : "X")
		sub_category = ProductSubCategory.find_by(:id=> sub_category_id)
		sub_category_code = (sub_category.present? ? sub_category.code : "X")
		type = ProductType.find_by(:id=> type_id)
		type_code = (type.present? ? type.code : "X")

		return "#{category_code}#{sub_category_code}#{type_code}"
	end
end
