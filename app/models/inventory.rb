class Inventory < ApplicationRecord
	belongs_to :company_profile
	belongs_to :product, optional: true
	belongs_to :material, optional: true
	belongs_to :general, optional: true
	belongs_to :consumable, optional: true
	belongs_to :equipment, optional: true

	scope :stock_products, -> { where("product_id > 0") }
	scope :stock_materials, -> { where("material_id > 0") }
	scope :stock_generals, -> { where("general_id > 0") }
	scope :stock_consumables, -> { where("consumable_id > 0") }
	scope :stock_equipments, -> { where("equipment_id > 0") }

  after_save :update_next_stock

	def stock_product_batch_numbers
	  return InventoryBatchNumber.where(:company_profile_id=> self.company_profile_id, :periode=> self.periode, :product_id=> self.product_id).order("product_batch_number_id asc")
	end
	def stock_material_batch_numbers
	  return InventoryBatchNumber.where(:company_profile_id=> self.company_profile_id, :periode=> self.periode, :material_id=> self.material_id).order("material_batch_number_id asc")
	end
	def stock_general_batch_numbers
	  return InventoryBatchNumber.where(:company_profile_id=> self.company_profile_id, :periode=> self.periode, :general_id=> self.general_id).order("general_batch_number_id asc")
	end
	def stock_consumable_batch_numbers
	  return InventoryBatchNumber.where(:company_profile_id=> self.company_profile_id, :periode=> self.periode, :consumable_id=> self.consumable_id).order("consumable_batch_number_id asc")
	end
	def stock_equipment_batch_numbers
	  return InventoryBatchNumber.where(:company_profile_id=> self.company_profile_id, :periode=> self.periode, :equipment_id=> self.equipment_id).order("equipment_batch_number_id asc")
	end

	def part(field)
		part = nil
		if self.product.present?
			part = self.product["#{field}"]
		elsif self.material.present?
			part = self.material["#{field}"]
		elsif self.general.present?
			part = self.general["#{field}"]
		elsif self.consumable.present?
			part = self.consumable["#{field}"]
		elsif self.equipment.present?
			part = self.equipment["#{field}"]
		end
		return part
	end

  private
	  def update_next_stock
	  	next_periode = ("#{self.periode}01".to_date+1.month).strftime("%Y%m")
	  	begin_stock = ((self.begin_stock.to_f+self.trans_in.to_f)-self.trans_out.to_f)
	  	if self.product.present?
	  		next_inventory = Inventory.find_by(:company_profile_id=> self.company_profile_id, :product_id=> self.product_id, :periode=> next_periode)
	  		if next_inventory.present?
	  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
	  			next_inventory.update({:begin_stock=> begin_stock, :end_stock=> end_stock})
	  		end
	  	elsif self.material.present?
	  		next_inventory = Inventory.find_by(:company_profile_id=> self.company_profile_id, :material_id=> self.material_id, :periode=> next_periode)
	  		if next_inventory.present?
	  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
	  			next_inventory.update({:begin_stock=> begin_stock, :end_stock=> end_stock})
	  		end
	  	elsif self.general.present?
	  		next_inventory = Inventory.find_by(:company_profile_id=> self.company_profile_id, :general_id=> self.general_id, :periode=> next_periode)
	  		if next_inventory.present?
	  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
	  			next_inventory.update({:begin_stock=> begin_stock, :end_stock=> end_stock})
	  		end
	  	elsif self.consumable.present?
	  		next_inventory = Inventory.find_by(:company_profile_id=> self.company_profile_id, :consumable_id=> self.consumable_id, :periode=> next_periode)
	  		if next_inventory.present?
	  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
	  			next_inventory.update({:begin_stock=> begin_stock, :end_stock=> end_stock})
	  		end
	  	elsif self.equipment.present?
	  		next_inventory = Inventory.find_by(:company_profile_id=> self.company_profile_id, :equipment_id=> self.equipment_id, :periode=> next_periode)
	  		if next_inventory.present?
	  			end_stock = ((begin_stock.to_f+next_inventory.trans_in.to_f)-next_inventory.trans_out.to_f)
	  			next_inventory.update({:begin_stock=> self.end_stock, :end_stock=> end_stock})
	  		end
	  	end
		end

end
