class InvoiceSupplierItem < ApplicationRecord
	belongs_to :invoice_supplier
	belongs_to :purchase_order_supplier
	belongs_to :purchase_order_supplier_item
	belongs_to :material_receiving, optional: true
	belongs_to :material_receiving_item, optional: true
	belongs_to :material, optional: true
	belongs_to :product_receiving, optional: true
	belongs_to :product_receiving_item, optional: true
	belongs_to :product, optional: true
	belongs_to :general_receiving, optional: true
	belongs_to :general_receiving_item, optional: true
	belongs_to :general, optional: true
	belongs_to :consumable_receiving, optional: true
	belongs_to :consumable_receiving_item, optional: true
	belongs_to :consumable, optional: true
	belongs_to :equipment_receiving, optional: true
	belongs_to :equipment_receiving_item, optional: true
	belongs_to :equipment, optional: true
end
