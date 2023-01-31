class InventoryLog < ApplicationRecord
	belongs_to :company_profile
  belongs_to :internal_transfer_item, optional: true
	belongs_to :inventory_adjustment_item, optional: true
	belongs_to :delivery_order_item, optional: true
	belongs_to :material_outgoing_item, optional: true
  belongs_to :material_receiving_item, optional: true
  belongs_to :material_return_item, optional: true
	belongs_to :material_additional_item, optional: true
	belongs_to :sterilization_product_receiving_item, optional: true
	belongs_to :finish_good_receiving_item, optional: true
	belongs_to :semi_finish_good_receiving_item, optional: true
  belongs_to :semi_finish_good_outgoing_item, optional: true
  belongs_to :product_receiving_item, optional: true
  belongs_to :delivery_order_supplier_item, optional: true
  belongs_to :general_receiving_item, optional: true
  belongs_to :consumable_receiving_item, optional: true
	belongs_to :equipment_receiving_item, optional: true

  def document_transaction(kind)
    result = nil
    if self.sterilization_product_receiving_item.present?
      result = self.sterilization_product_receiving_item.sterilization_product_receiving
    elsif self.inventory_adjustment_item.present?
      result = self.inventory_adjustment_item.inventory_adjustment
    elsif self.material_outgoing_item.present?
      result = self.material_outgoing_item.material_outgoing
    elsif self.material_receiving_item.present?
      result = self.material_receiving_item.material_receiving
    elsif self.material_return_item.present?
      result = self.material_return_item.material_return
    elsif self.material_additional_item.present?
      result = self.material_additional_item.material_additional
    elsif self.semi_finish_good_outgoing_item.present?
      result = self.semi_finish_good_outgoing_item.semi_finish_good_outgoing
    elsif self.semi_finish_good_receiving_item.present?
      result = self.semi_finish_good_receiving_item.semi_finish_good_receiving
    elsif self.finish_good_receiving_item.present?
      result = self.finish_good_receiving_item.finish_good_receiving
    elsif self.internal_transfer_item.present?
      result = self.internal_transfer_item.internal_transfer
    elsif self.delivery_order_item.present?
      result = self.delivery_order_item.delivery_order
    elsif self.product_receiving_item.present?
      result = self.product_receiving_item.product_receiving
    elsif self.delivery_order_supplier_item.present?
      result = self.delivery_order_supplier_item.delivery_order_supplier
    elsif self.general_receiving_item.present?
      result = self.general_receiving_item.general_receiving
    elsif self.consumable_receiving_item.present?
      result = self.consumable_receiving_item.consumable_receiving
    elsif self.equipment_receiving_item.present?
      result = self.equipment_receiving_item.equipment_receiving
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["#{kind}"]
  end

  def document_transaction_item(kind)
    result = nil
    if self.sterilization_product_receiving_item.present?
      result = self.sterilization_product_receiving_item
    elsif self.inventory_adjustment_item.present?
      result = self.inventory_adjustment_item
    elsif self.material_outgoing_item.present?
      result = self.material_outgoing_item
    elsif self.material_receiving_item.present?
      result = self.material_receiving_item
    elsif self.material_return_item.present?
      result = self.material_return_item
    elsif self.material_additional_item.present?
      result = self.material_additional_item
    elsif self.semi_finish_good_outgoing_item.present?
      result = self.semi_finish_good_outgoing_item
    elsif self.semi_finish_good_receiving_item.present?
      result = self.semi_finish_good_receiving_item
    elsif self.finish_good_receiving_item.present?
      result = self.finish_good_receiving_item
    elsif self.internal_transfer_item.present?
      result = self.internal_transfer_item
    elsif self.delivery_order_item.present?
      result = self.delivery_order_item
    elsif self.product_receiving_item.present?
      result = self.product_receiving_item
    elsif self.delivery_order_supplier_item.present?
      result = self.delivery_order_supplier_item
    elsif self.general_receiving_item.present?
      result = self.general_receiving_item
    elsif self.consumable_receiving_item.present?
      result = self.consumable_receiving_item
    elsif self.equipment_receiving_item.present?
      result = self.equipment_receiving_item
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["#{kind}"]
  end

  def product_batch_number
    result = nil
    if self.sterilization_product_receiving_item.present?
      result = self.sterilization_product_receiving_item.product_batch_number
    elsif self.inventory_adjustment_item.present?
      result = self.inventory_adjustment_item.product_batch_number
    elsif self.material_outgoing_item.present?
      result = self.material_outgoing_item.product_batch_number
    elsif self.material_receiving_item.present?
      result = self.material_receiving_item.product_batch_number
    elsif self.semi_finish_good_outgoing_item.present?
      result = self.semi_finish_good_outgoing_item.product_batch_number
    elsif self.semi_finish_good_receiving_item.present?
      result = self.semi_finish_good_receiving_item.product_batch_number
    elsif self.finish_good_receiving_item.present?
      result = self.finish_good_receiving_item.product_batch_number
    elsif self.internal_transfer_item.present?
      result = self.internal_transfer_item.product_batch_number
    elsif self.delivery_order_item.present?
      result = self.delivery_order_item.product_batch_number
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["number"]
  end
  def material_batch_number
    result = nil
    if self.delivery_order_supplier_item.present?
      result = self.delivery_order_supplier_item.material_batch_number
    elsif self.material_outgoing_item.present?
      result = self.material_outgoing_item.material_batch_number
    elsif self.material_receiving_item.present?
      result = self.material_receiving_item.material_batch_number
    elsif self.material_return_item.present?
      result = self.material_return_item.material_batch_number
    elsif self.material_additional_item.present?
      result = self.material_additional_item.material_batch_number
    elsif self.inventory_adjustment_item.present?
      result = self.inventory_adjustment_item.material_batch_number
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["number"]
  end
end
