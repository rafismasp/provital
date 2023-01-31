class PurchaseRequestItem < ApplicationRecord
	extend OrderAsSpecified
	has_many :production_order_used_prves
	has_many :purchase_order_supplier_items, -> { where status: 'active' }

	belongs_to :purchase_request
	belongs_to :product, optional: true
	belongs_to :material, optional: true
	belongs_to :consumable, optional: true
	belongs_to :equipment, optional: true
	belongs_to :general, optional: true

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
				:po_status=> po_item.purchase_order_supplier.status,
				:po_kind=> po_item.purchase_order_supplier.kind,
				:po_number=> po_item.purchase_order_supplier.number,
				:po_date=> po_item.purchase_order_supplier.date.strftime("%Y-%m-%d"),
				:unit_price=> po_item.unit_price,
				:quantity=> po_item.quantity,
			}
		end
		return result
	end
	def last_prf(lmit)
		result = []
		record_items = PurchaseRequestItem.where(:status=> 'active')
		.includes(:purchase_request)
		.where(:purchase_requests => {:company_profile_id=> self.purchase_request.company_profile_id})
		.order("purchase_requests.date desc")
		.limit(lmit)

		record_items = record_items.where(:product_id=> self.product_id) if self.product.present?
		record_items = record_items.where(:material_id=> self.material_id) if self.material.present?
		record_items = record_items.where(:consumable_id=> self.consumable_id) if self.consumable.present?
		record_items = record_items.where(:equipment_id=> self.equipment_id) if self.equipment.present?
		record_items = record_items.where(:general_id=> self.general_id) if self.general.present?
		record_items.each do |prf_item|
			result << {
				:prf_id=> prf_item.purchase_request_id,
				:basic_request=> prf_item.purchase_request.basic_request,
				:prf_status=> prf_item.purchase_request.status,
				:prf_kind=> prf_item.purchase_request.request_kind,
				:prf_number=> prf_item.purchase_request.number,
				:prf_date=> prf_item.purchase_request.date.strftime("%Y-%m-%d"),
				:quantity=> prf_item.quantity,
			}
		end
		return result
	end

	def last_price
		po_price = nil
		if self.product.present?
			po_price =	PurchaseOrderPrice.where(:company_profile_id=> self.purchase_request.company_profile_id, :product_id=> self.product_id, :status=> 'active')
		elsif self.material.present?
			po_price =	PurchaseOrderPrice.where(:company_profile_id=> self.purchase_request.company_profile_id, :material_id=> self.material_id, :status=> 'active')
		elsif self.consumable.present?
			po_price =	PurchaseOrderPrice.where(:company_profile_id=> self.purchase_request.company_profile_id, :consumable_id=> self.consumable_id, :status=> 'active')
		elsif self.equipment.present?
			po_price =	PurchaseOrderPrice.where(:company_profile_id=> self.purchase_request.company_profile_id, :equipment_id=> self.equipment_id, :status=> 'active')
		elsif self.general.present?
			po_price =	PurchaseOrderPrice.where(:company_profile_id=> self.purchase_request.company_profile_id, :general_id=> self.general_id, :status=> 'active')
		end
			
		if po_price.present?
			result = po_price.last.unit_price
		else
			result = 0
		end
		return result
	end
end
