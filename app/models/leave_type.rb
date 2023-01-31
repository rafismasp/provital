class LeaveType < ApplicationRecord
	has_many :employee_time_off_request
end
