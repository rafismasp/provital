class Employee < ApplicationRecord
  include EmployeePresenceHelper
	mount_uploader :image, ImageUploader
	belongs_to :company_profile

	belongs_to :department
	belongs_to :position
	belongs_to :work_status

	def legality_name
		case self.employee_legal_id
		when 1
			"Provital"
		when 2
			"Techno"
		when 3
			"TSSI"
		end
	end

	def working_hour(begin_period, end_period)
		count_hour = 0
		EmployeeSchedule.where(:company_profile_id=> self.division, :employee_id=> self.id, :status=> 'active').where("date between ? and ?", begin_period, end_period).order("date asc").each do |record|
			case record.schedule.code 
			when 'L','I','S','A'
			else
				AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|		
					day_name = "#{record.date.strftime('%A')}".downcase
	        schedule_time_in  = record.schedule["#{day_name}_in"]
	        schedule_time_out = record.schedule["#{day_name}_out"]		
	        diff_time = get_working_hour(att_user.company_profile_id, att_user.id_number, record.date, schedule_time_in, schedule_time_out, record.schedule.code) if att_user.present?
	        # diff_time = get_working_hour(self.hrd_employee_payroll_id, att_user.id_number, record.date, schedule_time_in, schedule_time_out, record.hrd_schedule.code) if att_user.present?
	        # puts "#{diff_time}"
	        count_hour += diff_time if diff_time.present?
	     	end
			end if record.schedule.present?
		end

		# puts "#{begin_period} sd #{end_period} => working_hour #{count_hour}"
		return count_hour
	end

	def working_weekday(att_log_array, schedule, begin_period, end_period)
		a = DateTime.now()

		# hari kerja berdasarkan schedule
		id_number = nil
		count = 0
		day = 0 
		libur = 0

    count_arr = 0
    att_log_array.each do |x|
      count_arr += 1
    end
    
    att_new = []
    (0..count_arr).each do |c|
          
      if att_log_array[c+1].present?
        if att_log_array[c][:type_presence] == 'in' and att_log_array[c+1][:type_presence] == 'out'
          att_new << { :period_shift=> att_log_array[c][:period_shift] } unless att_new.include?( {:period_shift=> att_log_array[c][:period_shift]} )
          # puts "[#{att_log_array[c][:period_shift]}] => IN: #{datetime_in}; OUT: #{datetime_out};"
          # puts "1 [#{att_log_array[c][:period_shift]}] #{att_log_array[c][:tr_date]} - in: #{datetime_in}; out: #{datetime_out}"
        end  
      end
    end
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)	
		EmployeeSchedule.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').where("date between ? and ?", begin_period, end_period).order("date asc").each do |record|
      schedule.each do |schedule|
      	if schedule[:id].to_i == record.schedule_id.to_i
      		puts record.date.to_date
      		case schedule[:code] 
					when 'L','I','S','22','A'
						libur  += 1
						# puts "   -> libur"
					else
						att_new.each do |att|
							if att[:period_shift].to_date == record.date.to_date
								count += 1
								# puts "   -> kerja"
								# puts att[:period_shift]
							end
						end
					end
      	end
      end
      day += 1
		end

		# puts "libur : #{libur} / #{day}"
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => working_weekday; libur : #{libur} / #{day} = #{count} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count
	end

	def working_weekend(begin_period, end_period)
		# masuk hari minggu
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		count = 0
		a = DateTime.now()
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			diff_time = get_working_day(att_user.company_profile_id, att_user.employee_id, self.work_schedule, att_user.id_number, 'weekend', begin_period, end_period) if att_user.present?
			count += diff_time if diff_time.present?
			# count = get_working_day(self.hrd_employee_payroll_id, att_user.id_number, 'weekend', begin_period, end_period) if att_user.present?
			# puts "#{begin_period} sd #{end_period} => working_weekend: #{count}"
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => working_weekend: #{count} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count
	end

	def working_off_day(hrd_holiday, employee_schedule_array, begin_period, end_period)
		# masuk pada schedule libur
		a = DateTime.now()
		counter = 0

		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			AttendanceLog.where(:company_profile_id=> att_user.company_profile_id, :employee_id=> self.id, :type_presence=> 'in').where("date between ? and ?", begin_period, end_period).each do |att_log|
				employee_schedule_array.each do |employee_schedule|
					if att_log.date.to_date == employee_schedule[:period_shift].to_date
						hrd_holiday.each do |holiday_date|
							if holiday_date[:date].to_date == employee_schedule[:period_shift].to_date or employee_schedule[:schedule_code] == "L"
								counter += 1
							end
						end
					end
				end
			end

			# HrdAttendanceLog.where(:sys_plant_id=> att_user.sys_plant_id, :hrd_employee_id=> att_user.hrd_employee_id, :type_presence=> 'in').where("date between ? and ?", begin_period, end_period).each do |record|
			# 	schedule = HrdEmployeeSchedule.find_by(:hrd_employee_id=> record.hrd_employee_id, :status=> 'active', :date=> record.date)
			# 	if schedule.present?
			# 		# jika schedule masuk pada tanggal libur nasional
			# 		if HrdHolidayDate.find_by(:status=> 'active', :date=> record.date).present? or (schedule.hrd_schedule.present? and schedule.hrd_schedule.code == 'L')
			# 			counter += 1
			# 		end
			# 	end
			# end if att_user.present?
			puts "[#{att_user.company_profile_id}] - #{att_user.employee_id} #{begin_period} sd #{end_period} => working_off_day"
		end
		b = DateTime.now()
		puts "  => working_off_day process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return counter
	end

	def ot_period(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			(begin_period..end_period).each do |dt|
				count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, 'all', dt, dt) if att_user.present?
				# count_ot += get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, 'all', dt, dt) if att_user.present?
			end
		end
		# lembur tidak boleh setengahjam harus dibulatkan (round down)
		# puts "lllllllllllllllllllllllllllllllllllllllllllll"
		# puts "lembur => #{count_ot}=> #{count_ot.to_i}"
		# puts "lllllllllllllllllllllllllllllllllllllllllllll"
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => ot_period: #{count_ot.to_i} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot.to_i
	end
	
	def first_hour_ot(att_log_array, begin_period, end_period)
		a = DateTime.now()
		count_ot = 0
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, 'first', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, 'first', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => first_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end

	def second_hour_ot(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, 'second', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, 'second', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => second_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end

	def four_to_seven_hour_ot(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, '4-7', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, '4-7', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => four_to_seven_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end	

	def eight_to_eleven_hour_ot(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, '8-11', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, '8-11', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => eight_to_eleven_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end

	def above_eleven_hour_ot(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, '11+', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, '11+', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => above_eleven_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end

	def five_to_eight_hour_ot(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, '5-8', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, '5-8', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => five_to_eight_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end

	def above_eight_hour_ot(att_log_array, begin_period, end_period)
		count_ot = 0
		a = DateTime.now()
		# att_user = HrdAttendanceUser.find_by(:hrd_employee_id=> self.id)
		AttendanceUser.where(:company_profile_id=> self.company_profile_id, :employee_id=> self.id, :status=> 'active').each do |att_user|
			count_ot += get_overtime(att_user.company_profile_id, att_log_array, self.id, att_user.id_number, '8+', begin_period, end_period) if att_user.present?
			# count_ot = get_overtime(self.hrd_employee_payroll_id, self.id, att_user.id_number, '8+', begin_period, end_period) if att_user.present?
		end
		b = DateTime.now()
		puts "#{begin_period} sd #{end_period} => above_eight_hour_ot: #{count_ot} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
		return count_ot
	end
end
