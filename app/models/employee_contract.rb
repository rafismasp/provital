class EmployeeContract < ApplicationRecord
	belongs_to :employee
	belongs_to :department
	belongs_to :position
	belongs_to :work_status


	belongs_to :creator, :class_name => "User", foreign_key: "created_by", optional: true
end
