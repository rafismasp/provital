class MaterialCheckSheet < ApplicationRecord
  extend OrderAsSpecified
  
	belongs_to :supplier 
	belongs_to :material
	belongs_to :unit
	belongs_to :material_batch_number 
	belongs_to :material_receiving 
	belongs_to :material_receiving_item

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true
	belongs_to :printed, :class_name => "User", foreign_key: "printed_by", optional: true

	before_save :update_outstanding

	private
		def update_outstanding
			if self.status != self.status_was 
				case self.status
				when 'approved3' 
					self.material_receiving_item.update_columns(:material_check_sheet_outstanding=> 0)
				when 'canceled3', 'void'
					self.material_receiving_item.update_columns(:material_check_sheet_outstanding=> self.material_receiving_item.quantity)

				end
			end

		end
end
