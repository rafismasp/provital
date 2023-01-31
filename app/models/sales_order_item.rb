class SalesOrderItem < ApplicationRecord
	belongs_to :sales_order
	belongs_to :product

	has_many :production_order_items, -> { where status: 'active' }
	has_many :delivery_order_items, -> { where status: 'active' }


	def summary_qty_delivery(company_profile_id)
		delivery_order_items = DeliveryOrderItem.where(:status=> 'active', :sales_order_item_id=> self.id).includes(:delivery_order).where(:delivery_orders => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("delivery_orders.number desc")
		if delivery_order_items.present?
			result = delivery_order_items.sum(:quantity)
		else
			result = 0
		end
		return result
	end
	def summary_sterilization_product_receivings
		sterilization_product_receivings_items = SterilizationProductReceivingItem.where(:status=> 'active', :sales_order_item_id=> self.id).includes(:sterilization_product_receiving).where(:sterilization_product_receivings => {:status=> 'approved3' }).order("sterilization_product_receivings.number desc")
		if sterilization_product_receivings_items.present?
			result = sterilization_product_receivings_items.sum(:quantity)
		else
			result = 0
		end
		return result
	end
	def outstanding_sterilization_product_receivings
		result = self.quantity - self.summary_sterilization_product_receivings
		return result
	end

	def is_outstanding_spr?
		# spr = sterilization product receivings
		outstanding_sterilization_product_receivings > 0
	end
end
