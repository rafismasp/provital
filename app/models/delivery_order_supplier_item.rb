class DeliveryOrderSupplierItem < ApplicationRecord
	belongs_to :delivery_order_supplier
	belongs_to :material
	belongs_to :material_batch_number
end
