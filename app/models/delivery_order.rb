class DeliveryOrder < ApplicationRecord
	extend OrderAsSpecified
	validates :number, uniqueness: { scope: :company_profile_id, message: "cannot be duplicate" }
	
	belongs_to :company_profile
	belongs_to :customer
	belongs_to :sales_order
	belongs_to :picking_slip
	belongs_to :invoice_customer, optional: true
	belongs_to :vehicle_inspection, optional: true

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true
	belongs_to :printed, :class_name => "User", foreign_key: "printed_by", optional: true

end
