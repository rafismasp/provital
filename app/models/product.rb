class Product < ApplicationRecord
	validates :part_id, uniqueness: { scope: :company_profile_id, message: "code cannot be duplicate" }

	scope :only_sterilization, -> { where("product_item_category_id = 3") }
	scope :is_not_sterilization, -> { where("product_item_category_id != 3") }

	belongs_to :company_profile
	belongs_to :unit
	belongs_to :color, optional: true
	belongs_to :product_category
	belongs_to :product_sub_category
	belongs_to :product_type
	belongs_to :customer, optional: true

	has_many :sales_order_items

	def current_stock(company_profile_id, periode)
		logger.info "periode: #{periode}"
		period_selected = "#{periode.present? ? periode : DateTime.now().strftime("%Y%m")}"
		# stok berdasarkan Periode dan Produk
		inventory = Inventory.find_by(:company_profile_id=> company_profile_id, :periode=> period_selected, :product_id=> self.id)
		if inventory.present?
			result = inventory.end_stock
		else
			result = 0
		end
		return result
	end
	def current_stock_batch_number(company_profile_id, product_batch_number_id, periode)
		logger.info "periode: #{periode}"
		period_selected = "#{periode.present? ? periode : DateTime.now().strftime("%Y%m")}"
		# stok berdasarkan Periode dan Produk dan Batch Number
		inventory = InventoryBatchNumber.find_by(:company_profile_id=> company_profile_id, :periode=> period_selected, :product_batch_number_id=> product_batch_number_id)
		if inventory.present?
			result = inventory.end_stock
		else
			result = 0
		end
		return result
	end

	def unit_name
		return (self.unit.present? ? self.unit.name : "")
	end
	def type_name
		return (self.product_type.present? ? self.product_type.name : "")
	end

	def sterilization
		return (self.product_item_category_id == 3 ? true : false)
	end
end
