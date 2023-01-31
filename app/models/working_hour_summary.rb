class WorkingHourSummary < ApplicationRecord
	belongs_to :employee
	belongs_to :employee_schedules, optional: true
	belongs_to :department
	
end
