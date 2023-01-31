class TemporaryInventoryLog < ApplicationRecord
	belongs_to :company_profile
	belongs_to :material_return_item, optional: true


  def document_transaction(kind)
    result = nil
    if self.material_return_item.present?
      result = self.material_return_item.material_return  
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["#{kind}"]
  end

  def document_transaction_item(kind)
    result = nil
    if self.material_return_item.present?
      result = self.material_return_item
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["#{kind}"]
  end

  def product_batch_number
    result = nil

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["number"]
  end
  def material_batch_number
    result = nil
    if self.material_return_item.present?
      result = self.material_return_item.material_batch_number
    end

    if result.blank?
      result = "id #{self.id} Not Defined"
    end
    return result["number"]
  end
end
