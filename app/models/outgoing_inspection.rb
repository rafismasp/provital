class OutgoingInspection < ApplicationRecord
	extend OrderAsSpecified
	belongs_to :customer
	belongs_to :picking_slip	
	
	has_many :outgoing_inspection_items
	
	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
end
