class Material < ApplicationRecord
	validates :part_id, uniqueness: { scope: :company_profile_id, message: "code cannot be duplicate" }
	
	belongs_to :company_profile
	belongs_to :unit
	belongs_to :color, optional: true
	belongs_to :material_category


	def current_stock(company_profile_id, periode)
		logger.info "periode: #{periode}"
		period_selected = "#{periode.present? ? periode : DateTime.now().strftime("%Y%m")}"
		# stok berdasarkan Periode dan Produk
		inventory = Inventory.find_by(:company_profile_id=> company_profile_id, :periode=> period_selected, :material_id=> self.id)
		if inventory.present?
			result = inventory.end_stock
		else
			result = 0
		end
		return result
	end
	def current_stock_batch_number(company_profile_id, material_batch_number_id, periode)
		logger.info "periode: #{periode}"
		period_selected = "#{periode.present? ? periode : DateTime.now().strftime("%Y%m")}"
		# stok berdasarkan Periode dan Produk dan Batch Number
		inventory = InventoryBatchNumber.find_by(:company_profile_id=> company_profile_id, :periode=> period_selected, :material_batch_number_id=> material_batch_number_id)
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
end
