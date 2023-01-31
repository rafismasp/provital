class Equipment < ApplicationRecord
	validates :part_id, uniqueness: { scope: :company_profile_id, message: "code cannot be duplicate" }

	belongs_to :company_profile
	belongs_to :unit
	belongs_to :color
	def unit_name
		return (self.unit.present? ? self.unit.name : "")
	end
end
