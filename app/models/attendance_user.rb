class AttendanceUser < ActiveRecord::Base
	belongs_to :employee
	belongs_to :department
end
