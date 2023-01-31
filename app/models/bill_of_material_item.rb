class BillOfMaterialItem < ApplicationRecord
	belongs_to :bill_of_material
	belongs_to :material
end
