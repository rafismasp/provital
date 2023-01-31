class EmployeeScheduleRecap < ActiveRecord::Base
	belongs_to :employee
	# belongs_to :schedule

	# def att_manual(kind, id_number, date, field)
	# 	result = nil
	# 	att_manual = AttManualPresence.find_by(:id_number=> id_number, :status=> 'approved', :date=> date, :type_presence=> kind)
	# 	result = att_manual["#{field}"] if att_manual.present?
	# 	return result
	# end
end