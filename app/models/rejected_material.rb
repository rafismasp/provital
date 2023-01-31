class RejectedMaterial < ApplicationRecord
	belongs_to :material_outgoing	
	has_many :rejected_material_items
end
