class PickingSlip < ApplicationRecord
	extend OrderAsSpecified
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	
	belongs_to :company_profile
	belongs_to :customer
	belongs_to :sales_order
	belongs_to :outgoing_inspection, optional: true

	scope :outgoing_inspection_hold, -> () {
		 	where(:status=> 'approved3').where("outstanding > 0").joins(:outgoing_inspection).where('outgoing_inspections.conclusion' => "Hold") 
		}
	scope :outgoing_inspection_released, -> () {
		 	where(:status=> 'approved3').where("outstanding > 0").joins(:outgoing_inspection).where('outgoing_inspections.conclusion' => ["Released","Released With Notes"]) 
		}

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true	
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true	
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true	
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true	
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true	
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true	
	belongs_to :voided, :class_name => "User", foreign_key: "voided_by", optional: true	
	
end
