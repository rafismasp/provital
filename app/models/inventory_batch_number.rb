class InventoryBatchNumber < ApplicationRecord
	belongs_to :company_profile
	belongs_to :product, optional: true
	belongs_to :product_batch_number, optional: true
	belongs_to :material, optional: true
	belongs_to :material_batch_number, optional: true	
	belongs_to :general, optional: true
	belongs_to :general_batch_number, optional: true	
	belongs_to :consumable, optional: true
	belongs_to :consumable_batch_number, optional: true	
	belongs_to :equipment, optional: true
	belongs_to :equipment_batch_number, optional: true	

  after_save :update_next_stock

  private
	  def update_next_stock
	  	next_periode = ("#{self.periode}01".to_date+1.month).strftime("%Y%m")
	  	begin_stock = ((self.begin_stock.to_f+self.trans_in.to_f)-self.trans_out.to_f)
	  	
	  	if next_periode <= DateTime.now.strftime("%Y%m")
		  	if self.product_batch_number.present?
		  		next_inventory = InventoryBatchNumber.find_by(:company_profile_id=> self.company_profile_id, :product_batch_number_id=> self.product_batch_number_id, :periode=> next_periode)
		  		if next_inventory.present?
		  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
		  			next_inventory.update({:product_id=> self.product_id, :begin_stock=> begin_stock, :end_stock=> end_stock})
		  		else
			  		next_inventory = InventoryBatchNumber.new({
			  			:company_profile_id=> self.company_profile_id, 
			  			:product_batch_number_id=> self.product_batch_number_id, 
			  			:product_id=> self.product_id,
			  			:periode=> next_periode,
			  			:begin_stock=> begin_stock,
			  			:trans_in=> 0, :trans_out=> 0,
			  			:end_stock=> begin_stock
			  		})
			  		next_inventory.save
		  		end
		  	elsif self.material_batch_number.present?
		  		next_inventory = InventoryBatchNumber.find_by(:company_profile_id=> self.company_profile_id, :material_batch_number_id=> self.material_batch_number_id, :periode=> next_periode)
		  		if next_inventory.present?
		  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
		  			next_inventory.update({:material_id=> self.material_id, :begin_stock=> begin_stock, :end_stock=> end_stock})
		  		else
			  		next_inventory = InventoryBatchNumber.new({
			  			:company_profile_id=> self.company_profile_id, 
			  			:material_batch_number_id=> self.material_batch_number_id, 
			  			:material_id=> self.material_id,
			  			:periode=> next_periode,
			  			:begin_stock=> begin_stock,
			  			:trans_in=> 0, :trans_out=> 0,
			  			:end_stock=> begin_stock
			  		})
			  		next_inventory.save
		  		end
		  	elsif self.general_batch_number.present?
		  		next_inventory = InventoryBatchNumber.find_by(:company_profile_id=> self.company_profile_id, :general_batch_number_id=> self.general_batch_number_id, :periode=> next_periode)
		  		if next_inventory.present?
		  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
		  			next_inventory.update({:begin_stock=> begin_stock, :end_stock=> end_stock})
		  		end
		  	elsif self.consumable_batch_number.present?
		  		next_inventory = InventoryBatchNumber.find_by(:company_profile_id=> self.company_profile_id, :consumable_batch_number_id=> self.consumable_batch_number_id, :periode=> next_periode)
		  		if next_inventory.present?
		  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
		  			next_inventory.update({:consumable_id=> self.consumable_id, :begin_stock=> begin_stock, :end_stock=> end_stock})
		  		else
			  		next_inventory = InventoryBatchNumber.new({
			  			:company_profile_id=> self.company_profile_id, 
			  			:consumable_batch_number_id=> self.consumable_batch_number_id, 
			  			:consumable_id=> self.consumable_id,
			  			:periode=> next_periode,
			  			:begin_stock=> begin_stock,
			  			:trans_in=> 0, :trans_out=> 0,
			  			:end_stock=> begin_stock
			  		})
			  		next_inventory.save
		  		end
		  	elsif self.equipment_batch_number.present?
		  		next_inventory = InventoryBatchNumber.find_by(:company_profile_id=> self.company_profile_id, :equipment_batch_number_id=> self.equipment_batch_number_id, :periode=> next_periode)
		  		if next_inventory.present?
		  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
		  			next_inventory.update({:equipment_id=> self.equipment_id, :begin_stock=> begin_stock, :end_stock=> end_stock})
		  		else
			  		next_inventory = InventoryBatchNumber.new({
			  			:company_profile_id=> self.company_profile_id, 
			  			:equipment_batch_number_id=> self.equipment_batch_number_id, 
			  			:equipment_id=> self.equipment_id,
			  			:periode=> next_periode,
			  			:begin_stock=> begin_stock,
			  			:trans_in=> 0, :trans_out=> 0,
			  			:end_stock=> begin_stock
			  		})
			  		next_inventory.save
		  		end
		  	end
		  end
		end
end