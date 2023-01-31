class EmployeeTimeOffRequest < ApplicationRecord
	belongs_to :employee
	belongs_to :department
	belongs_to :leave_type
end
