class PdmItem < ApplicationRecord
	belongs_to :pdm
	belongs_to :material
	has_many :purchase_order_supplier_items, -> { where status: 'active' }

	def last_po(lmit)
		result = []
		self.purchase_order_supplier_items
		.includes(:purchase_order_supplier)
		.where("purchase_order_suppliers.status = ?", 'approved3')
		.order("purchase_order_suppliers.date desc")
		.limit(lmit)
		.each do |po_item|
			result << {
				:po_id=> po_item.purchase_order_supplier_id,
				:po_kind=> po_item.purchase_order_supplier.kind,
				:po_number=> po_item.purchase_order_supplier.number,
				:po_date=> po_item.purchase_order_supplier.date.strftime("%Y-%m-%d"),
				:unit_price=> po_item.unit_price,
				:quantity=> po_item.quantity,
			}
		end
		return result
	end
	
	def last_price
		po_price =	PurchaseOrderPrice.where(:company_profile_id=> self.pdm.company_profile_id, :material_id=> self.material_id, :status=> 'active')
			
		if po_price.present?
			result = po_price.last.unit_price
		else
			result = 0
		end
		return result
	end
end
