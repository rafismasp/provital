class PurchaseOrderSupplierItem < ApplicationRecord
	extend OrderAsSpecified
	has_many :material_receiving_items, -> { where status: 'active' }
	has_many :product_receiving_items, -> { where status: 'active' }
	has_many :consumable_receiving_items, -> { where status: 'active' }
	has_many :equipment_receiving_items, -> { where status: 'active' }
	has_many :general_receiving_items, -> { where status: 'active' }


	belongs_to :purchase_order_supplier
	belongs_to :purchase_request_item, optional: true
	belongs_to :pdm_item, optional: true

  before_save :update_outstanding

	def so_selected
		number = []
		self.purchase_request_item.production_order_used_prves.each do |detail|
			number << {
				:so_number=> detail.production_order_item.sales_order_item.sales_order.number,
				:so_id=> detail.production_order_item.sales_order_item.sales_order_id
			}
		end
		return number.uniq
	end

	def total_price
		self.quantity*self.unit_price
	end

  private
  	def update_outstanding
  		# 2022-07-19
  		
  		outstanding_qty = self.quantity
  		self.material_receiving_items.each do |grn_item|
  			outstanding_qty -= grn_item.quantity if grn_item.material_receiving.present? and grn_item.material_receiving.status == 'approved3'
  		end if self.material_receiving_items.present?
  		self.product_receiving_items.each do |grn_item|
  			outstanding_qty -= grn_item.quantity if grn_item.product_receiving.present? and grn_item.product_receiving.status == 'approved3'
  		end if self.product_receiving_items.present?
  		self.consumable_receiving_items.each do |grn_item|
  			outstanding_qty -= grn_item.quantity if grn_item.consumable_receiving.present? and grn_item.consumable_receiving.status == 'approved3'
  		end if self.consumable_receiving_items.present?
  		self.equipment_receiving_items.each do |grn_item|
  			outstanding_qty -= grn_item.quantity if grn_item.equipment_receiving.present? and grn_item.equipment_receiving.status == 'approved3'
  		end if self.equipment_receiving_items.present?
  		self.general_receiving_items.each do |grn_item|
  			outstanding_qty -= grn_item.quantity if grn_item.general_receiving.present? and grn_item.general_receiving.status == 'approved3'
  		end if self.general_receiving_items.present?

  		self.outstanding = outstanding_qty
  	end
end
