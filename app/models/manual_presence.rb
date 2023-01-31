class ManualPresence < ApplicationRecord
	belongs_to :manual_presence_period

	def account_name(account_id)
		account = User.find_by(:id=> account_id)
		account_name = "#{account.first_name if account.present?} #{account.last_name if account.present?}"
		return account_name
	end
	def employee(field)
		result = nil
		att_user = AttendanceUser.find_by(:company_profile_id=> self.company_profile_id, :id_number=> self.id_number)
		if att_user.present?
			employee = Employee.find_by(:id=> att_user.employee_id)
			result = employee["#{field}"] if employee.present?
		else
			result = "User tidak terdaftar"
		end
		return result
	end
end