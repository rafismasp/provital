class ProductBatchNumber < ApplicationRecord
	belongs_to :company_profile
	belongs_to :sterilization_product_receiving_item, optional: true
	belongs_to :product_receiving_item, optional: true
	belongs_to :shop_floor_order_item, optional: true

	belongs_to :product
  before_save :update_outstanding

	def document_production(field)
		case field
		when "number", "date", "id", "approved3_at"
			if self.shop_floor_order_item.present?
				return self.shop_floor_order_item.shop_floor_order["#{field}"]
			elsif self.sterilization_product_receiving_item.present?
				return self.sterilization_product_receiving_item.sterilization_product_receiving["#{field}"]
			end
		when "quantity"
			if self.shop_floor_order_item.present?
				return self.shop_floor_order_item["#{field}"]
			elsif self.sterilization_product_receiving_item.present?
				return self.sterilization_product_receiving_item["#{field}"]
			end
		else
			return "Not Found"
		end
	end
	# new: 2021-10-29
	def sterilization_product_receiving(company_profile_id)
		# .group("shop_floor_order_sterilization_items.shop_floor_order_sterilization_id")
		return SterilizationProductReceivingItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:sterilization_product_receiving).where(:sterilization_product_receivings => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("sterilization_product_receivings.number desc")
	end

	# 2021-04-05 disabled group
	def sterilization_process(company_profile_id)
		# .group("shop_floor_order_sterilization_items.shop_floor_order_sterilization_id")
		return ShopFloorOrderSterilizationItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:shop_floor_order_sterilization).where(:shop_floor_order_sterilizations => {:company_profile_id => company_profile_id, :status=> 'approved3', :kind=> 'internal' }).order("shop_floor_order_sterilizations.number desc")
	end
	def sterilization_ext_process(company_profile_id)
		# .group("shop_floor_order_sterilization_items.shop_floor_order_sterilization_id")
		return ShopFloorOrderSterilizationItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:shop_floor_order_sterilization).where(:shop_floor_order_sterilizations => {:company_profile_id => company_profile_id, :status=> 'approved3', :kind=> 'external' }).order("shop_floor_order_sterilizations.number desc")
	end

	def semifg_receiving_process(company_profile_id)
		# .group("semi_finish_good_receiving_items.semi_finish_good_receiving_id")
		return SemiFinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:semi_finish_good_receiving).where(:semi_finish_good_receivings => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("semi_finish_good_receivings.number desc")
	end
	def semifg_outgoing_process(company_profile_id)
		# group("semi_finish_good_outgoing_items.semi_finish_good_outgoing_id")
		return SemiFinishGoodOutgoingItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:semi_finish_good_outgoing).where(:semi_finish_good_outgoings => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("semi_finish_good_outgoings.number desc")
	end
	def fg_receiving_process(company_profile_id)
		# .group("finish_good_receiving_items.finish_good_receiving_id")
		return FinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:finish_good_receiving).where(:finish_good_receivings => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("finish_good_receivings.number desc")
	end
	def picking_process(company_profile_id)
		# .group("picking_slip_items.picking_slip_id")
		return PickingSlipItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:picking_slip).where(:picking_slips => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("picking_slips.number desc")
	end
	def delivery_process(company_profile_id)
		# .group("delivery_order_items.delivery_order_id")
		return DeliveryOrderItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:delivery_order).where(:delivery_orders => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("delivery_orders.number desc")
	end
	def adj_process(company_profile_id)
		# .group("delivery_order_items.delivery_order_id")
		return InventoryAdjustmentItem.where(:status=> 'active', :product_batch_number_id=> self.id).includes(:inventory_adjustment).where(:inventory_adjustments => {:company_profile_id => company_profile_id, :status=> 'approved3' }).order("inventory_adjustments.number desc")
	end


	private

		def calc_outstanding_sterilization(qty_order)
			if qty_order > 0
				results = qty_order
				SemiFinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> self.id)
				.includes(:semi_finish_good_receiving)
				.where(:semi_finish_good_receivings => {:company_profile_id => self.company_profile_id, :status=> 'approved3' }).each do |item|
					results -= item.quantity
				end
			else
				results = 0
			end
			return results
		end
		def calc_outstanding_sterilization_out(qty_order)
			if qty_order > 0
				results = qty_order
				SemiFinishGoodOutgoingItem.where(:status=> 'active', :product_batch_number_id=> self.id)
				.includes(:semi_finish_good_outgoing)
				.where(:semi_finish_good_outgoings => {:company_profile_id => self.company_profile_id, :status=> 'approved3' }).each do |item|
					results -= item.quantity
				end
			else
				results = 0
			end
			return results
		end
		def calc_outstanding(qty_order, product_sterilization_status, outstanding_str_out)
			case product_sterilization_status
			when 'Yes'
				# yg sudah dibuatkan SFS
				results = qty_order.to_f - outstanding_str_out.to_f
			when 'No'
				results = qty_order
			end

			FinishGoodReceivingItem.where(:status=> 'active', :product_batch_number_id=> self.id)
			.includes(:finish_good_receiving)
			.where(:finish_good_receivings => {:company_profile_id => self.company_profile_id, :status=> 'approved3' }).each do |item|
				results -= item.quantity
			end
			return results
		end
		def calc_outstanding_picking_slip(qty_order)
			results = qty_order
			PickingSlipItem.where(:status=> 'active', :product_batch_number_id=> self.id)
			.includes(:picking_slip)
			.where(:picking_slips => {:company_profile_id => self.company_profile_id, :status=> ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3'] }).each do |item|
				results -= item.quantity
			end
			return results
		end

	  def update_outstanding
      if self.product.present? and self.product.sterilization
      	product_sterilization = "Yes"
      else
      	product_sterilization = "No"      	
      end

      sfo_item  = self.shop_floor_order_item
      spr_item  = self.sterilization_product_receiving_item

      qty_order = 0
      sfo_quantity_for_str     = 0
      sfo_quantity_for_str_out = 0

      if sfo_item.present?
      	qty_order = sfo_item.quantity
      	sfo_quantity_for_str 		 = qty_order if product_sterilization == "Yes"
      	sfo_quantity_for_str_out = qty_order if product_sterilization == "Yes"
      elsif spr_item.present?
      	qty_order = spr_item.quantity
      	sfo_quantity_for_str_out = qty_order if product_sterilization == "Yes"
      	# SPR tanpa dibuatkan Semi FG receiving (sfo_quantity_for_str)
      end

      result_outstanding_str = calc_outstanding_sterilization(sfo_quantity_for_str)
      outstanding_str_out    = calc_outstanding_sterilization_out(sfo_quantity_for_str_out)
      outstanding_fg         = calc_outstanding(qty_order, product_sterilization, outstanding_str_out)
      outstanding_ps         = qty_order.to_f - outstanding_fg.to_f

      self.outstanding_direct_labor			 = result_outstanding_str
	    self.outstanding_sterilization 		 = result_outstanding_str
	    self.outstanding_sterilization_out = outstanding_str_out
	    self.outstanding 									 = outstanding_fg
	    self.outstanding_picking_slip			 = calc_outstanding_picking_slip(outstanding_ps)
		end
end
