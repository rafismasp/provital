class EmployeePresence < ApplicationRecord
	belongs_to :employee
	belongs_to :employee_schedules, optional: true
	
end
