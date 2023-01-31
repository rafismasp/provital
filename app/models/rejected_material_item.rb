class RejectedMaterialItem < ApplicationRecord
	belongs_to :rejected_material
	belongs_to :material_outgoing_item
end
