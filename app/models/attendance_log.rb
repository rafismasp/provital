class AttendanceLog < ApplicationRecord
	belongs_to :employee
	# belongs_to :sys_plant, :foreign_key => "sys_plant_id", :class_name => "HrdEmployeeAttendanceLocation"
end
