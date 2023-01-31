class EmployeeAbsence < ApplicationRecord
	belongs_to :employee
	belongs_to :employee_absence_type
	belongs_to :position, optional: true
	belongs_to :creator, :class_name => "User", foreign_key: "created_by", optional: true

  belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
  belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
  belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
  belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true
  belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
  belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
  belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
  belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true

  belongs_to :voided, :class_name => "User", foreign_key: "deleted_by", optional: true
end
