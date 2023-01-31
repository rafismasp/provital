class MaterialBatchNumber < ApplicationRecord
	belongs_to :company_profile
	belongs_to :material_receiving, optional: true
	belongs_to :material_receiving_item, optional: true
	belongs_to :material

	has_many :material_receiving_items, -> { where status: 'active' }

	def summary_material_check_sheet_outstanding
		qty = 0
		self.material_receiving_items.map { |e| qty+= e.material_check_sheet_outstanding  }
		return qty
	end

	def summary_material_receiving_quantity
		qty = 0
		self.material_receiving_items.map { |e| qty+= e.quantity  }
		return qty
	end
end
