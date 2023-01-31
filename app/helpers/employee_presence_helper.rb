module EmployeePresenceHelper

  

    def get_absence(plant_id, employee_id, att_log_array, holiday_date_array, hrd_schedule, employee_schedule_array, employee_absence_type, kind, begin_period, end_period)    
      # L = libur
      # I = izin
      # S = Sakit
      # A = Alpa
      a = DateTime.now()
      count = 0


      # att_check = HrdAttendanceUser.find_by(:id_number=> id_number, :sys_plant_id=> plant_id, :status=> 'active')
      if employee_id.present?
        

        # attendences = HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> att_check.hrd_employee_id, :status=> 'active').where("date between ? and ?", begin_period, end_period).order("date_time asc")
        # att_log_array = []
        # attendences.each do |att|
        #   case att.type_presence
        #   when 'in'
        #     acc_code = 'Att'
        #   else
        #     acc_code = 'Ext'
        #   end
        #   att_log_array << {
        #     :manual_presence=> false, 
        #     :empl_code=> att.id_number, 
        #     :period_shift=> att.date.strftime("%Y-%m-%d"), 
        #     :tr_date=> att.date_time.strftime("%Y-%m-%d"), 
        #     :tr_time=> att.date_time.strftime("%H:%M:%S"), 
        #     :acc_code=> acc_code, 
        #     :without_repair_period_shift=> att.without_repair_period_shift, 
        #     :type_presence=> att.type_presence
        #   }
        # end

        (begin_period .. end_period).each do |date_period|
          # absen tidak dianggap jika libur nasional
          national_holiday = false
          national_holiday_date = nil
          national_holiday_name = nil
          national_holiday_description = nil
          holiday_date_array.each do |hd|
            if hd[:date].to_date == date_period
              national_holiday = true 
              national_holiday_date = hd[:date]
              national_holiday_name = hd[:holiday]
              national_holiday_description = hd[:description]
            end
          end

          # 20210125: ada karyawan techno cuti di tgl libur nasional karena system off
          # if national_holiday == true
          #   # 20201124: aden
          #   puts "[#{kind}] libur nasional #{national_holiday_date}: #{national_holiday_name}; #{national_holiday_description}"
          #   case kind
          #   when 'L'
          #     # libur berdasarkan schedule
          #     employee_schedule_array.each do |schedule|
          #       if schedule[:period_shift].to_date >= date_period and schedule[:period_shift].to_date <= date_period 
          #         if schedule[:schedule_code] == kind
          #           count += 1
          #         end
          #       end
          #     end
          #   end
          # else
            cuti = false
            # att_check = HrdAttendanceUser.find_by(:id_number=> id_number, :sys_plant_id=> plant_id, :status=> 'active')
            # if att_check.present?
              case kind
              when 'L'
                # libur berdasarkan schedule
                employee_schedule_array.each do |schedule|
                  if schedule[:period_shift].to_date >= date_period and schedule[:period_shift].to_date <= date_period 
                    if schedule[:schedule_code] == kind
                      count += 1
                    end
                  end
                end

                # schedule = HrdSchedule.find_by( :code=> kind)
                # if schedule.present?
                #   HrdEmployeeSchedule.where(:hrd_schedule_id=> schedule.id, :sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :status=> 'active').where("date between ? and ?", date_period, date_period).each do |schedule|
                #     count += 1
                #   end
                # end
              else
                # jika dokumen izin sudah di approve tidak akan di anggap alpa (tidak hadir)
                 # HrdEmployeeAbsence.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id).where("begin_date <= ? and end_date >= ?", date_period, date_period).each do |absence|
                 # puts "hrd_employee_id: #{employee_id} period between #{date_period} and #{date_period}"
                 EmployeeAbsence.where(:employee_id=> employee_id).where("begin_date <= ? and end_date >= ?", date_period, date_period).each do |absence|
                # HrdEmployeeAbsence.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id).where("begin_date >= ? and end_date <= ?", date_period, date_period).each do |absence|
                  # puts "absence: [#{absence.status}] #{absence.begin_date} sd #{absence.end_date}"
                  if absence.status == 'approved3'
                    puts 'HAHAHAHAHHAHAH ZZZZZZZZZZZZZZZZZZ HAHAHAHAHHAHAHAH'
                    employee_absence_type.each do |at|                      
                      if at[:id].to_i == absence.employee_absence_type_id.to_i
                        case kind
                        when 'A'
                          cuti = true
                        when 'I'
                          # izin tidak masuk kerja
                          count += 1 if at[:code] == 'ITM'
                        when 'S'
                          # Tidak Masuk dengan Keterangan Dokter
                          count += 1 if at[:code] == 'IS'
                        when 'C'
                          # 2020-10-22: lina
                          # count += 1 if at[:code] == 'CT'

                          # 2021-08-19: cuti dibaca jika kode schedule bukan L
                          employee_schedules = EmployeeSchedule.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :status=> 'active').where("date between ? and ?", date_period.to_date.beginning_of_year(), date_period.to_date.end_of_year() ).includes(:schedule).order("date asc")
                          libur = 0
                          (absence.begin_date..absence.end_date).each do |dt|
                            schedule = employee_schedules.find_by(:date=> dt)
                            if schedule.present? and schedule.schedule.present?
                              case schedule.schedule.code
                              when 'L'
                                libur += 1
                              end
                            end
                          end

                          if libur == 0
                            puts "#{libur} iniiii"
                            # Cuti Tahunan
                            case at[:code]
                            when 'C01','C02','C03','C04','C05','C06','CHM','CML','CT'
                              count += 1
                            end
                            puts "#{count} uhuyyyy"
                          end
                        end
                      end
                    end
                    # puts "[#{kind}] #{absence.begin_date} sd #{absence.end_date} => #{absence.hrd_employee_absence_type_id} => #{count}"
                  end
                end

                # HrdEmployeeAbsence.where(:sys_plant_id=> plant_id, :hrd_employee_id=> att_check.hrd_employee_id).where("begin_date >= ? and end_date <= ?", date_period, date_period).each do |absence|
                #   if absence.status == 'app3'
                #     case kind
                #     when 'A'
                #       cuti = true
                #     when 'I'
                #       # izin tidak masuk kerja
                #       if absence.hrd_employee_absence_type.present? and absence.hrd_employee_absence_type.code == 'ITM'
                #         count += 1
                #       end
                #     when 'S'
                #       # Tidak Masuk dengan Keterangan Dokter
                #       if absence.hrd_employee_absence_type.present? and absence.hrd_employee_absence_type.code == 'IS'
                #         count += 1
                #       end
                #     when 'C'
                #       # Cuti Tahunan
                #       if absence.hrd_employee_absence_type.present? and absence.hrd_employee_absence_type.code == 'CT'
                #         count += 1
                #       end
                #     end
                #   end
                # end

                case kind
                when 'A'
                  # jika tidak ada cuti (app3) maka dihitung sebagai alpa
                  if cuti == false
                    employee_schedule_array.each do |schedule|
                      if schedule[:period_shift].to_date == date_period.to_date
                        case schedule[:schedule_code] 
                        when 'L','I','S','22'
                        else
                          att_log_type_presence_in = false
                          att_log_type_presence_out = false
                          att_log_array.each do |att_log|
                            if att_log[:period_shift].to_date == date_period.to_date
                              if att_log[:type_presence] == 'in'
                                att_log_type_presence_in = true
                              end
                              if att_log[:type_presence] == 'out'
                                att_log_type_presence_out = true
                              end
                              # puts "[#{att_log[:period_shift]}] absence #{kind} att_log_type_presence_in: #{att_log_type_presence_in}; att_log_type_presence_out: #{att_log_type_presence_out}"
                            end
                          end
                          if att_log_type_presence_in == false and att_log_type_presence_out == false
                            count += 1
                          end
                        end
                      end
                    end

                    # schedule  = HrdEmployeeSchedule.find_by(:hrd_employee_id=> att_check.hrd_employee_id, :date=> date_period, :status=> 'active')
                    # if schedule.present?
                    #   schedule_code = (schedule.hrd_schedule.code if schedule.hrd_schedule.present?)
                    #   case schedule_code
                    #   when 'L','I','S'
                    #   else
                    #     if HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> date_period, :status=> 'active').where("type_presence in (?)", ['in','out']).blank?
                    #       count += 1
                    #     end
                    #   end
                    # end
                  end
                end
              end
            # else
            #   puts "id_number: #{id_number} tidak ada"
            # end
          # end
        end
      end
      b = DateTime.now()
      puts "#{begin_period} sd #{end_period} => absence [#{kind}]: #{count.to_i} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
      # puts "#{begin_period} sd #{end_period} => absence #{kind}; #{count}"
      return count
    end

    def get_late_in(att_log_array, date_period, begin_period) 
      a = DateTime.now()
      count = 0
      # att_check = HrdAttendanceUser.find_by(:id_number=> id_number, :sys_plant_id=> plant_id, :status=> 'active')
      # employee_id = att_check.hrd_employee_id
      # if HrdAttendanceLog.where("date_time > ? ",begin_period).find_by(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> date_period, :type_presence=> 'in', :status=> 'active').present?
      #   count = 1
      # end if begin_period.present?
      if begin_period.present?
        record_exist = false
        att_log_array.each do |att_log|
          # puts "[#{att_log[:date]}] #{att_log[:date_time]} => #{att_log[:type_presence]}"
          if att_log[:date].to_date == date_period.to_date 
            if att_log[:type_presence] == 'in' 
              if record_exist == false
                if att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S") > begin_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                  count = 1
                  # puts "[#{att_log[:date]}] telat: #{att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S")} > #{begin_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S") > begin_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
                  
                end
                # ambil record awal
                record_exist = true
              end
            end
          end
        end
      end
      b = DateTime.now().strftime("%H:%M:%S")
      puts "[#{date_period}] => telat: #{count.to_i} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
      
      return count
    end
    
    def get_leave_early(att_log_array, date_period, end_period) 
      a = DateTime.now()
      count = 0
      # att_check = HrdAttendanceUser.find_by(:id_number=> id_number, :sys_plant_id=> plant_id, :status=> 'active')
      # employee_id = att_check.hrd_employee_id
      # if HrdAttendanceLog.where("date_time < ? ",end_period).find_by(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> date_period, :type_presence=> 'out', :status=> 'active').present?
      #   count = 1
      # end
      last_date_time = nil
      last_date = nil
      att_log_array.each do |att_log|
        if att_log[:date].to_date == date_period.to_date 
          if att_log[:type_presence] == 'out'
            last_date_time = att_log[:date_time]
            last_date = att_log[:date]
          end
        end
      end
      if last_date_time.present?
        if last_date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") < end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          count = 1
          puts "[#{last_date}] pulang awal: #{last_date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} < #{end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
        end
      end
      b = DateTime.now().strftime("%H:%M:%S")
      puts "[#{date_period}] => pulang awal: #{count.to_i} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
      return count
    end

    def get_working_hour(plant_id, id_number, date_period, schedule_time_in, schedule_time_out, schedule_code) 
      a = DateTime.now()
      # puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"   
      # puts "#{plant_id}, #{id_number}, #{date_period}, #{schedule_time_in}, #{schedule_time_out}, #{schedule_code}"
      att_check = AttendanceUser.find_by(:id_number=> id_number, :company_profile_id=> plant_id, :status=> 'active')
      employee_id = att_check.employee_id
      ot =  EmployeeOvertime.find_by(:company_profile_id=> plant_id, :employee_id=> employee_id, :date=> date_period, :status=> 'arppoved3')
      # menghitung jam kerja
        # if (schedule_code == 'L' or schedule_code == 'I' or schedule_code == 'S' or schedule_code == 'A') and ot.blank?

      case schedule_code
      when 'L','I','S','A'
        diff_time = 0
        # puts "tidak ada schdule Masuk"
      else
        if schedule_time_in.blank? and schedule_time_out.blank?
          schedule_time_in  = ot.overtime_begin if ot.present?
          schedule_time_out = ot.overtime_end if ot.present?
        end

        if schedule_time_in.present? and schedule_time_out.present?
          # puts "#{schedule_time_in} to #{schedule_time_out}"
          begin_period  = "#{date_period} #{schedule_time_in}".to_time
          end_period  = "#{date_period} #{schedule_time_out}".to_time
          
          # puts "----------> begin: #{begin_period} end: #{end_period}"

          case end_period.strftime("%H:%M")
          when '00:00'
            end_period = end_period.to_date+1.days
            end_period = "#{end_period} 00:00:59"
          # when '08:00'
          #   end_period = end_period.to_date+1.days
          #   end_period = "#{end_period} 08:00:00"
          else
            if schedule_time_in > schedule_time_out
              end_period  = end_period+1.days
            end
          end

          # jika ada yg schedule masuk 23:59 ini akan membaca telat masuk
          # puts begin_period
          # puts "xxxxxxxxxxxxxxxxxxxxxxxxx"
          # case begin_period.strftime("%H:%M")
          # when '23:59'
          #   begin_period = (begin_period.strftime("%Y-%m-%d")+" 00:00:00").to_date
          # end
          diff_time_late = 0
          diff_time_leave = 0
          if id_number.present? #and HrdAttendanceLog.find_by(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> date_period, :type_presence=> 'out', :status=> 'active').present? and HrdAttendanceLog.find_by(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> date_period, :type_presence=> 'in', :status=> 'active').present?
            
            att_log_array = []
            AttendanceLog.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :date=> date_period, :status=> 'active').order("date_time asc").each do |att_log|
              att_log_array << {
                :period_shift=> att_log.date,
                :time => att_log.time.strftime("%H:%M:%S"),
                :date_time => att_log.date_time.strftime("%Y-%m-%d %H:%M:%S"),
                :type_presence=> att_log.type_presence
              }
            end
            att_log_array_type_presence_in = false
            att_log_array_type_presence_out = false
            late_in_at_date_time = nil
            late_in_at_time = nil
            late_in = false

            leave_early_at = nil
            leave_early_at_date_time = nil
            leave_early = false

            presence_in = false
            presence_out = false

            att_log_array.each do |att_log|
              # puts "#{att_log[:date_time]} => #{att_log[:type_presence]}"            
              if att_log[:type_presence] == 'in'
                att_log_array_type_presence_in = true
                if att_log[:period_shift].to_date == date_period.to_date
                  presence_in = true
                  late_in_at_date_time = att_log[:date_time] if late_in_at_date_time == nil
                end

                if late_in_at_date_time.present? 
                  if late_in_at_date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") > begin_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att_log[:period_shift].to_date == date_period.to_date
                    late_in = true
                    late_in_at_time = att_log[:time] if late_in_at_time == nil
                  end
                end
              end
              if att_log[:type_presence] == 'out'
                att_log_array_type_presence_out = true
                if att_log[:period_shift].to_date == date_period.to_date
                  presence_out = true
                  leave_early_at_date_time = att_log[:date_time]
                end
                if leave_early_at_date_time.present? 
                  leave_early = false
                  leave_early_at = nil
                  puts leave_early_at_date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") 
                  puts begin_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S") 
                  puts att_log[:period_shift].to_date 
                  puts date_period.to_date
                  if leave_early_at_date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") < end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att_log[:period_shift].to_date == date_period.to_date
                    leave_early = true
                    leave_early_at = att_log[:date_time]
                  end
                end
              end
            end

            # puts "late_in_at_time: #{late_in_at_time}"
            # puts "leave_early_at: #{leave_early_at}"
            if att_log_array_type_presence_in.present? and att_log_array_type_presence_out.present?

              # late_in = HrdAttendanceLog.where("date_time > ? ",begin_period).where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'in', :status=> 'active').order("date_time asc").find_by(:date=> date_period)
              # leave_early = HrdAttendanceLog.where("date_time < ? ",end_period).where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'out', :status=> 'active').order("date_time desc").find_by(:date=> date_period)
              
             
              # # schedule jam kerja
              # if TimeDifference.between( begin_period.to_time, end_period.to_time).in_hours > 8
              #   end_period = (end_period.to_time+1.days).to_time
              # end
              # end_period_late = end_period
              # if TimeDifference.between( begin_period.to_time, end_period.to_time).in_hours > 8
              #   end_period_late = (end_period.to_time+1.days).to_time
              # end
              # diff_time = TimeDifference.between( begin_period.to_time, end_period_late.to_time).in_hours

              # puts "schedule jam kerja #{date_period}"
              # puts "Masuk: #{begin_period.to_time}"
              # puts "Keluar: #{end_period.to_time}"
              # puts "selisih: #{diff_time}"

              if late_in == true
                # puts "================================="
                # puts "#{date_period} #{late_in.time}".to_time
                # puts "================================="
                # jika schedule masuk jam 23:59 dan telat maka tgl di kurangi 1
                # late_date_period = date_period
                # 2020-03-20 aden: untuk yg telat
                # case begin_period.strftime("%H:%M")
                # when '23:59'
                #   late_date_period = date_period.to_date+1.days
                # end
                # puts "#{late_in_at_date_time}".to_time.strftime("%Y-%m-%d %H:%M:%S")
                # puts begin_period.to_time.strftime("%Y-%m-%d %H:%M:59")
                # if "#{late_date_period} #{late_in_at_time}".to_time > begin_period.to_time.strftime("%Y-%m-%d %H:%M:59")
                #   late_date_period = date_period.to_date+1.days
                # end

                # selisih berdsarkan schedule in dan presensi masuk
                # jika telat maka jam kerja di potong selisih telat

                diff_time_late = TimeDifference.between( "#{late_in_at_date_time}".to_time.strftime("%Y-%m-%d %H:%M:%S"), begin_period.to_time ).in_hours
                # diff_time_late = TimeDifference.between( "#{late_date_period} #{late_in_at_time}".to_time, begin_period.to_time ).in_hours
                # puts "#{late_date_period} #{late_in_at_time}".to_time
                # puts begin_period.to_time
                # diff_time_late = TimeDifference.between( "#{late_date_period} #{late_in.time.strftime("%H:%M:%S")}".to_time, begin_period.to_time ).in_hours
                # puts "#{date_period} datang telat; #{diff_time_late}"
                # puts "#{late_date_period} datang telat; between #{late_date_period} #{late_in.time.strftime("%H:%M:%S")} and #{begin_period.to_time};"
              end
              # puts "leave_early: #{leave_early}"
              if leave_early == true
                # leave_early = HrdAttendanceLog.where(:date=> date_period).where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'out', :status=> 'active').order("date_time asc")

                # selisih berdsarkan schedule out dan presensi keluar
                # jika pulang awal maka jam kerja di potong selisih pulang awal
                if schedule_time_in.strftime("%H:%M:%S") > schedule_time_out.strftime("%H:%M:%S")
                # if schedule_time_out.strftime("%H:%M:%S") >= '00:00:59' and schedule_time_out.strftime("%H:%M:%S") <= '09:00:59'
                  # 20200221 - jika 
                  end_period = "#{date_period+1.days} #{schedule_time_out}".to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                  # puts end_period
                  # 20200221 - jika tidak sesuai schedule maka bermasalah
                  # end_period = "#{presence_out.date_time.strftime("%Y-%m-%d")} #{schedule_time_out}".to_time
                end

                # puts "leave_early_at: #{leave_early_at.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}; < end_period: #{end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{leave_early_at.to_datetime.strftime("%Y-%m-%d %H:%M:%S") < end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
                if leave_early_at.to_datetime.strftime("%Y-%m-%d %H:%M:%S") < end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                # if leave_early.last.date_time.strftime("%Y-%m-%d %H:%M:%S") < end_period
                  # puts "periode: #{leave_early.last.date_time.strftime("%Y-%m-%d %H:%M:%S")} sd  #{end_period}"
                  # puts end_period.to_time
                    diff_time_leave = TimeDifference.between("#{leave_early_at.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}", end_period.to_datetime.strftime("%Y-%m-%d %H:%M:%S")).in_hours
                    # diff_time_leave = TimeDifference.between("#{leave_early.last.date_time.strftime("%Y-%m-%d %H:%M:%S")}", end_period).in_hours
                    # diff_time_leave = TimeDifference.between("#{date_period} #{leave_early.last.time.strftime("%H:%M:%S")}", end_period).in_hours
                    puts "#{date_period} pulang awal #{diff_time_leave}"
                    puts "-----------------------------"
                end
              end

              # puts "jam kerja normal"
              # if AttCheckinout.where(:id_number=> id_number, :type_presence=> 'in', :date=> date_period).where("date_time <= ?", begin_period).present? and AttCheckinout.where(:id_number=> id_number, :type_presence=> 'out').where("date_time >= ?", end_period).present?
              #   diff_time = TimeDifference.between( begin_period.to_time, end_period.to_time).in_hours
              #   puts "#{date_period} jam kerja normal => #{begin_period.to_time}, #{end_period.to_time}"
              # end
              # presence_in = HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'in', :status=> 'active').order("date_time asc").find_by(:date=> date_period) 
              # presence_out = HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'out', :status=> 'active').order("date_time desc").find_by(:date=> date_period) 

              if presence_in == true and presence_out == true
                # if presence_in.present? and presence_out.present?
                # menghitung selisih termasuk pulang telat
                # diff_time = TimeDifference.between( presence_in.date_time.to_time, presence_out.date_time.to_time).in_hours
                # puts "#{date_period} jam kerja normal => #{presence_in.date_time.to_time}, #{presence_out.date_time.to_time}"

                # pulang telat ga di hitung, datang telat dihitung
                # puts end_period
                # 20200110 - perhitungan bermasalah jika jam kerja lebih dari 8 jam karena loyalitas
                # if TimeDifference.between( begin_period.to_time, end_period.to_time).in_hours > 8
                #   end_period = (end_period.to_time+1.days).to_time
                # end
                # 20200110 - perhitungan bermasalah jika jam kerja shift berikutnya
                # if "#{end_period.to_date.strftime("%Y-%m-%d")} 10:00:00".to_time > end_period.to_time
                #   end_period = (end_period.to_time+1.days).to_time
                # end
                # puts presence_out.date_time

                # if presence_out.date_time > "#{presence_out.date_time.to_date.strftime("%Y-%m-%d")} 00:00:00" and presence_out.date_time < "#{presence_out.date_time.to_date.strftime("%Y-%m-%d")} 10:00:00"
                # puts presence_out.date_time.strftime("%Y-%m-%d") > presence_in.date_time.strftime("%Y-%m-%d")
                # puts presence_in.date_time.strftime("%Y-%m-%d")
                # puts presence_out.date_time.strftime("%Y-%m-%d")
                # if presence_out.date_time.strftime("%Y-%m-%d") > presence_in.date_time.to_time.strftime("%Y-%m-%d")
                #   # end_period = "#{presence_out.date_time.strftime("%Y-%m-%d")} #{schedule_time_out}".to_time
                #   end_period = "#{presence_out.date} #{schedule_time_out}".to_time
                #   puts "ini"
                # end
                # if presence_out.date_time > "#{presence_out.date} #{schedule_time_out}".to_time
                #   end_period = "#{presence_out.date_time.strftime("%Y-%m-%d")} #{schedule_time_out}".to_time
                # end
                
                # if presence_out.date_time.strftime("%Y-%m-%d") > presence_in.date_time.to_time.strftime("%Y-%m-%d")
                #   end_period = "#{presence_out.date} #{schedule_time_out-1.minutes}".to_time
                #   puts "ini"
                # end

                # if schedule_time_out >= '00:00:59' and schedule_time_out <= '09:00:59'
                if schedule_time_in.strftime("%H:%M:%S") > schedule_time_out.strftime("%H:%M:%S")
                # if schedule_time_out.strftime("%H:%M:%S") >= '00:00:59' and schedule_time_out.strftime("%H:%M:%S") <= '09:00:59'
                  # 20200221 - jika 
                  end_period = "#{date_period+1.days} #{schedule_time_out}".to_time
                  # puts end_period
                  # 20200221 - jika tidak sesuai schedule maka bermasalah
                  # end_period = "#{presence_out.date_time.strftime("%Y-%m-%d")} #{schedule_time_out}".to_time
                end

                diff_time = TimeDifference.between( begin_period.to_time, end_period.to_time).in_hours
                # puts "begin_period: #{begin_period.to_time}, end_period: #{end_period.to_time} => #{diff_time}"
                # att_date_in = "#{presence_in.date_time.strftime("%Y-%m-%d")} #{schedule_time_in.strftime("%H:%M:%S")}".to_time
                # puts "late = #{diff_time_late}"
                # puts "diff_time = #{diff_time}"
                  # att_date_out = "#{presence_out.date_time.strftime("%Y-%m-%d")} #{schedule_time_out.strftime("%H:%M:%S")}".to_time
                # end
                
                # diff_time = TimeDifference.between(att_date_in, att_date_out).in_hours
                # puts "#{date_period} jam kerja normal => #{att_date_in}, #{att_date_out}"

              end

              if presence_in == false or presence_out == false
                # if presence_in.blank? or presence_out.blank?
                # jika tidak ada presensi masuk atau pulang
                diff_time = 8
              end

              # if begin_period.strftime("%H:%M:%S") == '23:59:59'
                # selisih dari 23:59:59 dengan 08:00:59 adalah 8 jam 1 menit atau 8.02
                # diff_time -= 0.02
              # end
               if begin_period.strftime("%M:%S") != '59:59'
                diff_time += 0.02
              end

              # jika jam kerja lebih dari 4 jam maka potong 1 jam untuk istirahat
              if diff_time > 4 
                diff_time -= 1
              end

              # puts diff_time
              if diff_time_late > 0
                puts "xxxxxxxxxxxxxxxxxxxxxxxxx"
                puts "potong telat masuk: #{diff_time_late}"
                puts "xxxxxxxxxxxxxxxxxxxxxxxxx"
                diff_time -= diff_time_late
              end
              if diff_time_leave > 0
                puts "xxxxxxxxxxxxxxxxxxxxxxxxx"
                puts "potong pulang awal: #{diff_time_leave}"
                puts "xxxxxxxxxxxxxxxxxxxxxxxxx"
                diff_time -= diff_time_leave
              end
              # puts "diff_time => #{diff_time} XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

            else
              diff_time = 0
              # puts "tidak ada: #{begin_period} sd #{end_period} "
            end

          else
            diff_time = 0
            # puts "tidak ada: #{begin_period} sd #{end_period} "
          end
        else
          diff_time = 0
          # puts "tidak ada schdule lembur"
        end
      end
      # jika total jam kerja jadi minus karena di potong telat dan atau pulang awal
      if diff_time < 0
        diff_time = 0
      end
      # puts "diff_time = #{diff_time}"
      # puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"   
      b = DateTime.now()
      puts "    => #{date_period} working hour #{diff_time.round(2)} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
      return diff_time.round(2)
    end

    def get_working_day(plant_id, employee_id, work_schedule, id_number, kind, begin_period, end_period)
      # hari kerja dan hari libur
      count = 0
      a = DateTime.now()
      # att_check = HrdAttendanceUser.find_by(:id_number=> id_number, :sys_plant_id=> plant_id, :status=> 'active')
      # hrd_employee = HrdEmployee.find_by(:id=> att_check.hrd_employee_id ) if att_check.present?
      # employee_id = att_check.hrd_employee_id
      # work_schedule = (hrd_employee.present? ? hrd_employee.work_schedule : nil)

      # AttCheckinout.where(:id_number=> id_number).where("date_time between ? and ?", begin_period, end_period).each do |weekday|
      # AttCheckinout.where(:id_number=> id_number, :type_presence=> 'in').where("date between ? and ?", begin_period, end_period).each do |weekday|
      # HrdEmployeeSchedule.where(:sys_plant_id=> hrd_employee.hrd_employee_legal_id, :hrd_employee_id=> att_check.hrd_employee_id, :status=> 'active').where("date between ? and ?", begin_period, end_period).each do |schedule|
      #   if schedule.hrd_schedule.present? 
      #     case schedule.hrd_schedule.code
      #     when 'L'
      #       case kind
      #       when 'weekend'
      #         if HrdEmployeeOvertime.find_by(:hrd_employee_id=> hrd_employee.id, :status=> 'app3', :period_shift=> schedule.date).present? and HrdAttendanceLog.find_by(:hrd_employee_id=> hrd_employee.id, :date=> schedule.date, :type_presence=> 'in').present?
      #           count += 1
      #         end
      #       end
      #     else
      #       case kind
      #       when 'weekday'
      #         count += 1
      #       end
      #     end
      #   end
      # end

      attendences = AttendanceLog.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :status=> 'active').where("date between ? and ?", begin_period, end_period).order("date_time asc")
      att_log_array = []
      attendences.each do |att|
        case att.type_presence
        when 'in'
          acc_code = 'Att'
        else
          acc_code = 'Ext'
        end
        att_log_array << {
          :manual_presence=> false, 
          :empl_code=> att.id_number, 
          :period_shift=> att.date.strftime("%Y-%m-%d"), 
          :tr_date=> att.date_time.strftime("%Y-%m-%d"), 
          :tr_time=> att.date_time.strftime("%H:%M:%S"), 
          :acc_code=> acc_code, 
          :without_repair_period_shift=> att.without_repair_period_shift, 
          :type_presence=> att.type_presence
        }
      end

      hrd_schedule = []
      Schedule.where(:status=> 'active').each do |schedule|
        hrd_schedule << {
          :id=> schedule.id, 
          :company_profile_id=> schedule.company_profile_id,
          :code=> schedule.code,
          :monday_in=> schedule.monday_in, :monday_out=> schedule.monday_out, 
          :tuesday_in=> schedule.tuesday_in, :tuesday_out=> schedule.tuesday_out, 
          :wednesday_in=> schedule.wednesday_in, :wednesday_out=> schedule.wednesday_out, 
          :thursday_in=> schedule.thursday_in, :thursday_out=> schedule.thursday_out, 
          :friday_in=> schedule.friday_in, :friday_out=> schedule.friday_out, 
          :saturday_in=> schedule.saturday_in, :saturday_out=> schedule.saturday_out, 
          :sunday_in=> schedule.sunday_in, :sunday_out=> schedule.sunday_out
        }
      end 
      holiday_in_month = 0
      employee_schedule_array = []
      EmployeeSchedule.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :status=> 'active').where("date between ? and ?", begin_period, end_period).each do |employee_schedule|
        hrd_schedule.each do |schedule|
          if schedule[:id].to_i == employee_schedule.schedule_id.to_i
            employee_schedule_array << {
              :schedule_id=> employee_schedule.schedule_id,
              :period_shift=> employee_schedule.date,
              :schedule_code => schedule[:code],
              :employee_id=> employee_id
            }

            holiday_in_month+=1 if schedule[:code] == 'L'
          end
        end
      end

      ot_array = []
      EmployeeOvertime.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :status=> 'approved3').where("date between ? and ?", begin_period, end_period).group(:company_profile_id, :employee_id, :date, :overtime_begin).each do |ot|
        ot_array << {
          :id=> ot.id,
          :date=> ot.date,
          :status=> ot.status
        }
      end

      (begin_period .. end_period).each do |dt|
        next_script = true
        case kind
        when 'weekend'
          # masuk pada hari libur dan di schedule libur (L, I, S, A) maka tidak akan dihitung masuk hari libur
          employee_schedule_array.each do |schedule|
            if schedule[:period_shift].to_date == dt.to_date
              case schedule[:code]
              when 'L','I','S','A'
                next_script = false
              end
            end
          end
          # schdule = HrdEmployeeSchedule.find_by(:hrd_employee_id=> employee_id, :status=> 'active', :date=> dt)
          # if schdule.present? and schdule.hrd_schedule.present?
          #   case schdule.hrd_schedule.code 
          #   when 'L','I','S','A'
          #     next_script = false
          #   end
          # end
        end

        # hari libur berdasarkan schedule employee bukan work schedule
        case next_script 
        when true
          weekday = false
          weekday_date  = nil
          weekday2_date = nil
          att_log_array.each do |att_log|
            if att_log[:period_shift].to_date == dt.to_date 
              if att_log[:type_presence] == 'in'
                weekday = true
                weekday_date = att_log[:period_shift].to_date
              end
            end
          end
          ot_exist = false
          ot_array.each do |ot|
            if ot[:date].to_date == dt.to_date 
              ot_exist = true
            end
          end

          # weekday = HrdAttendanceLog.find_by(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> dt, :type_presence=> 'in', :status=> 'active')      
          # weekday = AttCheckinout.find_by("type_presence = ? and id_number = ? and DATE(date_time) = ?", 'in', id_number, dt)
          if weekday == true and ot_exist == true
            # jika lembur lanjut dari hari sebelumnya
            att_log_array.each do |att_log|
              if att_log[:tr_date].to_date == dt.to_date 
                if att_log[:type_presence] == 'out'
                  weekday2_date = att_log[:tr_date].to_date
                end
              end
            end
            # weekday = HrdAttendanceLog.where(:sys_plant_id=> plant_id, :type_presence=> 'out', :hrd_employee_id=> employee_id, :status=> 'active').find_by("DATE(date_time) = ?", dt)
            # weekday2_date = weekday.date_time if weekday.present?
          end

          if weekday == true
            if weekday2_date.present?
              weekday_date = weekday2_date
              # weekday_date = weekday.date
            end
            case work_schedule
            when '6-2','6-0'
              case kind
              when 'weekend'
                if weekday_date.sunday?
                  # puts "#{weekday_date} is a weekend!"
                  count += 1
                end
              when 'weekday'
                if weekday_date.sunday?
                  # puts "#{weekday_date} is a weekend!"
                else
                  # puts "#{weekday_date} is a work day!"
                  count += 1
                end
              end
            else
              case kind
              when 'weekend'
                if weekday_date.saturday? || weekday_date.sunday?
                  # puts "#{weekday_date} is a weekend!"
                  count += 1
                end
              when 'weekday'
                if weekday_date.saturday? || weekday_date.sunday?
                  # puts "#{weekday_date} is a weekend!"
                else
                  # puts "#{weekday_date} is a work day!"
                  count += 1
                end
              end
            end
            # puts "work_schedule: #{work_schedule}; kind: #{kind}; date: #{weekday_date} => #{count}"
          end
        end
      end if id_number.present?

      b = DateTime.now()
      # puts "[#{begin_period}] => #{kind}: #{count.to_i} => process time: #{TimeDifference.between(a, b).in_seconds} Sec."
      return count
    end

    def get_overtime(plant_id, att_log_array, employee_id, id_number, kind, begin_period, end_period)
      summary_ot = 0
      # puts "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoo overtime #{kind} =>            #{ begin_period}, #{end_period}"
      # x = jumlah ot dalam 1 periode presensi
      x = 0

      # attendences = HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :status=> 'active').where("date between ? and ?", begin_period, end_period).order("date_time asc")
      
      # count = 0
      # att_log_array = []
      # attendences.each do |att|
      #   case att.type_presence
      #   when 'in'
      #     acc_code = 'Att'
      #   else
      #     acc_code = 'Ext'
      #   end
      #   att_log_array << {
      #     :manual_presence=> false, 
      #     :empl_code=> att.id_number, 
      #     :period_shift=> att.date.strftime("%Y-%m-%d"), 
      #     :tr_date=> att.date_time.strftime("%Y-%m-%d"), 
      #     :tr_time=> att.date_time.strftime("%H:%M:%S"), 
      #     :acc_code=> acc_code, 
      #     :without_repair_period_shift=> att.without_repair_period_shift, 
      #     :type_presence=> att.type_presence
      #   }
      #   count += 1
      # end
      count = 0
      att_log_array.each do |x|
        count += 1
      end

      att_new = []
      (0..count).each do |c|
            
        if att_log_array[c+1].present?
          if att_log_array[c][:type_presence] == 'in' and att_log_array[c+1][:type_presence] == 'out'
            datetime_in = "#{att_log_array[c][:tr_date]} #{att_log_array[c][:tr_time]}".to_datetime.strftime("%Y-%m-%d %H:%M:%S")
            datetime_out = "#{att_log_array[c+1][:tr_date]} #{att_log_array[c+1][:tr_time]}".to_datetime.strftime("%Y-%m-%d %H:%M:%S")
            att_new << {
              :period_shift=> att_log_array[c][:period_shift],
              :datetime_in => datetime_in,
              :datetime_out => datetime_out
            }
            # puts "[#{att_log_array[c][:period_shift]}] => IN: #{datetime_in}; OUT: #{datetime_out};"
            # puts "1 [#{att_log_array[c][:period_shift]}] #{att_log_array[c][:tr_date]} - in: #{datetime_in}; out: #{datetime_out}"
          end  
        end
      end

      EmployeeOvertime.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :status=> 'approved3').where("date between ? and ?", begin_period, end_period).group(:company_profile_id, :employee_id, :date, :overtime_begin).each do |ot|
        # puts "m #{x} mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm ======> #{ot.date} #{ot.overtime_begin}"
        begin_time = "#{ot.date} #{ot.overtime_begin.strftime('%H:%M:%S')}".to_time
        end_time = "#{ot.date} #{ot.overtime_end.strftime('%H:%M:%S')}".to_time

        count_ot = 0

        ot_date = ot.date
        if end_time < begin_time
          end_time = "#{ot_date.to_date+1.days} #{end_time.strftime('%H:%M:%S')}"
        end

        # jika lanjut lembur dari hari kerja sebelumnya
        # if begin_time.hour < 8
        #   ot_date = ot.date-1.days
        #   begin_time = "#{ot_date} #{begin_time.strftime('%H:%M:%S')}"
        #   end_time = "#{ot_date} #{end_time.strftime('%H:%M:%S')}"
        #   # puts "ot_date: #{ot_date}"
        #   # puts "end_time: #{end_time}"
        # end

        # puts "count_ot => #{count_ot}"
        case kind
        when 'all','second'
          diff_in = 10000
          diff_out = 10000

          presence_in  = nil
          presence_out = nil
          # HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :status=> 'active').where("date(date_time) = ?", ot.date).each do |x|
          #   # puts "[#{x.date}]"
      
          #   HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> x.date, :status=> 'active').each do |a|
          #     # jika menggunakan tanggal period_shift pada OT hasilnya masalah
          #   # HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :date=> ot.period_shift).each do |a|
          #     # puts "   #{a.date_time} #{a.type_presence}"
          #     if a.type_presence == 'in'
          #       # puts "     in  => #{TimeDifference.between( a.date_time.to_time, begin_time.to_time).in_hours}"
          #       diff_in_check = TimeDifference.between( a.date_time.to_time, begin_time.to_time).in_hours
          #       if diff_in_check < diff_in
          #         diff_in = diff_in_check 
          #         presence_in = a.date_time
          #       end
          #     end
          #     if a.type_presence == 'out'
          #       # puts "     out => #{TimeDifference.between( a.date_time.to_time, end_time.to_time).in_hours}"
          #       diff_out_check = TimeDifference.between( a.date_time.to_time, end_time.to_time).in_hours
          #       if diff_out_check < diff_out
          #         diff_out = diff_out_check 
          #         presence_out = a.date_time
          #       end
          #     end
          #   end
          # end
          puts "====================================================="

          att_new.each do |att|
            puts "[#{att[:period_shift]}]: IN: #{att[:datetime_in]}; OUT: #{att[:datetime_out]}; => begin: #{begin_time}; end: #{end_time}; #{att[:datetime_in].to_datetime.strftime("%Y-%m-%d") == begin_time.to_datetime.strftime("%Y-%m-%d")}"
             # telat
            if att[:datetime_in].to_datetime.strftime("%Y-%m-%d") == begin_time.to_datetime.strftime("%Y-%m-%d") or att[:datetime_out].to_datetime.strftime("%Y-%m-%d") == end_time.to_datetime.strftime("%Y-%m-%d")
              puts "    => presence_in: #{presence_in}; presence_out: #{presence_out};"
              puts "  C => #{att[:datetime_in]} >= #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_in] >= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              puts "  C => #{att[:datetime_out]} >= #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_out] >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              # puts "B => #{att[:datetime_in]} <= #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} and #{att[:datetime_out]} > #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_in] <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att[:datetime_out] > begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              # if att[:datetime_in] >= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att[:datetime_out] > begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
              if att[:datetime_in] >= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att[:datetime_out] >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                puts "  C => #{att[:datetime_in]} <= #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_in] <= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
                if att[:datetime_in] <= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                  presence_in = att[:datetime_in] #if presence_in.blank?
                  presence_out = att[:datetime_out] #if presence_out.blank?
                  telat = true
                  puts "  NEW => presence_in: #{presence_in}; presence_out: #{presence_out};"
                end
              end
            end
            # pulang awal, masalah jika ada telat
            # if att[:datetime_out].to_datetime.strftime("%Y-%m-%d") == end_time.to_datetime.strftime("%Y-%m-%d")
            if att[:datetime_in].to_datetime.strftime("%Y-%m-%d") == begin_time.to_datetime.strftime("%Y-%m-%d") or att[:datetime_out].to_datetime.strftime("%Y-%m-%d") == end_time.to_datetime.strftime("%Y-%m-%d")
              puts "    => presence_in: #{presence_in}; presence_out: #{presence_out};"
              puts "  B => #{att[:datetime_in]} <= #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_in] <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") }"
              puts "  B => #{att[:datetime_out]} <= #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_out] <= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              # puts "C => #{att[:datetime_in]} < #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} and #{att[:datetime_out]} >= #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_in] < end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att[:datetime_out] >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              # if att[:datetime_out] >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
              if att[:datetime_in] <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S") and att[:datetime_out] <= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                puts "  B => #{att[:datetime_out]} >= #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:datetime_out] >= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
                if att[:datetime_out] >= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                  presence_in = att[:datetime_in] #if presence_in.blank?
                  presence_out = att[:datetime_out] #if presence_out.blank?
                  puts "  NEW => presence_in: #{presence_in}; presence_out: #{presence_out};"
                end
              end
            end
            # normal
           if att[:datetime_in] <= begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S") and att[:datetime_out] >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
              puts "  A => #{att[:datetime_in]} <= #{begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S")} : #{att[:datetime_in] <= begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S")}"
              puts "  A => #{att[:datetime_out]} >= #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{att[:datetime_out] >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
            
              presence_in = att[:datetime_in]
              presence_out = att[:datetime_out]
              puts "    => presence_in: #{presence_in}; presence_out: #{presence_out};"
            end
            # baca lembur akhir
            # if att[:period_shift].to_date == ot.period_shift.to_date
            #   presence_in = att[:datetime_in] if presence_in.blank?
            #   presence_out = att[:datetime_out] if presence_out.blank?
            # end
            # baca lembur awal
            # if presence_in.blank?
            #   if att[:period_shift].to_date == ot.period_shift.to_date+1.day
            #     presence_in = att[:datetime_in] if presence_in.blank?
            #     presence_out = att[:datetime_out] if presence_out.blank?
            #   end
            # end
            
            # check_ot_begin = TimeDifference.between(att[:datetime_in].to_datetime.strftime("%Y-%m-%d %H:%M:%S"), end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")).in_hours
            # check_ot_end   = TimeDifference.between(att[:datetime_out].to_datetime.strftime("%Y-%m-%d %H:%M:%S"), end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")).in_hours
            # if check_ot_begin > check_ot_end
            #   att.merge!(:kind=> "lembur akhir")
            # elsif check_ot_end > check_ot_begin
            #   att.merge!(:kind=> "lembur awal")
            # end


            # if att[:datetime_in].to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
            #   presence_in = att[:datetime_in]
            # end
            # if att[:datetime_out].to_datetime.strftime("%Y-%m-%d %H:%M:%S") >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
            #   presence_out = att[:datetime_out] if presence_out.blank?
            # end
          end
          # puts att_new
          # puts begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #  puts TimeDifference.between(presence_in.to_datetime.strftime("%Y-%m-%d %H:%M:%S"), end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")).in_hours if presence_out.present?
           
          # puts end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #  puts TimeDifference.between(presence_out.to_datetime.strftime("%Y-%m-%d %H:%M:%S"), end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")).in_hours if presence_out.present?
         
          # puts "------------"
          # att_log_array.each do |att|
          #   # if att[:period_shift].to_date == ot.period_shift.to_date
          #   # puts "[#{att[:period_shift]}] #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")} => #{att[:type_presence]}"
          #   # puts TimeDifference.between( ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S"), begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S")).in_hours if att[:type_presence] == 'in'
          #   # puts TimeDifference.between( ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S"), end_time.to_time.strftime("%Y-%m-%d %H:%M:%S")).in_hours if att[:type_presence] == 'out'
          #   # puts "-----------------------"
          #   # if att[:tr_date].to_date == ot.date.to_date
          #     # if ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                
          #     # if att[:tr_date].to_date == ot.date.to_date
          #       if att[:type_presence] == 'in'
          #         # diff_in_check = TimeDifference.between( ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S"), begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S")).in_hours
          #         # if diff_in_check < diff_in
          #         #   diff_in = diff_in_check 
          #         #   presence_in = ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #         # end
          #         # presensi masuk lebih kecil sama dengan jam lembur
          #         if ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S")
          #           presence_in = ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")

          #         end
          #         puts "   IN  [#{att[:period_shift]}] #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")} <= #{begin_time.to_time.strftime("%Y-%m-%d %H:%M:%S")} => #{diff_in}"
                  
          #       end
          #     # end
          #     # end
          #     # if ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #       if att[:type_presence] == 'out'
          #         diff_out_check = TimeDifference.between( ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S"), end_time.to_time.strftime("%Y-%m-%d %H:%M:%S")).in_hours
          #         if diff_out_check < diff_out
          #           diff_out = diff_out_check 
          #           presence_out = ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #         end
          #         puts "   OUT [#{att[:period_shift]}] #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")} >= #{end_time.to_time.strftime("%Y-%m-%d %H:%M:%S")} => #{diff_out}"
                  
          #       end
          #     # end
          #   # end
          # end
          # puts "------------"
          puts "[#{ot.date}] presence_in: #{presence_in}; presence_out: #{presence_out};"

          # if presence_in.present? and presence_in.to_datetime.strftime("%Y-%m-%d %H:%M:%S") > begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #   puts "[OT tidak terbaca] IN : #{begin_time}; actual: #{presence_in};"
          #   presence_in = nil
          # end
          # if presence_out.present? and presence_out.to_datetime.strftime("%Y-%m-%d %H:%M:%S") < end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
          #   puts "[OT tidak terbaca] OUT: #{end_time}; actual: #{presence_out};"
          #   presence_out = nil
          # end

          if presence_in.present? and presence_out.present?

            puts "IN #{presence_in.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} <= #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} = #{presence_in.to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
            # masih masalah
            if presence_in.to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
              presence_time_in = begin_time.to_time
            else
              presence_time_in = presence_in.to_time
            end
            puts "OUT #{presence_out.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} >= #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} = #{presence_out.to_datetime.strftime("%Y-%m-%d %H:%M:%S") >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
            if presence_out.to_datetime.strftime("%Y-%m-%d %H:%M:%S") >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
              # puts "jika presensi out #{presence_out.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} lebih dari schedule lembur out #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              # puts "#{ot.period_shift} add_ot #{presence_in.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} between #{end_time.to_time} => #{TimeDifference.between( begin_time.to_time, end_time.to_time).in_hours}"
              presence_time_out = end_time.to_time
              # count_ot += TimeDifference.between( begin_time.to_time, end_time.to_time).in_hours
            else
              # puts "#{ot.period_shift} add_ot #{presence_out.to_time} between #{begin_time.to_time} => #{TimeDifference.between( presence_out.to_time, begin_time.to_time).in_hours}"
              presence_time_out = presence_out.to_time
              # count_ot += TimeDifference.between( begin_time.to_time, presence_out.to_time).in_hours
            end
            puts "  presensi in => #{presence_time_in}"
            puts "  presensi out => #{presence_time_out}"
            puts "  lembur => #{TimeDifference.between(presence_time_in, presence_time_out).in_hours}"
            puts "--------------------------------------------------------"
            count_ot += TimeDifference.between(presence_time_in, presence_time_out).in_hours

            # count_ot -= 0.02 if count_ot > 0
          end
        when 'first'
          count_ot += 1
        when '4-7','8-11','5-8'
          case kind
          when '4-7'
            range = (4.0..7.9)
          when '5-8'
            range = (5.0..8.9)
          when '8-11'
            range = (8.0..11.9)
          end
          type_presence_in  = false
          type_presence_out = false
          att_log_array.each do |att|
            if att[:tr_date].to_date == ot.date.to_date and att[:type_presence] == 'in'
              puts "  in: #{att[:tr_date].to_date} == #{ot.date.to_date} => #{att[:tr_date].to_date == ot.date.to_date}"
              type_presence_in = true
            end
            if att[:tr_date].to_date == end_time.to_date and att[:type_presence] == 'out'
              # jika terdapat actual presensi lebih besar sama dengan schedule lembur keluar
              puts "#lembur akhir"
              puts "  actual: #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              puts "  schedule: #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} [OUT]"
              puts "  result: actual >= schedule => #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              if ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") >= end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                type_presence_out = true
                puts "  out: #{att[:tr_date].to_date} == #{end_time.to_date} => #{att[:tr_date].to_date == end_time.to_date}"
              end
            end

            # 2021-10-13 aden penambahan logic lembur awal
            if att[:tr_date].to_date == begin_time.to_date and att[:type_presence] == 'in'
              # jika terdapat actual presensi lebih kecil sama dengan schedule lembur masuk
              puts "#lembur awal"
              puts "  actual: #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              puts "  schedule: #{begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} [IN]"
              # puts "  schedule: #{end_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")} [OUT]"
              puts "  result: actual <= schedule => #{("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}"
              if ("#{att[:tr_date]} #{att[:tr_time]}").to_datetime.strftime("%Y-%m-%d %H:%M:%S") <= begin_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
                type_presence_out = true
                puts "  out: #{att[:tr_date].to_date} == #{begin_time.to_date} => #{att[:tr_date].to_date == begin_time.to_date}"
              end
            end
          end

          puts "range #{begin_time.to_time}, #{end_time.to_time}"
          puts "type_presence_in: #{type_presence_in}"
          puts "type_presence_out: #{type_presence_out}"
          if type_presence_in == true and type_presence_out == true
            puts "ok => #{range} === #{TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours} => #{range === TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours}"
            if range === TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours
              puts "#{TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours} => #{range === TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours}"
              count_ot += 1
            end
          end
          puts "-------------------------------------------"
          # puts "type_presence_in: #{type_presence_in}"
          # puts "type_presence_out: #{type_presence_out}"
          # puts "#{range === TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours}"
          # if HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'in', :date=> ot_date, :status=> 'active').present? and HrdAttendanceLog.where(:sys_plant_id=> plant_id, :hrd_employee_id=> employee_id, :type_presence=> 'out', :date=> end_time.to_date.strftime("%Y-%m-%d"), :status=> 'active').where("date_time >= ?", end_time.to_time ).present?
          #   if range === TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours
          #     count_ot += 1
          #   end
          # end
        when '11+','8+'
          case kind
          when '11+'
            hour = 11
          when '8+'
            hour = 8
          end
          if AttendanceLog.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :type_presence=> 'in', :date=> ot_date, :status=> 'active').present? and AttendanceLog.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :type_presence=> 'out', :date=> end_time.to_date.strftime("%Y-%m-%d"), :status=> 'active').where("date_time >= ?", end_time.to_time ).present?
            if TimeDifference.between( begin_time.to_time, end_time.to_time ).in_hours > hour
              count_ot += 1
            end
          end
        end


        # puts "count_ot => #{count_ot}"

        # kalau lembur lebih dari 4 sampe 5 jam ke potong setengah jam 
        # kalau lembur lebih dari 5 jam ke potong 1 jam
        # lembur dibulatkan (round down)

        if count_ot > 4.0 and count_ot < 5
          # count_ot -= 0.5
          # 2020-03-23 hasil OT jika dikurangi tidak sesuai dengan perhitungan manual
        elsif count_ot >= 6
        # elsif count_ot >= 5
          # kalau koding ini ditutup kesalahannya lebih banyak 150 yg ga sesuai
          count_ot -= 1
        end  
        summary_ot += count_ot
        x += 1    

        # puts "OT periode #{ot.date} => #{count_ot};"
      end
      # puts "x =>       #{x}"

      case kind
      when 'second'
        # ot jam kedua = total OT - OT jam pertama
        summary_ot -= x if (summary_ot - x) >= 0
      end
      return summary_ot
    end
  #perbaiki ---- end -----


	def report_3a0(plant_id, period_begin, period_end, employee_id) 
    employee_schedules = EmployeeSchedule.where(:employee_id=> employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date asc")
    attendences = AttendanceLog.where(:company_profile_id=> plant_id, :employee_id=> employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date_time asc") if employee_id.present?
              
    att_log = [] 
    count = 0 
    attendences.each do |att|
      att_log << {:att_id=> att.id, :empl_code=> att.id_number, :tr_date=> att.date.strftime("%Y-%m-%d"), :tr_time=> att.time.strftime("%H:%M:%S"), :date_time=> att.date_time, :acc_code=> att.mode_presence, :type_presence=> att.type_presence }
      count += 1
    end if attendences.present? 

    att_array = [] 
    att_log.each do |att| 
      period_shift = (att[:period_shift].present? ? att[:period_shift].to_date.strftime("%Y-%m-%d") : att[:tr_date]) 
      schedule = employee_schedules.find_by(:date=> period_shift)
      if period_shift.present?
        day_name = "#{period_shift.to_date.strftime('%A')}".downcase 
        schedule_att_in  = (day_name.present? ? (schedule.schedule["#{day_name}_in"] if schedule.present? and schedule.schedule.present?) : nil)
        schedule_att_out = (day_name.present? ? (schedule.schedule["#{day_name}_out"] if schedule.present? and schedule.schedule.present?) : nil)
      else
        schedule_att_in = nil
        schedule_att_out = nil
      end
      att_array << {
        :att_id=> att[:att_id], 
        :id_number=> att[:empl_code], 
        :period_shift=> period_shift, 
        :date=> att[:tr_date], 
        :time=> att[:tr_time], 
        :date_time=> att[:date_time], 
        :mode_presence=> att[:acc_code], 
        :type_presence=> att[:type_presence],
        :schedule_att_in=> (schedule_att_in.present? ? schedule_att_in.to_time.strftime("%H:%M:%S") : nil), 
        :schedule_att_out=> (schedule_att_out.present? ? schedule_att_out.to_time.strftime("%H:%M:%S") : nil), 
      } 
    end 
    (0..count).each do |c| 
      if att_array[c+1].present? 
        if att_array[c][:date] == att_array[c+1][:date] and att_array[c][:date] == att_array[c-1][:date]
          att_array[c-1].merge!(:double_record=> true ) if att_array[c].present? 
        elsif att_array[c][:type_presence] == att_array[c+1][:type_presence] or att_array[c][:date] != att_array[c][:period_shift]
          att_array[c].merge!(:double_record=> true ) if att_array[c].present? 
        else 
          att_array[c].merge!(:double_record=> false ) if att_array[c].present? 
        end 
      end 
    end 

    period_att_array = [] 
    (period_begin..period_end).each do |date| 
      id_number = nil
      wrong1 = false 
      wrong2 = false 
      att_in = nil 
      att_out = nil 
      att_datetime_in = nil
      att_datetime_out = nil
      working_hour = 0 
      (0..count).each do |c| 
        id_number = att_array[c][:id_number] if att_array[c].present? 
        if att_array[c][:date].to_date == date.to_date 
          if att_array[c-1][:date].to_date != att_array[c][:date].to_date and att_array[c][:date].to_date != att_array[c+1][:date].to_date 
            wrong1 = true 
          end if att_array[c+1].present? and att_array[c-1].present? 
          if att_array[c-1][:date].to_date == att_array[c][:date].to_date and att_array[c][:date].to_date == att_array[c+1][:date].to_date 
            wrong2 = true 
          end if att_array[c+1].present? and att_array[c-1].present? 

          # puts "#{date} - #{att_array[c][:date_time]} - #{att_array[c][:type_presence]}" 
          att_in = att_array[c][:time] if att_array[c][:type_presence] == 'in' 
          att_datetime_in = att_array[c][:date_time] if att_array[c][:type_presence] == 'in' 
          att_out = att_array[c][:time] if att_array[c][:type_presence] == 'out' 
          att_datetime_out = att_array[c][:date_time] if att_array[c][:type_presence] == 'out' 

          if att_array[c][:type_presence] != att_array[c+1][:type_presence] and att_array[c+1][:type_presence] == 'out' 
            att_out = att_array[c+1][:time] if att_array[c+1][:type_presence] == 'out' 
            att_datetime_out = att_array[c+1][:date_time] if att_array[c+1][:type_presence] == 'out' 
          end if att_array[c+1].present? 
        end if att_array[c].present? 
      end 

      if att_datetime_in.present? and att_datetime_out.present? 
        working_hour = TimeDifference.between(att_datetime_in, att_datetime_out).in_hours 
        if att_datetime_out.strftime("%Y-%m-%d")  > att_datetime_in.strftime("%Y-%m-%d") 
          overday = true 
        else 
          overday = false 
        end 
      end

      period_att_array << {
        :id_number=> id_number, :period_shift=> date.to_date.strftime("%Y-%m-%d"), 
        :wrong_date=> wrong1, :double_date=> wrong2,
        :att_in=> att_in, :att_out=> att_out, :working_hour=> working_hour, :att_out_overday=> overday
      } 
    end 

    return period_att_array
  end

  #perbaiki ---- start -----
    # perbaikan report dashboard
    def schedule_without_hk(plant_id, period_yyyymm, dept_id, employee_id)  
      kind          = 'schedule_without_hk'
      puts kind
      plant         = plant_id
      period        = (period_yyyymm.present? ? ("#{period_yyyymm}01").to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d"))
      period_begin  = period.to_date+20.day if period.present?
      period_end    = period.to_date+1.month+19.day if period.present?
      puts "period_begin: #{period_begin}; period_end: #{period_end}"
      
      # work_status      = HrdWorkStatus.where(:payroll=> 1, :status=> 'active')
      # employees        = HrdEmployee.where(:hrd_employee_payroll_id=> plant, :hrd_work_status_id=> work_status.select(:id))
      employees        = HrdEmployee.where(:hrd_employee_payroll_id=> plant)
      # employees        = HrdEmployee.where(:hrd_employee_payroll_id=> plant, :status=> 'active').where(:hrd_work_status_id=> work_status.select(:id))
      
      employees        = employees.where(:department_id=> dept_id) if dept_id.present?
      employees        =  employees.where(:id=> employee_id) if employee_id.present?

      attendance_users = AttendanceUser.where(:employee_id=> employees.select(:id), :company_profile_id=> plant) if employees.present?
      # attendance_logs  = HrdAttendanceLog.where(:sys_plant_id=> plant, :hrd_employee_id=> attendance_users.select(:hrd_employee_id), :status=> 'active').where("date between ? and ?", period_begin, period_end) if attendance_users.present?
      
      employees_lists  = []   
      schedule = Schedule.where(:status=> 'active').where.not(:monday_in=> nil) 
      EmployeeSchedule.where(:schedule_id=> schedule.select(:id), :employee_id=> attendance_users.select(:employee_id)).where("date between ? and ?", period_begin, period_end).where(:status=> 'active').each do |a|
        # puts "date: #{a.date}; #{a.hrd_employee.name if a.hrd_employee.present?}"
        # if employees_lists.include?(a.hrd_employee_id)
        #   # jika ada maka tidak akan proses 
        # else
          att_user = AttendanceUser.find_by(:company_profile_id=> plant, :employee_id=> a.employee_id, :status=> 'active')
          if att_user.present?
            att_log = AttendanceLog.where(:company_profile_id=> plant, :status=> 'active', :date=> a.date).find_by(:employee_id=> a.employee_id)
            if att_log.blank?
              puts "date: #{a.date}; [#{a.employee_id}] #{a.employee.name if a.employee.present?} log tidak ada"
              # employees_lists << a.hrd_employee_id unless employees_lists.include?(a.hrd_employee_id)
              # legal_id  = a.hrd_employee.hrd_employee_legal_id
              employee_presence = EmployeePresence.find_by(:company_profile_id=> plant, :kind=> kind, :employee_id=> a.employee_id, :period=> period_yyyymm, :date=> a.date)
              if employee_presence.present?
                employee_presence.update_columns(:id_number=> att_user.id_number, :status=> 'active') if employee_presence.status == 'remove'
              else
                EmployeePresence.create(
                  :company_profile_id=> plant, 
                  :kind=> kind, 
                  :employee_id=> a.employee_id, :id_number=> att_user.id_number,
                  :period=> period_yyyymm, 
                  :date=> a.date,
                  :status=> 'active', :note=> nil,
                  :created_at=> DateTime.now(),
                  :created_by=> 1
                )
              end
            else
              puts "date: #{a.date}; [#{a.employee_id}] #{a.employee.name if a.employee.present?}"
              employee_presence = EmployeePresence.find_by(:company_profile_id=> plant, :kind=> kind, :employee_id=> a.employee_id, :period=> period_yyyymm, :date=> a.date)
              if employee_presence.present?
                if employee_presence.status == 'active'
                  employee_presence.update_columns(:id_number=> att_user.id_number, :status=> 'remove') 
                  puts "hapus"
                end
              end
            end
          else
            puts "user tidak ada"
          end
        # end
      end if attendance_users.present?
      if employees_lists.length > 0
        employee_list = employees_lists.split(", ")
      end
    end
    def hk_without_schedule(plant_id, period_yyyymm, dept_id, employee_id)
      kind          = 'hk_without_schedule'
      puts kind
      plant         = plant_id
      period        = (period_yyyymm.present? ? ("#{period_yyyymm}01").to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d"))
      period_begin  = period.to_date+20.day if period.present?
      period_end    = period.to_date+1.month+19.day if period.present?
      puts "period_begin: #{period_begin}; period_end: #{period_end}"
      
      # work_status      = HrdWorkStatus.where(:payroll=> 1, :status=> 'active')
      # employees        = HrdEmployee.where(:hrd_employee_payroll_id=> plant, :status=> 'active').where(:hrd_work_status_id=> work_status.select(:id))
      employees        = Employee.where(:status=> 'active')
      
      employees        = employees.where(:department_id=> dept_id) if dept_id.present?

      attendance_users = AttendanceUser.where(:employee_id=> (employee_id.present? ? employee_id : employees.select(:id)), :company_profile_id=> plant) if employees.present?
      
      employees_lists  = []  
      attendance_users.each do |att_user|
        AttendanceLog.where(:company_profile_id=> plant, :employee_id=> att_user.employee_id).where("date between ? and ?", period_begin, period_end).each do |a|        
          # puts "[#{a.sys_plant_id}] #{a.id_number} => #{a.date} #{a.type_presence}"
          employee_presence = EmployeePresence.find_by(:company_profile_id=> plant, :kind=> kind, :employee_id=> a.employee_id, :period=> period_yyyymm, :date=> a.date)
            
          if a.status == 'active'
            # legal_id  = a.hrd_employee.hrd_employee_legal_id
            if EmployeeSchedule.where(:company_profile_id=> plant, :employee_id=> a.employee_id, :date=> a.date, :status=> 'active').blank?
            
              puts "date: #{a.date}; [#{a.employee_id}] #{a.employee.name if a.employee.present?} tidak ada schedule"
              employees_lists << a.employee_id unless employees_lists.include?(a.employee_id)
              if employee_presence.present?
                employee_presence.update_columns(:id_number=> a.id_number)
              else
                EmployeePresence.create(
                  :company_profile_id=> plant, 
                  :kind=> kind, 
                  :employee_id=> a.employee_id, :id_number=> a.id_number,
                  :period=> period_yyyymm, 
                  :date=> a.date,
                  :status=> 'active', :note=> nil,
                  :created_at=> DateTime.now(),
                  :created_by=> 1
                )
              end
            end
          else
            employee_presence.update_columns(:status=> 'remove') if employee_presence.present?
          end
        end
      end if attendance_users.present?    
    end

    def att_dupplicate(plant_id, period_yyyymm, dept_id, kind, employee_id)
      period = period_yyyymm.present? ? (period_yyyymm+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      period_begin = period.to_date+20.day if period.present?
      period_end = period.to_date+1.month+19.day if period.present?
      puts "period_begin: #{period_begin}; period_end: #{period_end}"
      
      # work_status = HrdWorkStatus.where(:payroll=> 1, :status=> 'active')
      # employees = HrdEmployee.where(:hrd_employee_payroll_id=> plant_id, :status=> 'active').where(:hrd_work_status_id=> work_status.select(:id))
      employees = Employee.where(:status=> 'active')
      employees = employees.where(:department_id=> dept_id) if dept_id.present?
      attendance_users = AttendanceUser.where(:employee_id=> (employee_id.present? ? employee_id : employees.select(:id)), :company_profile_id=> plant_id) if employees.present?
      attendance_logs = AttendanceLog.where(:company_profile_id=> plant_id, :employee_id=> attendance_users.select(:employee_id), :status=> 'active').where("date between ? and ?", period_begin, period_end) if attendance_users.present?
        # puts attendance_users.order("name asc").map { |e| "[#{e.id_number}] - #{e.hrd_employee_id} - #{e.name}" }
      duplicate_mode_same_day_employee_id = []
      attendance_logs.where(:type_presence=> kind ).group(:date, :employee_id, :company_profile_id).having("count(*) > 1").each do |a|
        duplicate_mode_same_day_employee_id << a.employee_id  unless duplicate_mode_same_day_employee_id.include?(a.employee_id)
      end if attendance_logs.present?
      employee_list = duplicate_mode_same_day_employee_id.split(", ") if duplicate_mode_same_day_employee_id.length > 0
      
      attendance_logs = attendance_logs.where(:employee_id=> employee_list).order("id_number asc, date_time asc")
      if employee_list.present?
        EmployeePresence.where(:company_profile_id=> plant_id, :kind=> "duplicate_#{kind}", :period=> period_yyyymm).each do |a|
          a.update_columns(:status=> 'remove') if a.status == 'active'
        end
        att_array = []
        count = 0
        attendance_logs.each do |att|
          att_array << {
            :id=> att.id,
            :employee_id => att.employee_id, 
            :employee_name => "#{att.employee.name if att.employee.present?}", 
            :department_name => "#{att.employee.sys_department.name if att.employee.present? and att.employee.department.present?}",
            :id_number=> att.id_number,
            :period_shift=> att.date,
            :date=> att.date_time.strftime("%Y-%m-%d"),
            :time=> att.date_time.strftime("%H:%M:%S"),
            :mode_presence=> att.mode_presence,
            :type_presence=> att.type_presence,
            :double_date=> false,
            :possibly_trouble=> false,
            :wrong_mode=> false
          }
          count += 1
        end if attendance_logs.present?

        (0..count).each do |c|

          if att_array[c+1].present? and att_array[c+1][:id_number] == att_array[c][:id_number] and att_array[c][:type_presence] == kind
            # case att_array[c][:mode_presence]
            # when 'aTt', 'eXt'
            #   att_array[c][:possibly_trouble] = true
            # end
            # puts "[#{att_array[c][:id_number]}] #{att_array[c][:period_shift]} => #{att_array[c][:type_presence]}"
            if att_array[c][:type_presence] == att_array[c+1][:type_presence] #and att_array[c][:period_shift] == att_array[c+1][:period_shift]
              # att_array[c-2][:possibly_trouble] = true if att_array[c-2].present?
              # att_array[c-1][:possibly_trouble] = true if att_array[c-1].present?
              # att_array[c][:possibly_trouble] = true
              # att_array[c+1][:possibly_trouble] = true if att_array[c+1].present?
              # att_array[c+2][:possibly_trouble] = true if att_array[c+2].present?
              # if att_array[c][:period_shift] != att_array[c+1][:period_shift]
                att_array[c][:wrong_mode] = true
                att_array[c+1][:wrong_mode] = true
              # end
            end

            #  1 hari double in dan out
            if att_array[c].present? and att_array[c+1].present? and att_array[c+2].present? and att_array[c+3].present?
              if att_array[c+1][:id_number] == att_array[c][:id_number] and att_array[c+1][:id_number] == att_array[c+2][:id_number] and att_array[c+2][:id_number] == att_array[c+3][:id_number]
                if att_array[c+1][:period_shift] == att_array[c][:period_shift] and att_array[c+1][:period_shift] == att_array[c+2][:period_shift] and att_array[c+2][:period_shift] == att_array[c+3][:period_shift]
                  # att_array[c-2][:possibly_trouble] = true if att_array[c-2].present?
                  # att_array[c-1][:possibly_trouble] = true if att_array[c-1].present?
                  # att_array[c][:possibly_trouble] = true
                  # att_array[c+1][:possibly_trouble] = true if att_array[c+1].present?
                  # att_array[c+2][:possibly_trouble] = true if att_array[c+2].present?
                  # att_array[c+3][:possibly_trouble] = true if att_array[c+3].present?
                  # att_array[c+4][:possibly_trouble] = true if att_array[c+4].present?
                  # att_array[c+5][:possibly_trouble] = true if att_array[c+5].present?

                  att_array[c][:wrong_mode] = true
                  att_array[c+1][:wrong_mode] = true if att_array[c+1].present?
                  att_array[c+2][:wrong_mode] = true if att_array[c+2].present?
                  att_array[c+3][:wrong_mode] = true if att_array[c+3].present?
                end
              end
            end
          end

        end
      end
      att_array = att_array.select{ |item| item[:wrong_mode] == true } if att_array.present?

      att_array.each do |a|
        puts a[:employee_name]
        if a[:type_presence] == kind
          employee_presence = EmployeePresence.find_by(:company_profile_id=> plant_id, :kind=> "duplicate_#{kind}", :employee_id=> a[:employee_id], :period=> period_yyyymm, :date=> a[:period_shift])
          if employee_presence.present?
            employee_presence.update_columns(:id_number=> a[:id_number], :status=> 'active')
          else
            EmployeePresence.create(
              :company_profile_id=> plant_id, 
              :kind=> "duplicate_#{kind}", 
              :employee_id=> a[:employee_id], :id_number=> a[:id_number],
              :period=> period_yyyymm, 
              :date=> a[:period_shift],
              :status=> 'active', :note=> nil,
              :created_at=> DateTime.now(),
              :created_by=> 1
            )
          end
        end
      end if att_array.present?
    end

    def att_in_without_out(plant_id, period_yyyymm, dept_id, employee_id)
      period = period_yyyymm.present? ? (period_yyyymm+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      period_begin = period.to_date+20.day if period.present?
      period_end = period.to_date+1.month+19.day if period.present?
      puts "period_begin: #{period_begin}; period_end: #{period_end}"

      # work_status = HrdWorkStatus.where(:payroll=> 1, :status=> 'active')
      # employees = HrdEmployee.where(:hrd_employee_payroll_id=> plant_id, :status=> 'active').where(:hrd_work_status_id=> work_status.select(:id))
      employees = Employee.where(:status=> 'active')
      employees = employees.where(:department_id=> dept_id) if dept_id.present?
      attendance_users = AttendanceUser.where(:employee_id=> (employee_id.present? ? employee_id : employees.select(:id)), :company_profile_id=> plant_id) if employees.present?
      
      attendance_users.each do |att_user|
        (period_begin..period_end).each do |date|
          att_in  = AttendanceLog.find_by(:company_profile_id=> plant_id, :employee_id=> att_user.employee_id, :status=> 'active', :date=> date, :type_presence=> 'in')
          att_out = AttendanceLog.find_by(:company_profile_id=> plant_id, :employee_id=> att_user.hrd_employee_id, :status=> 'active', :date=> date, :type_presence=> 'out')
          if (att_in.present? and att_out.present?) or (att_in.blank? and att_out.blank?)
            puts "[#{date}] #{att_user.employee_id} good"
            EmployeePresence.where(:company_profile_id=> plant_id, :employee_id=> att_user.employee_id, :period=> period_yyyymm, :date=> date).each do |employee_presence|
              employee_presence.update_columns(:status=> 'remove')
            end
          else
            if att_in.present? and att_out.blank?
              puts "[#{date}] #{att_user.employee_id} tidak ada out"

              employee_presence = EmployeePresence.find_by(:company_profile_id=> plant_id, :kind=> "att_in_without_out", :employee_id=> att_user.employee_id, :period=> period_yyyymm, :date=> date)
              if employee_presence.present?
                employee_presence.update_columns(:status=> 'active')
              else
                EmployeePresence.create(
                  :company_profile_id=> plant_id, 
                  :kind=> "att_in_without_out", 
                  :employee_id=> att_user.employee_id, :id_number=> att_user.id_number,
                  :period=> period_yyyymm, 
                  :date=> date,
                  :status=> 'active', :note=> nil,
                  :created_at=> DateTime.now(),
                  :created_by=> 1
                )
              end
            elsif att_out.present? and att_in.blank?
              puts "[#{date}] #{att_user.employee_id} tidak ada in"

              employee_presence = EmployeePresence.find_by(:company_profile_id=> plant_id, :kind=> "att_out_without_in", :employee_id=> att_user.employee_id, :period=> period_yyyymm, :date=> date)
              if employee_presence.present?
                employee_presence.update_columns(:status=> 'active')
              else
                EmployeePresence.create(
                  :company_profile_id=> plant_id, 
                  :kind=> "att_out_without_in", 
                  :employee_id=> att_user.employee_id, :id_number=> att_user.id_number,
                  :period=> period_yyyymm, 
                  :date=> date,
                  :status=> 'active', :note=> nil,
                  :created_at=> DateTime.now(),
                  :created_by=> 1
                )
              end
            end
          end
        end
      end
    end

    def working_hour_actual(plant_id, period_yyyymm, kind, dept_id, employee_id)
      # mencari jam kerja yg lebih dari 20 dan dibawah 2 jam
      puts kind
      plant         = plant_id

      period        = (period_yyyymm.present? ? ("#{period_yyyymm}01").to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d"))
      period_begin  = period.to_date+20.day if period.present?
      period_end    = period.to_date+1.month+19.day if period.present?
      puts "period_begin: #{period_begin}; period_end: #{period_end}"

      
      # work_status      = HrdWorkStatus.where(:payroll=> 1, :status=> 'active')
      # employees        = HrdEmployee.where(:hrd_employee_payroll_id=> plant, :status=> 'active').where(:hrd_work_status_id=> work_status.select(:id))
      employees        = Employee.where(:status=> 'active')
      
      employees        = employees.where(:department_id=> dept_id) if dept_id.present?

      attendance_users = AttendanceUser.where(:employee_id=> employees.select(:id), :company_profile_id=> plant) if employees.present?
      attendance_users.each do |att_user|
        attendences = AttendanceLog.where(:company_profile_id=> plant, :employee_id=> att_user.employee_id, :status=> 'active')
                
        count = 0
        att_array  = []
        attendences.order("date_time asc").each do |att|
          att_array << {:employee_id=> att.employee_id, :id_number=> att.id_number, :date=> att.date.strftime("%Y-%m-%d"), :time=> att.time.strftime("%H:%M:%S"), :date_time=> att.date_time.strftime("%Y-%m-%d %H:%M:%S"), :type_presence=> att.type_presence }
          count += 1
        end
        att_array_new  = []
        (0..count).each do |c|
          if att_array[c+1].present?
            if att_array[c][:type_presence] == 'in' and att_array[c+1][:type_presence] == 'out'
              working_hour_actual = 0
              working_hour_actual += TimeDifference.between(att_array[c][:date_time], att_array[c+1][:date_time]).in_hours
              
              case kind 
              when 'working_hour_over_20h'
                att_array_new << {:employee_id=> att_array[c][:employee_id], :id_number=> att_array[c][:id_number], :date=> att_array[c][:date], :att_in=> att_array[c][:date_time], :att_out=> att_array[c+1][:date_time], :working_hour_actual=> working_hour_actual } if working_hour_actual > 20
              when 'working_hour_under_2h'
                att_array_new << {:employee_id=> att_array[c][:employee_id], :id_number=> att_array[c][:id_number], :date=> att_array[c][:date], :att_in=> att_array[c][:date_time], :att_out=> att_array[c+1][:date_time], :working_hour_actual=> working_hour_actual } if working_hour_actual >= 0 and working_hour_actual <= 2
              end
            end
          end
        end

        att_array_new.each do |att|
          employee_presence = EmployeePresence.find_by(:company_profile_id=> plant, :kind=> kind, :employee_id=> att[:employee_id], :period=> period_yyyymm, :date=> att[:date])
          if employee_presence.present?
            employee_presence.update_columns(:id_number=> att[:id_number])
          else
            EmployeePresence.create(
              :company_profile_id=> plant, 
              :kind=> kind, 
              :employee_id=> att[:employee_id], :id_number=> att[:id_number],
              :period=> period_yyyymm, 
              :date=> att[:date],
              :status=> 'active', :note=> nil,
              :created_at=> DateTime.now(),
              :created_by=> 1
            )
          end
        end

      end
    end
  #perbaiki ---- end -----

  def merge_attendance(plant_id, dept_id, period_begin, period_end, employee_id) 
    # tarik berdasarkan lokasi payroll
    a  = DateTime.now()
    period_begin = period_begin.to_date-1.days
    period_end = period_end.to_date+1.days

    # list_users = []
    # case plant_id.to_i
    # when 3, 4
    #   AbsensiHabsen.where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc").group(:empl_code).each do |att|
    #     list_users << { :empl_code=> att.empl_code }
    #   end
    #   # get finger print
    #   AbsensiFpabsen.where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc").group(:empl_code).each do |att|
    #     list_users << { :empl_code=> att.empl_code }
    #   end

    #   # get dari komputer mesin produksi
    #   AbsensiPcabsen.where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc").group(:empl_code).each do |att|
    #     list_users << { :empl_code=> att.empl_code }
    #   end
    # when 2
    #   AbsensiHabsenTechno.where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc").group(:empl_code).each do |att|
    #     case att.empl_code.to_s.length
    #     when 1
    #       att_empl_code = "000#{att.empl_code}"
    #     when 2
    #       att_empl_code = "00#{att.empl_code}"
    #     when 3
    #       att_empl_code = "0#{att.empl_code}"
    #     else
    #       att_empl_code = "#{att.empl_code}"
    #     end
    #     list_users << { :empl_code=> att.empl_code }
    #   end

    #   # get dari komputer mesin produksi
    #   AbsensiPcabsenTechno.where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc").group(:empl_code).each do |att|
    #     list_users << { :empl_code=> att.empl_code }
    #   end

    # end

    user_unregistered = []
    # att_users = HrdAttendanceUser.where(:sys_plant_id=> plant_id, :status=> 'active')
    # list_users.each do |list_user|
    #   list_user_exist = false
    #   att_users.each do |att_user|
    #     if list_user[:empl_code].to_i == att_user.id_number.to_i
    #       list_user_exist = true
    #     end
    #   end
    #   user_unregistered << {:hrd_employee_id=> nil, :empl_code=> list_user[:empl_code]} if list_user_exist == false
    #   # user_unregistered <<  list_user[:empl_code]  if list_user_exist == false
    # end

    # 3470, 2890, 2822, 3501, 3448, 3076, 1813, 1404,1821, 2537, 2652, 3475,3192,3046,2925, 3404, 2695, 2706, 2696, 3167, 3476, 3129, 30, 3518, 3502, 164, 1807, 3010,1667
    records = Employee.where(:company_profile_id=> plant_id, :department_id=> dept_id)
    records = records.where(:id=> employee_id) if employee_id.present?
    records.order("name asc").each do |employee|
      # 2020-04-21 - fiqih safitri habis kontrak 2020-02-21 tapi masuk lagi dengan kontrak baru 2020-04-21 tapi dari jeda tersebut ada masuk pake HK lama
      # jadi filter dibawah tidak bisa dipakai
      # case employee.hrd_work_status_id.to_i
      # when 7, 11, 10
      #   # 7, 11 => status Tetap
      #   # 10 => status outsource
      # else
      #   if employee.contract_end.present? and employee.contract_end < period_begin
      #     HrdAttendanceUser.where(:hrd_employee_id=> employee.id, :status=> 'active').each do |att_user|
      #       att_user.update_columns(:status=> 'suspend')
      #       puts "Habis Kontrak #{employee.contract_end}"
      #     end
      #   end
      # end

      att_users = AttendanceUser.where(:employee_id=> employee.id, :status=> 'active')
      if att_users.present?
        puts 'masuk'
        att_log_array = []
        original_attendances = []
        original_manual_attendances = []
        att_user_id_number = nil
        att_users.each do |att_user|
          case att_user.company_profile_id.to_i
          when 1
            ## dibawah ini untuk tarik absen dari mesin handkey
            # att_provital = AbsensiHabsen.where(:empl_code=> att_user.id_number).where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc") 
            # original_attendances += att_provital if att_provital.present?

            # get finger print
            att_provital_fp = AbsensiFpabsen.where(:empl_code=> att_user.id_number, :loc_code=>'BWXP201160769').where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
            original_attendances += att_provital_fp if att_provital_fp.present?

            att_manual_provital = ManualPresence.where(:company_profile_id=> att_user.company_profile_id, :status=> 'approved', :id_number=> att_user.id_number).where("date between ? and ?", period_begin, period_end).order("date_time asc")
            original_manual_attendances += att_manual_provital if att_manual_provital.present?
          end
          att_user_id_number = att_user.id_number if att_user.company_profile_id.to_i == employee.company_profile_id.to_i
        end

        att_users.each do |att_user|
          # don't use status active
          AttendanceLog.where(:company_profile_id=> employee.company_profile_id, :employee_id=> employee.id).where("date between ? and ?", period_begin, period_end).order("date_time asc").each do |att|
            att_log_array << {
              :id=> att.id,
              :company_profile_id=> att.company_profile_id,
              :loc_code=> att.loc_code,
              :possibly_wrong_push=> att.possibly_wrong_push,
              :without_repair_period_shift=> att.without_repair_period_shift,
              :employee_id=> att.employee_id,
              :date=> att.date.to_date.strftime("%Y-%m-%d"),
              :time=> att.time.to_datetime.strftime("%H:%M:%S"),
              :date_time=> att.date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S"),
              :id_number=> att.id_number,
              :mode_presence=> att.mode_presence,
              :type_presence=> att.type_presence,
              :status=> att.status,
              :note=> att.note
            }
          end
          puts "#{att_user.id_number} - #{att_user.employee_id} - #{att_user.company_profile_id} - #{employee.name}"
          # case att_user.sys_plant_id.to_i
          # when 3, 4
          #   original_attendances = AbsensiHabsen.where(:empl_code=> att_user.id_number).where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
          # when 2
          #   original_attendances = AbsensiHabsenTechno.where(:empl_code=> att_user.id_number).where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
          # end

          count = 0
          att_array  = []
          original_attendances.sort { |a, b| [a['tr_date'], a['tr_time']] <=> [b['tr_date'], b['tr_time']] }.each do |att|            
            case att.empl_code.to_s.length
            when 1
              att_empl_code = "000#{att.empl_code}"
            when 2
              att_empl_code = "00#{att.empl_code}"
            when 3
              att_empl_code = "0#{att.empl_code}"
            else
              att_empl_code = "#{att.empl_code}"
            end
            puts att_empl_code

            case att.acc_code.to_i
            when 4, 9
              puts "penambahan user di mesin HK"
            else
              case att.acc_code.to_i
              when 1
                acc_code = 'Att'
              else
                acc_code = 'Ext'
              end
              att_array << {:loc_code=> att.loc_code, :manual_presence=> false, :empl_code=> att_empl_code, :tr_date=> att.tr_date.strftime("%Y-%m-%d"), :tr_time=> att.tr_time.strftime("%H:%M:%S"), :acc_code=> acc_code }
              count += 1
            end
            # puts "[#{att.empl_code}] #{att.tr_date} - #{acc_code}"
          end

          original_manual_attendances.sort { |a, b| [a['date_time']] <=> [b['date_time']] }.each do |att_manual|
            case att_manual.type_presence
            when 'in'
              acc_code = 'Att'
            else
              acc_code = 'Ext'
            end
            att_array << {:loc_code=> "", :manual_presence=> true, :empl_code=> att_manual.id_number, :tr_date=> att_manual.date_time.strftime("%Y-%m-%d"), :tr_time=> att_manual.date_time.strftime("%H:%M:%S"), :acc_code=> acc_code }
            count += 1
          end
          # puts "--------------------------------------"
          # puts att_array
          puts "precompile_attendance ================================================ start "
          att_array = att_array.sort_by{ |t| [t[:tr_date], t[:tr_time]] }  
          # puts att_array
          att_array = precompile_attendance(count, att_array, employee, att_user)
          puts "precompile_attendance ================================================ end "
          # perbaikan mode_presence
          # puts att_array
          att_array.each do |att|
            note = nil
            case att[:acc_code_b]
            when 'Att'
              if att[:manual_presence] == true
                mode_presence = 'aTt'
                note = 'manual update'
              else
                if att[:acc_code] != att[:acc_code_b]
                  mode_presence = 'att'
                else
                  mode_presence = 'Att'
                end
              end
              type_presence = 'in'
            else
              if att[:manual_presence] == true
                mode_presence = 'eXt'
                note = 'manual update'
              else
                if att[:acc_code] != att[:acc_code_b]
                  mode_presence = 'ext'
                else
                  mode_presence = 'Ext'
                end
              end
              type_presence = 'out'
            end

            possibly_wrong_push = att[:possibly_wrong_push]
            # if "#{att[:tr_date]} #{att[:tr_time]}".to_time < "#{att[:tr_date]} 02:00:00".to_time
            #   puts "#{att[:tr_date]} #{att[:tr_time]}".to_time
            #   date_shift = att[:tr_date].to_date-1.days
            # else
            #   date_shift = att[:tr_date]
            # end

            date_shift = (att[:period_shift].present? ? att[:period_shift] : att[:tr_date])
            att_log_array_exist = false
            att_log_array.each do |att_log|
              if att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S") == "#{att[:tr_date]} #{att[:tr_time]}"
                puts "attendance_log_id: #{att_log[:id]}"
                  puts "without_repair_period_shift: #{att_log[:without_repair_period_shift]}"
                  puts "company_profile_id: #{att_log[:company_profile_id]}"
                  puts "note: #{att_log[:note]} != #{note} => #{att_log[:note] != note}"
                  puts "date: #{att_log[:date].to_date.strftime("%Y-%m-%d")} != #{date_shift.to_date.strftime("%Y-%m-%d")} => #{att_log[:date].to_date.strftime("%Y-%m-%d") != date_shift.to_date.strftime("%Y-%m-%d")}"
                  puts "date_time: #{att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S")} != #{att[:tr_date]} #{att[:tr_time]}"
                  puts "mode_presence: #{att_log[:mode_presence]} != #{mode_presence} => #{att_log[:mode_presence] != mode_presence} "
                  puts "type_presence: #{att_log[:type_presence]} != #{type_presence} => #{att_log[:type_presence] != type_presence}"
                  puts "possibly_wrong_push: #{att_log[:possibly_wrong_push]} != #{possibly_wrong_push} => #{att_log[:possibly_wrong_push] != possibly_wrong_push}"
                  
                if att_log[:note] != note or att_log[:date].to_date.strftime("%Y-%m-%d") != date_shift.to_date.strftime("%Y-%m-%d") or att_log[:mode_presence] != mode_presence or att_log[:type_presence] != type_presence or att_log[:possibly_wrong_push] != possibly_wrong_push
                  
                  check = AttendanceLog.find_by(:id=> att_log[:id])
                  if check.present?
                    if att_log[:without_repair_period_shift].to_i == 1
                      check.update_columns(
                        :loc_code=> att_log[:loc_code],
                        :possibly_wrong_push=> possibly_wrong_push,
                        :note=> note
                        )
                      puts "without_repair_period_shift"
                    else
                      check.update_columns(
                        :loc_code=> att_log[:loc_code],
                        :date=> date_shift,
                        :possibly_wrong_push=> possibly_wrong_push,
                        :mode_presence=> mode_presence,
                        :type_presence=> type_presence,
                        :note=> note
                        )
                      puts "#{check.possibly_wrong_push}"
                    end
                    puts "update attendance_log_id: #{att_log[:id]}"
                  end
                end
                att_log_array_exist = true
              end
            end

            if att_log_array_exist == false
              puts "[#{att_user_id_number}] employee_id: #{att_user.employee_id} => Create date: #{date_shift} => #{att[:tr_date]} #{att[:tr_time]}"
                AttendanceLog.create(
                  :loc_code=> att[:loc_code],
                  :company_profile_id=> employee.company_profile_id, 
                  :employee_id=> att_user.employee_id, 
                  :possibly_wrong_push=> possibly_wrong_push,
                  :date=> date_shift,
                  :time=> att[:tr_time],
                  :date_time=> "#{att[:tr_date]} #{att[:tr_time]}",
                  :id_number=> att_user_id_number,
                  :mode_presence=> mode_presence,
                  :type_presence=> type_presence,
                  :status=> 'active',
                  :note=> note,:updated_at=> DateTime.now(), :updated_by=> 1
                )
            end
            puts "-----------------------------"
            # puts "[#{att[:empl_code]}] #{att[:tr_date]} - #{att[:acc_code]} / #{mode_presence}"
          end
          # 20200427: aden - update report dipisah task
          # puts "update report ================================================== start"
          # update_report(employee.hrd_employee_payroll_id, period_begin.to_date.strftime("%Y%m"), att_user.id_number)
          # puts "update report ================================================== end"
        end
      else
        puts 'tidak masuk'
        if employee.status == 'active'
          puts "#{plant_id} - tidak terdaftar: employee_id=> #{employee.id}"       
          user_unregistered << {:employee_id=> employee.id, :empl_code=> nil}
        end
        # HrdAttendanceUser.create(
        #   :sys_plant_id=> plant_id,
        #   :hrd_employee_id=> employee.id,
        #   :sys_department_id=> dept_id,
        #   :id_number=> employee.pin,
        #   :name=> employee.name,
        #   :status=> 'active',
        #   :created_by=> 1, :created_at=> DateTime.now()

        #   ) if employee.present? and employee.pin.present?
      end
    end
    puts "----------------------------------"
    puts user_unregistered
    puts "----------------------------------"
    b = DateTime.now()
    puts "[#{dept_id}] start: #{a} between #{b} => #{TimeDifference.between(a, b).in_minutes}"
  end

  #perbaiki ---- start -----
    def get_attendance(plant_id, dept_id, period_begin, period_end) 
      a  = DateTime.now()
      period_begin = period_begin.to_date-1.days
      period_end = period_end.to_date+1.days

      # 3470, 2890, 2822, 3501, 3448, 3076, 1813, 1404,1821, 2537, 2652, 3475,3192,3046,2925, 3404, 2695, 2706, 2696, 3167, 3476, 3129, 30, 3518, 3502, 164, 1807, 3010,1667
      # records = Employee.where(:hrd_employee_payroll_id=> plant_id, :sys_department_id=> dept_id)
      records = Employee.where(:department_id=> dept_id)
      user_unregistered = []
      records.order("name asc").each do |employee|
        att_users = AttendanceUser.where(:employee_id=> employee.id, :status=> 'active')
        if att_users.present?
          att_log_array = []
          original_attendances = []
          original_manual_attendances = []
          att_users.each do |att_user|
            AttendanceLog.where(:company_profile_id=> employee.company_profile_id, :employee_id=> att_user.employee_id).where("date between ? and ?", period_begin, period_end).order("date_time asc").each do |att|
              att_log_array << {
                :id=> att.id,
                :loc_code=> att.loc_code,
                :possibly_wrong_push=> att.possibly_wrong_push,
                :without_repair_period_shift=> att.without_repair_period_shift,
                :company_profile_id=> att.company_profile_id,
                :employee_id=> att.employee_id,
                :date=> att.date.to_date.strftime("%Y-%m-%d"),
                :time=> att.time.to_datetime.strftime("%H:%M:%S"),
                :date_time=> att.date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S"),
                :id_number=> att.id_number,
                :mode_presence=> att.mode_presence,
                :type_presence=> att.type_presence,
                :status=> att.status,
                :note=> att.note
              }
            end

            case att_user.company_profile_id.to_i
            when 1
              # att_pinang = AbsensiHabsen.where(:empl_code=> att_user.id_number).where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
              # original_attendances += att_pinang if att_pinang.present?

              # get finger print
              att_pinang_fp = AbsensiFpabsen.where(:empl_code=> att_user.id_number, :loc_code=>'BWXP201160769').where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
              original_attendances += att_pinang_fp if att_pinang_fp.present?

              att_manual_piang = ManualPresence.where(:company_profile_id=> att_user.company_profile_id, :status=> 'approved', :id_number=> att_user.id_number).where("date between ? and ?", period_begin, period_end).order("date_time asc")
              original_manual_attendances += att_manual_piang if att_manual_piang.present?
            end
          end

          att_users.each do |att_user|
            puts "#{att_user.id_number} - #{att_user.employee_id} - #{att_user.company_profile_id} - #{employee.name}"
            # case att_user.sys_plant_id.to_i
            # when 3, 4
            #   original_attendances = AbsensiHabsen.where(:empl_code=> att_user.id_number).where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
            # when 2
            #   original_attendances = AbsensiHabsenTechno.where(:empl_code=> att_user.id_number).where("tr_date between ? and ?", period_begin, period_end).order("tr_no asc")
            # end

            count = 0
            att_array  = []
            original_attendances.sort { |a, b| [a['tr_date'], a['tr_time']] <=> [b['tr_date'], b['tr_time']] }.each do |att|
              case att.acc_code.to_i
              when 1
                acc_code = 'Att'
              else
                acc_code = 'Ext'
              end
              att_array << {:loc_code=> att.loc_code, :manual_presence=> false, :empl_code=> att.empl_code, :tr_date=> att.tr_date.strftime("%Y-%m-%d"), :tr_time=> att.tr_time.strftime("%H:%M:%S"), :acc_code=> acc_code }
              count += 1

              # puts "[#{att.empl_code}] #{att.tr_date} - #{acc_code}"
            end

            original_manual_attendances.sort { |a, b| [a['date_time']] <=> [b['date_time']] }.each do |att_manual|
              case att_manual.type_presence
              when 'in'
                acc_code = 'Att'
              else
                acc_code = 'Ext'
              end
              att_array << {:loc_code=> "", :manual_presence=> true, :empl_code=> att_manual.id_number, :tr_date=> att_manual.date_time.strftime("%Y-%m-%d"), :tr_time=> att_manual.date_time.strftime("%H:%M:%S"), :acc_code=> acc_code }
              count += 1
            end
            # puts "--------------------------------------"
            # puts att_array
            att_array = att_array.sort_by{ |t| [t[:tr_date], t[:tr_time]] }  
            # puts att_array
            att_array = precompile_attendance(count, att_array, employee, att_user)

            # perbaikan mode_presence
            att_array.each do |att|
              note = nil
              case att[:acc_code_b]
              when 'Att'
                if att[:manual_presence] == true
                  mode_presence = 'aTt'
                  note = 'manual update'
                else
                  if att[:acc_code] != att[:acc_code_b]
                    mode_presence = 'att'
                  else
                    mode_presence = 'Att'
                  end
                end
                type_presence = 'in'
              else
                if att[:manual_presence] == true
                  mode_presence = 'eXt'
                  note = 'manual update'
                else
                  if att[:acc_code] != att[:acc_code_b]
                    mode_presence = 'ext'
                  else
                    mode_presence = 'Ext'
                  end
                end
                type_presence = 'out'
              end

              possibly_wrong_push = att[:possibly_wrong_push]
              # if "#{att[:tr_date]} #{att[:tr_time]}".to_time < "#{att[:tr_date]} 02:00:00".to_time
              #   puts "#{att[:tr_date]} #{att[:tr_time]}".to_time
              #   date_shift = att[:tr_date].to_date-1.days
              # else
              #   date_shift = att[:tr_date]
              # end

              date_shift = (att[:period_shift].present? ? att[:period_shift] : att[:tr_date])
              att_log_array_exist = false
              att_log_array.each do |att_log|
                if att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S") == "#{att[:tr_date]} #{att[:tr_time]}"
                  if att_log[:note] != note or att_log[:date].to_date.strftime("%Y-%m-%d") != date_shift.to_date.strftime("%Y-%m-%d") or att_log[:mode_presence] != mode_presence or att_log[:type_presence] != type_presence or att_log[:possibly_wrong_push] != possibly_wrong_push
                    puts "note: #{att_log[:note]} != #{note} => #{att_log[:note] != note}"
                    puts "date: #{att_log[:date].to_date.strftime("%Y-%m-%d")} != #{date_shift.to_date.strftime("%Y-%m-%d")} => #{att_log[:date].to_date.strftime("%Y-%m-%d") != date_shift.to_date.strftime("%Y-%m-%d")}"
                    puts "mode_presence: #{att_log[:mode_presence]} != #{mode_presence} => #{att_log[:mode_presence] != mode_presence} "
                    puts "type_presence: #{att_log[:type_presence]} != #{type_presence} => #{att_log[:type_presence] != type_presence}"
                    puts "possibly_wrong_push: #{att_log[:possibly_wrong_push]} != #{possibly_wrong_push} => #{att_log[:possibly_wrong_push] != possibly_wrong_push}"
                    
                    check = AttendanceLog.find_by(:id=> att_log[:id])
                    if check.present?
                      check.update_columns(
                        :loc_code=> att_log[:loc_code],
                        :date=> date_shift,
                        :possibly_wrong_push=> possibly_wrong_push,
                        :mode_presence=> mode_presence,
                        :type_presence=> type_presence,
                        :note=> note
                        ) 
                      puts "update attendance_log_id: #{att_log[:id]}"
                    end
                  end
                  att_log_array_exist = true
                end
              end

              if att_log_array_exist == false
                puts "Create date: #{date_shift} => #{att[:tr_date]} #{att[:tr_time]}"
                AttendanceLog.create(
                  :loc_code=> att[:loc_code],
                  :company_profile_id=> employee.company_profile_id, 
                  :employee_id=> att_user.employee_id, 
                  :possibly_wrong_push=> possibly_wrong_push,
                  :date=> date_shift,
                  :time=> att[:tr_time],
                  :date_time=> "#{att[:tr_date]} #{att[:tr_time]}",
                  :id_number=> att_user.id_number,
                  :mode_presence=> mode_presence,
                  :type_presence=> type_presence,
                  :status=> 'active',
                  :note=> note,:updated_at=> DateTime.now(), :updated_by=> 1
                  )
              end
              # puts "[#{att[:empl_code]}] #{att[:tr_date]} - #{att[:acc_code]} / #{mode_presence}"

            end


            # update report yg salah pencet
            att_array = precompile_attendance(count, att_array, nil, nil)
            att_array.each do |att|

              att_log_array.each do |att_log|
                if att_log[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S") == "#{att[:tr_date]} #{att[:tr_time]}"
                  if att_log[:possibly_wrong_push] != att[:possibly_wrong_push]
                    check = AttendanceLog.find_by(:id=> att_log[:id])
                    if check.present?
                      check.update_columns(:possibly_wrong_push=> att[:possibly_wrong_push] ) 
                      puts "update #{att[:date_shift]} -#{att[:type_presence]}"
                    end
                  end
                end
              end

              # attendence_log = HrdAttendanceLog.find_by(:sys_plant_id=> employee.hrd_employee_payroll_id, :hrd_employee_id=> att_user.hrd_employee_id, :date_time=> "#{att[:tr_date]} #{att[:tr_time]}")
            
              # if attendence_log.possibly_wrong_push != att[:possibly_wrong_push]
              #   attendence_log.update_columns(:possibly_wrong_push=> att[:possibly_wrong_push] ) 
              #   puts "update #{att[:date_shift]} -#{att[:type_presence]}"
              # end
            
            end

            schedule_without_hk(att_user.company_profile_id, period_begin.strftime("%Y%m"), nil, att_user.employee_id)
            hk_without_schedule(att_user.company_profile_id, period_begin.strftime("%Y%m"), nil, att_user.employee_id)
            att_dupplicate(att_user.company_profile_id, period_begin.strftime("%Y%m"), nil, 'in', att_user.employee_id)
            att_dupplicate(att_user.company_profile_id, period_begin.strftime("%Y%m"), nil, 'out', att_user.employee_id)

            att_in_without_out(att_user.company_profile_id, period_begin.strftime("%Y%m"), nil, att_user.employee_id)
          end
        else
          puts "#{plant_id} - tidak terdaftar: employee_id=> #{employee.id}"       
          user_unregistered << employee.id
          # HrdAttendanceUser.create(
          #   :sys_plant_id=> plant_id,
          #   :hrd_employee_id=> employee.id,
          #   :sys_department_id=> dept_id,
          #   :id_number=> employee.pin,
          #   :name=> employee.name,
          #   :status=> 'active',
          #   :created_by=> 1, :created_at=> DateTime.now()

          #   ) if employee.present? and employee.pin.present?
        end
      end
      puts user_unregistered
      b = DateTime.now()
      puts "[#{dept_id}] start: #{a} between #{b} => #{TimeDifference.between(a, b).in_minutes}"
    end
  #perbaiki ---- end -----  


  def precompile_attendance(count, att_array, employee, att_user)

    # Menghapus data yang mempunyai selang waktu kurang dari 5 menit
      (0..count).each do |c|
        if att_array[c+1].present?
          if att_array[c][:tr_date] == att_array[c+1][:tr_date]
            begin_periode = "#{att_array[c][:tr_date]} #{att_array[c][:tr_time].to_datetime.strftime("%H:%M:%S")}"
            end_periode   = "#{att_array[c+1][:tr_date]} #{att_array[c+1][:tr_time].to_datetime.strftime("%H:%M:%S")}"
            diff_time     = TimeDifference.between(begin_periode, end_periode).in_hours

            if diff_time < 0.5
              puts "delete < 0.5 - #{att_array[c]} => #{diff_time}" 
              # result << "delete c #{c} - #{array[c]} => #{diff_time}"
              # hapus data yg awal
              # att_array.delete_at(c)
              # hapus data yg akhir
              att_array.delete_at(c+1)

            end
          end
        end
      end
      # jgn dipake
      # (0..count).each do |c|
      #   if att_array[c+1].present?
      #     if att_array[c][:tr_date] == att_array[c+1][:tr_date]
      #       begin_periode = "#{att_array[c][:tr_date]} #{att_array[c][:tr_time].to_datetime.strftime("%H:%M:%S")}"
      #       end_periode   = "#{att_array[c+1][:tr_date]} #{att_array[c+1][:tr_time].to_datetime.strftime("%H:%M:%S")}"
      #       diff_time     = TimeDifference.between(begin_periode, end_periode).in_hours

      #       puts "#{begin_periode} #{att_array[c][:acc_code]} == #{end_periode} #{att_array[c+1][:acc_code]} => #{diff_time}"
      #       if att_array[c][:acc_code] == att_array[c+1][:acc_code]
      #         case att_array[c][:acc_code]
      #         when 'Att'
      #           puts "delete - #{att_array[c+1]} => #{diff_time}" 
      #           att_array.delete_at(c+1)
      #         when 'Ext'
      #           puts "delete - #{att_array[c]} => #{diff_time}" 
      #           att_array.delete_at(c)
      #         end
      #       end
      #     end
      #   end
      # end
    # johnny logic shift 1
    (0..count).each do |c|
      prev_date = (c-1 > 0 ? (att_array[c-1].present? ? att_array[c-1][:tr_date] : nil ) : nil )
      now_date = (att_array[c].present? ? att_array[c][:tr_date] : nil )
      next_date = (att_array[c+1].present? ? att_array[c+1][:tr_date] : nil )

      # 2020/03/13
      # att_array[c][:acc_code] = att_array[c][:acc_code].humanize if att_array[c].present?
      # att_array[c+1][:acc_code] = att_array[c+1][:acc_code].humanize if att_array[c+1].present?

      now_mode_presence = (att_array[c].present? ? att_array[c][:acc_code] : nil )
      next_mode_presence = (att_array[c+1].present? ? att_array[c+1][:acc_code] : nil )

      # pengecekan mode sama
      check_a = (now_mode_presence == next_mode_presence ? 1 : 0)
      # pengecekan hari sama dan mode sama
      check_b = ( now_date == next_date ? (now_mode_presence == next_mode_presence ? 1 : 0) : 0)
      # pengecekan check_a
      check_d = ((check_a+check_b) == 1 ? 1 : 0 )
      # pengecekan check_d dan (check_a atau check 2 ada)
      if check_d == 1 and (check_a == 1 or check_b == 1)
        check_e = 1
      else
        check_e = 0
      end
      att_array[c].merge!(:check_a=> check_a, :check_b=> check_b, :check_d=> check_d, :check_e=> check_e, :possibly_wrong_push=> 0, :wrong_mode=> 0, :diff_time=> 0,
        :working_hour_under_2h => false
        ) if att_array[c].present?
    end
    # puts att_array
    # perbaikan in out shift 1
    (0..count).each do |c|
      prev_mode_presence = (c-1 > 0 ? (att_array[c-1].present? ? att_array[c-1][:acc_code] : nil ) : nil )
      now_mode_presence = (att_array[c].present? ? att_array[c][:acc_code] : nil )
      next_mode_presence = (att_array[c+1].present? ? att_array[c+1][:acc_code] : nil )

      prev_check_e = att_array[c-1][:check_e] if c-1 > 0 and att_array[c-1].present?
      now_check_e = att_array[c][:check_e] if att_array[c].present?
      next_check_e = att_array[c+1][:check_e] if att_array[c+1].present?

      att_array[c].merge!(:acc_code_a=> att_array[c][:acc_code]) if att_array[c].present?
      att_array[c].merge!(:acc_code_b=> att_array[c][:acc_code]) if att_array[c].present?
   
      if prev_check_e == 1 and now_check_e == 0 and prev_mode_presence == 'Ext' and now_mode_presence == 'Ext' and  next_mode_presence == 'Ext'
        att_array[c][:acc_code_a] = 'Att' if att_array[c].present?
      end
      if prev_check_e == 0 and now_check_e == 1 and next_check_e == 0 and prev_mode_presence == 'Att' and now_mode_presence == 'Att' and  next_mode_presence == 'Att'
        att_array[c][:acc_code_b] = 'Ext' if att_array[c].present?
      end          
    end
    # puts att_array
    # johnny logic shift 3
    (0..count).each do |c|
      prev_date = (c-1 > 0 ? (att_array[c-1].present? ? att_array[c-1][:tr_date] : nil ) : nil )
      now_date = (att_array[c].present? ? att_array[c][:tr_date] : nil )
      next_date = (att_array[c+1].present? ? att_array[c+1][:tr_date] : nil )

      now_mode_presence = (att_array[c].present? ? att_array[c][:acc_code_b] : nil )
      next_mode_presence = (att_array[c+1].present? ? att_array[c+1][:acc_code_b] : nil )

      # pengecekan mode sama
      check_a = (now_mode_presence == next_mode_presence ? 1 : 0)
      # pengecekan hari sama dan mode sama
      check_b = ( now_date == next_date ? (now_mode_presence == next_mode_presence ? 1 : 0) : 0)
      # pengecekan check_a
      check_d = ((check_a+check_b) == 1 ? 1 : 0 )
      # pengecekan check_d dan (check_a atau check 2 ada)
      if check_d == 1 and (check_a == 1 or check_b == 1)
        check_e = 1
      else
        check_e = 0
      end

      att_array[c][:check_a] = check_a if att_array[c].present?   
      att_array[c][:check_b] = check_b if att_array[c].present?   
      att_array[c][:check_d] = check_d if att_array[c].present?   
      att_array[c][:check_e] = check_e if att_array[c].present?
    end

    # perbaikan in out shift 3
    (0..count).each do |c|
      prev_mode_presence = (c-1 > 0 ? (att_array[c-1].present? ? att_array[c-1][:acc_code_b] : nil ) : nil)
      now_mode_presence = (att_array[c].present? ? att_array[c][:acc_code_b] : nil )
      next_mode_presence = (att_array[c+1].present? ? att_array[c+1][:acc_code_b] : nil )

      prev_check_e = att_array[c-1][:check_e] if c-1 > 0 and att_array[c-1].present?
      now_check_e = att_array[c][:check_e] if att_array[c].present?
      next_check_e = att_array[c+1][:check_e] if att_array[c+1].present?
   
      if prev_check_e == 1 and now_check_e == 0 and next_check_e == 0 and prev_mode_presence == 'Att' and now_mode_presence == 'Att' and  next_mode_presence == 'Att'
        att_array[c][:acc_code_a] = 'Ext' if att_array[c].present?
      end
      if prev_check_e == 0 and now_check_e == 1 and prev_mode_presence == 'Ext' and now_mode_presence == 'Ext' and  next_mode_presence == 'Ext' and "#{att_array[c][:tr_date].to_date.strftime("%d")}".to_i != 21 
        att_array[c][:acc_code_b] = 'Att' if att_array[c].present?
      end   
    end
    # puts att_array
    # check kemungkinan masih ada salah dalam range 7 hari
    (0..count).each do |c|
      check_a_prev_4 = (c-4 > 0 ? (att_array[c-4].present? ? att_array[c-4][:check_a] : 0) : 0)
      check_a_prev_3 = (c-3 > 0 ? (att_array[c-3].present? ? att_array[c-3][:check_a] : 0) : 0)
      check_a_prev_2 = (c-2 > 0 ? (att_array[c-2].present? ? att_array[c-2][:check_a] : 0) : 0)
      check_a_prev_1 = (c-1 > 0 ? (att_array[c-1].present? ? att_array[c-1][:check_a] : 0) : 0)
      check_a_now    = (att_array[c].present? ? att_array[c][:check_a] : 0)
      check_a_next_1 = (att_array[c+1].present? ? att_array[c+1][:check_a] : 0)
      check_a_next_2 = (att_array[c+2].present? ? att_array[c+2][:check_a] : 0)
      
      if check_a_now == 1
        att_array[c][:wrong_mode] = 1
      end

      if check_a_prev_4 == 1 or check_a_prev_3 == 1 or check_a_prev_2 == 1 or check_a_prev_1 == 1 or check_a_now == 1 or check_a_next_1 == 1 or check_a_next_2 == 1
        att_array[c][:possibly_wrong_push] = 1 if att_array[c].present? 
        possibly_wrong_push = 1 if att_array[c].present? 
      else  
        att_array[c][:possibly_wrong_push] = 0 if att_array[c].present?  
        possibly_wrong_push = 0 if att_array[c].present? 
      end     
      # puts "#{att_array[c][:tr_date]} #{att_array[c][:tr_time]} #{att_array[c][:acc_code_b]}- [#{check_a_prev_4}][#{check_a_prev_3}][#{check_a_prev_2}][#{check_a_prev_1}] < [#{check_a_now}] > [#{check_a_next_1}][#{check_a_next_2}] => #{possibly_wrong_push} | #{att_array[c][:wrong_mode]}" if att_array[c].present?
      
    end

    # perbaiakn periode jam kerja masuk jika dibawah 03:00 maka masuk periode sebelumnya
    (0..count).each do |c|
      if att_array[c].present?
        if "#{att_array[c][:tr_date]} #{att_array[c][:tr_time]}".to_time < "#{att_array[c][:tr_date]} 01:00:00".to_time
          # ada schedule masuk jam 2
          # if "#{att_array[c][:tr_date]} #{att_array[c][:tr_time]}".to_time < "#{att_array[c][:tr_date]} 03:00:00".to_time
          case att_array[c][:acc_code_b]
          when 'Att'
            att_array[c].merge!(:period_shift=> (att_array[c][:tr_date].to_date-1.days).strftime("%Y-%m-%d"))
          else
            att_array[c].merge!(:period_shift=> att_array[c][:tr_date]) 
          end
        else
          att_array[c].merge!(:period_shift=> att_array[c][:tr_date]) 
        end
        # puts "#{att_array[c][:period_shift]} => #{att_array[c][:acc_code_b]}"
        # puts "[#{att_array[c][:period_shift]}] #{att_array[c][:tr_date]} #{att_array[c][:tr_time]} => #{att_array[c][:acc_code_b]}"
        
      end
    end

    (0..count).each do |c|
          
      if att_array[c+1].present?
        if att_array[c][:acc_code_b] == 'Att' and att_array[c+1][:acc_code_b] == 'Ext'
          # 2020-04-23 - penambahan kolom array selisih waktu in dan out
          begin_datetime = "#{att_array[c][:tr_date]} #{att_array[c][:tr_time]}"
          end_datetime   = "#{att_array[c+1][:tr_date]} #{att_array[c+1][:tr_time]}"
          diff_time_period = TimeDifference.between(begin_datetime, end_datetime).in_hours

          if att_array[c].present? and att_array[c+1].present?
            att_array[c][:diff_time] = diff_time_period 
            att_array[c+1][:diff_time] = diff_time_period
            att_array[c][:working_hour_under_2h] = true 
            att_array[c+1][:working_hour_under_2h] = true

          end
          puts "1 [#{att_array[c][:period_shift]}] #{att_array[c][:tr_date]} - in: #{att_array[c][:tr_time]}; out: #{att_array[c+1][:tr_time]} => #{diff_time_period}"
          # att_array[c][:period_shift] = att_array[c][:tr_date] if att_array[c].present?
          att_array[c+1][:period_shift] = att_array[c][:period_shift] if att_array[c+1].present?
        elsif att_array[c][:acc_code_b] == 'Ext' and att_array[c+1][:acc_code_b] == 'Ext'

          if "#{att_array[c+1][:tr_date]} #{att_array[c+1][:tr_time]}".to_time < "#{att_array[c+1][:tr_date]} 10:00:00".to_time
            puts "2 [#{att_array[c+1][:tr_date].to_date-1.days}] #{att_array[c+1][:tr_date]} - in: - ; out: #{att_array[c+1][:tr_time]}"
            att_array[c+1][:period_shift] = att_array[c+1][:tr_date].to_date-1.days
          else
            puts "2 [#{att_array[c+1][:period_shift]}] #{att_array[c+1][:tr_date]} - in: - ; out: #{att_array[c+1][:tr_time]}"     
          end
          
        else
          puts "3 [#{att_array[c][:period_shift]}] #{att_array[c][:tr_date]} - in: #{att_array[c][:tr_time]}; out: -" if att_array[c].present? and att_array[c][:acc_code_b] == 'Att'
          # att_array[c].merge!(:period_shift=> att_array[c][:tr_date]) if att_array[c].present?
        end
      else
        puts "4 [#{att_array[c][:period_shift]}] #{att_array[c][:tr_date]} - in: #{att_array[c][:tr_time]}; out: -" if att_array[c].present? and att_array[c][:acc_code_b] == 'Att'
        # att_array[c].merge!(:period_shift=> att_array[c][:tr_date]) if att_array[c].present?
      end
    end

    return att_array
  end

  #perbaiki ---- start -----
    def update_report(plant_id, period_yyyymm, id_number)
      puts 'masuk helper update report'
      plant         = plant_id
      period        = ("#{period_yyyymm}01").to_date.beginning_of_month().strftime("%Y-%m-%d")
      period_begin  = period.to_date+20.day if period.present?
      period_end    = period.to_date+1.month+19.day if period.present?
      
      hrd_schedule = []
      Schedule.where(:status=> 'active').each do |schedule|
        hrd_schedule << {
          :id=> schedule.id, 
          :company_profile_id=> schedule.company_profile_id,
          :monday_in=> schedule.monday_in, :monday_out=> schedule.monday_out, 
          :tuesday_in=> schedule.tuesday_in, :tuesday_out=> schedule.tuesday_out, 
          :wednesday_in=> schedule.wednesday_in, :wednesday_out=> schedule.wednesday_out, 
          :thursday_in=> schedule.thursday_in, :thursday_out=> schedule.thursday_out, 
          :friday_in=> schedule.friday_in, :friday_out=> schedule.friday_out, 
          :saturday_in=> schedule.saturday_in, :saturday_out=> schedule.saturday_out, 
          :sunday_in=> schedule.sunday_in, :sunday_out=> schedule.sunday_out
        }
      end
      AttendanceUser.where(:company_profile_id=> plant, :id_number=> id_number).each do |att_user|
        if att_user.status == 'active'
          if att_user.employee.present?
            employee_id = att_user.employee_id
            # hrd_employee_payroll_id = att_user.hrd_employee.hrd_employee_payroll_id

            attendences = AttendanceLog.where(:company_profile_id=> plant, :employee_id=> employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date_time asc")
            count = 0
            att_array = []
            attendences.each do |att|
              case att.type_presence
              when 'in'
                acc_code = 'Att'
              else
                acc_code = 'Ext'
              end
              att_array << {:manual_presence=> false, :empl_code=> att.id_number, :tr_date=> att.date_time.strftime("%Y-%m-%d"), :tr_time=> att.date_time.strftime("%H:%M:%S"), :acc_code=> acc_code, :without_repair_period_shift=> att.without_repair_period_shift }
              count += 1
            end
            # update report yg salah pencet

            att_array = precompile_attendance(count, att_array, nil, nil)

            update_employee_presence = []
            # peribaikan salah periode
            att_array.each do |att|
              if att[:without_repair_period_shift].to_i == 0
                attendences.each do |e|
                  if e[:date_time].to_datetime.strftime("%Y-%m-%d %H:%M:%S") == "#{att[:tr_date]} #{att[:tr_time]}" 
                    if att[:period_shift].to_date != e[:date].to_date
                      # perbaikan salah periode 
                      puts "[#{att[:period_shift]}] update period_shift #{e[:date]} => #{att[:period_shift]} "
                      e.update_columns(:date=> att[:period_shift])
                      # update_att_log << {:id=> e[:id], :date=> att[:period_shift], :status=> "update", :possibly_wrong_push=> att[:possibly_wrong_push] }
                    end
                  end
                end
              end

              # update report jika jam kerja lebih dari 20 jam
              if att[:diff_time].to_f > 20
                update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "create", :kind=> "working_hour_over_20h"}
              end

              if att[:diff_time].to_f < 2
                # working_hour_under_2h = true jika terdapat sepasang IN dan OUT
                if att[:working_hour_under_2h] == true
                  update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "create", :kind=> "working_hour_under_2h"}
                else
                  update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "remove", :kind=> 'working_hour_under_2h'}
                end
              end
            end

            att_array.each do |att|
            end
            # penambahan array periode
            (period_begin..period_end).each do |date|
              check_period = true
              att_array.each do |att|
                if att[:period_shift].to_date == date.to_date
                  check_period = false
                end
              end
              if check_period == true 
                att_array << {
                  :manual_presence=>false, 
                  :empl_code=> id_number, 
                  :tr_date=> date, :tr_time=> nil, :acc_code=> 'Att', 
                  :check_a=>0, :check_b=>0, :check_d=>0, :check_e=>0, 
                  :possibly_wrong_push=>0, :wrong_mode=>0, :acc_code_a=> 'Att', :acc_code_b=> 'Att', 
                  :period_shift=> date}           
                # att_array << {:manual_presence=> false, :empl_code=> id_number, :tr_date=> date.strftime("%Y-%m-%d"), :tr_time=> nil, :acc_code=> nil }
                count += 1
              end
            end

            # puts "----------------------------------------------------------"
            # puts att_array
            # puts "----------------------------------------------------------"
            array_process_cript = true
            attendence_log = []
            attendence_log_counter = 0
            AttendanceLog.where(:company_profile_id=> plant, :employee_id=> employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date_time asc").each do |att_log|
              # attendence_log << att_log.as_json
              attendence_log << {
                :id=> att_log.id, 
                # :sys_plant_id=> att_log.sys_plant_id, 
                # :hrd_employee_id=> att_log.hrd_employee_id, 
                :date=> att_log.date.to_date.strftime("%Y-%m-%d"), 
                :time=> att_log.time.to_datetime.strftime("%H:%M:%S"), 
                :date_time=> att_log.date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S"),
                :mode_presence=> att_log.mode_presence,
                :type_presence=> att_log.type_presence,
                :possibly_wrong_push=> att_log.possibly_wrong_push,
                :status=> att_log.status
              }
              attendence_log_counter += 1
            end
            employee_presence = []
            EmployeePresence.where(:company_profile_id=> plant, :employee_id=> employee_id, :period=> period_yyyymm).order("date asc").each do |a|
              employee_presence << {
                :id=> a.id, 
                :kind=> a.kind,
                :id_number=> a.id_number,
                :date=> a.date,
                :status=> a.status
              }
            end

            employee_schedule = []
            # schedule kerja yg mempunyai jam masuk dan keluar
            EmployeeSchedule.where(:employee_id=> employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).each do |b|
              day_name = b.date.strftime("%A").downcase
              schedule_time_in = nil
              schedule_time_out = nil
              hrd_schedule.each do |schedule|
                if schedule[:id].to_i == b.schedule_id.to_i
                  schedule_time_in = schedule["#{day_name}_in".to_sym]
                  schedule_time_out = schedule["#{day_name}_out".to_sym]
                end
              end
              employee_schedule << {
                :id=> b.id,
                :hrd_schedule_id=> b.schedule_id,
                :date=> b.date,
                :schedule_time_in=> (schedule_time_in.present? ? schedule_time_in.strftime("%H:%M:%S") : nil),
                :schedule_time_out=> (schedule_time_out.present? ? schedule_time_out.strftime("%H:%M:%S") : nil)
              }
            end
            
            process_update_schedule_without_hk = true
            if process_update_schedule_without_hk == true
              employee_schedule.each do |e|
                # update HK without schdeule
                attendence_log.each do |x|
                  if x[:date].to_date == e[:date].to_date 
                    if x[:status] == 'active'
                      employee_presence.each do |z|
                        if z[:kind] == "hk_without_schedule"
                          if z[:date].to_date == e[:date].to_date
                            if z[:status] == 'active'
                              puts "[#{x[:date]}] update employee_presence [#{z[:kind]}] status remove"
                              update_employee_presence << {:id=> z[:id], :date=> z[:date], :job_process=> "remove", :kind=> z[:kind]}
                            end
                          end
                        end
                      end
                    end
                  end
                end

                # update schdeule without hk
                if e[:schedule_time_in].blank? and e[:schedule_time_out].blank?
                  # pastikan schedule tanpa hankey ada jam masuk dan jam keluar
                  employee_presence.each do |z|
                    if z[:kind] == "schedule_without_hk" and z[:status] == 'active'
                      if e[:date].to_date == z[:date].to_date
                        puts "[#{e[:date]}] update employee_presence [#{z[:kind]}] status remove"
                        update_employee_presence << {:id=> z[:id], :date=> z[:date], :job_process=> "remove", :kind=> z[:kind]}
                      end
                    end
                  end
                else     
                  # update schedule_without_hk   
                  create_employee_presence = true    
                  attendence_log.each do |x|
                    if x[:date].to_date == e[:date].to_date 
                      create_employee_presence = false   
                      if x[:status] == 'active'
                        # jika ada log 
                        # puts "date: #{e[:date]}; "
                        employee_presence.each do |z|
                          if z[:kind] == "schedule_without_hk"
                            if z[:date].to_date == e[:date].to_date
                              if z[:status] == 'active'
                                puts "[#{x[:date]}] update employee_presence [#{z[:kind]}] status remove"
                                update_employee_presence << {:id=> z[:id], :date=> z[:date], :job_process=> "remove", :kind=> z[:kind]}
                              end
                            end
                          end
                        end
                      else
                        puts "date: #{e[:date]}; [#{employee_id}] log tidak ada"
                        employee_presence.each do |z|
                          if z[:kind] == "schedule_without_hk"
                            if z[:date].to_date == e[:date].to_date
                              if z[:status] == 'remove'
                                puts "[#{x[:date]}] update employee_presence [#{z[:kind]}] status active"
                                update_employee_presence << {:id=> z[:id], :date=> z[:date], :job_process=> "active", :kind=> z[:kind]}
                              end
                            else
                              puts "[#{x[:date]}] create employee_presence [#{z[:kind]}]"      
                              update_employee_presence << {:id=> z[:id], :date=> z[:date], :job_process=> "create", :kind=> z[:kind]}                    
                            end
                          end
                        end
                      end
                    end
                  end
                  if create_employee_presence == true
                    puts "[#{e[:date]}] create employee_presence [schedule_without_hk]"      
                    update_employee_presence << {:id=> nil, :date=> e[:date], :job_process=> "create", :kind=> "schedule_without_hk"} 
                  end
                end
              end
            end

              # puts attendence_log.map {|x| "key: #{x.keys}; value: #{x.values}" }
              # puts attendence_log.select{|key, hash| hash["date_time"]}
            update_att_log = []

            dt_period = nil
            # update possibly_wrong_push menjadi 0 jika tidak ada
            attendence_log.each do |e|

              remove_possibly_wrong_push = true
              att_array.each do |att|
                if e[:date_time] == "#{att[:tr_date]} #{att[:tr_time]}" 
                  remove_possibly_wrong_push = false
                  # if e[:mode_presence] != att[:acc_code_b]        
                  #   puts "[#{e[:date]}] update log: change mode_presence: #{att[:acc_code_b]}"
                  #   # update_att_log << {:id=> e[:id], :date=> e[:date], :status=> "change_mode_presence", :possibly_wrong_push=> 0, :mode_presence=> att[:acc_code_b] }
                  # end

                end
              end

              if remove_possibly_wrong_push == true
                puts "[#{e[:date]}] remove log"
                update_att_log << {:id=> e[:id], :date=> e[:date], :status=> "remove", :possibly_wrong_push=> 0 }
            
              end


              create_hk_without_schedule = true
              employee_schedule.each do |schedule|
                if e[:date].to_date == schedule[:date].to_date 
                  create_hk_without_schedule = false
                end
              end
              if create_hk_without_schedule == true
                puts "[#{e[:date]}] create status employee_presence hk_without_schedule"
                update_employee_presence << {:id=> nil, :date=> e[:date], :job_process=> "create", :kind=> "hk_without_schedule"}
              end
            end

            att_array.each do |att|
              if array_process_cript == true
                case att[:acc_code_b].downcase
                when 'att'
                  kind = 'in'
                else
                  kind = 'out'
                end 

                # puts "new #{att[:tr_date]} #{att[:tr_time]}=> #{att[:possibly_wrong_push]}"
                # puts "#{att[:tr_date]} #{att[:tr_time]} => #{att[:acc_code_b]}"
                att_in = nil 
                att_out = nil 
                # puts "#{att[:tr_date]} #{att[:tr_time]} #{kind}"

                attendence_log.each do |e|
                  if e[:status] == 'active' and e[:date].to_date == att[:period_shift].to_date 
                    # puts "[#{ e[:date].to_date}] => #{e[:type_presence]} #{e[:id]}"
                    if e[:type_presence] == 'in'
                      att_in = e[:id]
                    elsif e[:type_presence] == 'out'
                      # untuk out yg salah periode shift
                      if e[:date_time].to_date.strftime("%Y-%m-%d") <= (e[:date].to_date+1.days).to_date.strftime("%Y-%m-%d") == false
                        puts "log #{e[:date_time]} hapus" 
                        update_att_log << {:id=> e[:id], :date=> e[:date], :status=> "remove", :possibly_wrong_push=> e[:possibly_wrong_push]}
                      end
                      att_out = e[:id]
                    end
                  end

                end
                # puts "#{att[:period_shift]} => #{att[:tr_date]} #{att[:tr_time]}"

                remove_employee_presence = true
                attendence_log.each do |e|
                  if e[:date_time] == "#{att[:tr_date]} #{att[:tr_time]}" 
                    # puts "old #{e[:date_time]}=> #{e[:possibly_wrong_push]}"
                    if att[:possibly_wrong_push].to_i != e[:possibly_wrong_push].to_i
                      puts "[#{att[:period_shift]}] update possibly_wrong_push => #{att[:possibly_wrong_push]} "
                      update_att_log << {:id=> e[:id], :date=> e[:date], :status=> "update", :possibly_wrong_push=> att[:possibly_wrong_push] }
                      # puts "update #{e[:date_time]} #{e[:type_presence]} => [possibly_wrong_push] new: #{att[:possibly_wrong_push]} != old: #{e[:possibly_wrong_push]}"
                    end
                  end

                  if e[:status] == 'active' and e[:date].to_date == att[:period_shift].to_date              
                    # puts "#{att_in} #{att_out}"
                    if (att_in.present? and att_out.present?) or (att_in.blank? and att_out.blank?)
                      # puts "[#{att[:period_shift]}] #{hrd_employee_id} good"
                      # perbaikan rangkuman masalah
                      # if dt_period == nil
                        employee_presence.each do |x|
                          if x[:date].to_date == att[:period_shift].to_date
                            
                            if x[:status] != 'remove'
                              puts "[#{att[:period_shift]}] update status employee_presence #{x[:kind]} remove" 
                              update_employee_presence << {:id=> x[:id], :date=> x[:date], :job_process=> "remove", :kind=> x[:kind]}
                            end
                          end
                        end
                        # dt_period = att[:period_shift].to_date
                      # end
                      remove_employee_presence = false
                    else
                      if att_in.present? and att_out.blank?
                        # puts "--------------------------------------------------------"
                        # perbaikan att_in_without_out
                        puts "[#{att[:period_shift]}] #{employee_id} tidak ada out"
                        create_employee_presence = true
                        check_employee_presence = []
                        employee_presence.each do |x|
                          if x[:kind] == "att_in_without_out"
                            if x[:date].to_date == att[:period_shift].to_date
                              create_employee_presence = false unless check_employee_presence.include?({:date=> x[:date], :kind=> x[:kind]})
                              if x[:status] != 'active'
                                puts "[#{att[:period_shift]}] update status employee_presence #{x[:kind]} active" unless check_employee_presence.include?({:date=> x[:date], :kind=> x[:kind]})
                                update_employee_presence << {:id=> x[:id], :date=> x[:date], :job_process=> "active", :kind=> x[:kind]}
                                check_employee_presence << {:date=> x[:date], :kind=> x[:kind]}
                              end
                              remove_employee_presence = false
                            end
                          end
                        end
                        if create_employee_presence == true
                          puts "[#{att[:period_shift]}] create status employee_presence att_in_without_out"
                          update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "create", :kind=> "att_in_without_out"}
                        end
                      elsif att_out.present? and att_in.blank?
                        # puts "--------------------------------------------------------"
                        # perbaikan att_out_without_in
                        create_employee_presence = true
                        check_employee_presence = []
                        puts "[#{att[:period_shift]}] #{employee_id} tidak ada in"
                        employee_presence.each do |x|
                          if x[:kind] == "att_out_without_in"
                            if x[:date].to_date == att[:period_shift].to_date
                              create_employee_presence = false unless check_employee_presence.include?({:date=> x[:date], :kind=> x[:kind]})
                              if x[:status] != 'active'
                                puts "[#{att[:period_shift]}] update status employee_presence #{x[:kind]} active" unless check_employee_presence.include?({:date=> x[:date], :kind=> x[:kind]})
                                update_employee_presence << {:id=> x[:id], :date=> x[:date], :job_process=> "active", :kind=> x[:kind]}
                                check_employee_presence << {:date=> x[:date], :kind=> x[:kind]}
                              end
                              remove_employee_presence = false
                            end
                          end
                        end
                        if create_employee_presence == true
                          puts "[#{att[:period_shift]}] create status employee_presence att_out_without_in"
                          update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "create", :kind=> "att_out_without_in"}
                        end
                      end
                    end
                  end
                end

                if remove_employee_presence == true
                  puts "[#{att[:period_shift]}] update status employee_presence all remove" 
                  update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "remove", :kind=> 'all'}
                end

                # puts "[#{att[:period_shift]}] remove_employee_presence => #{remove_employee_presence}"

                # puts "update report yg duplikat in atau out"
                check_employee_presence = []
                create_employee_presence = true
                # puts "[#{att[:period_shift]}] #{att[:tr_time]} #{kind}"

                employee_presence.each do |e|              
                  if e[:date].to_date == att[:period_shift].to_date and e[:kind] == "duplicate_#{kind}"
                    if att[:wrong_mode].to_i == 1
                      puts "[#{att[:period_shift]}] #{employee_id} duplicate_#{kind}"
                      # jika ditemukan kemungkinan salah
                      if e[:status] != 'active'
                        puts "#{att[:tr_date]} #{att[:tr_time]} update employee_presence [#{e[:id]}] kind duplicate_#{kind} status #{e[:status]} => active" unless check_employee_presence.include?({:date=> e[:date], :kind=> e[:kind]})
                        update_employee_presence << {:id=> e[:id], :date=> e[:date], :job_process=> "active", :kind=> e[:kind]} unless check_employee_presence.include?({:date=> e[:date], :kind=> e[:kind]})
                        check_employee_presence << {:date=> e[:date], :kind=> e[:kind]}
                      end                    
                    else
                      # hapus jika wrong mode == 0
                      if e[:status] == 'active'
                        puts "#{att[:tr_date]} #{att[:tr_time]} update employee_presence status remove" unless check_employee_presence.include?({:date=> e[:date], :kind=> e[:kind]})
                        update_employee_presence << {:id=> e[:id], :date=> e[:date], :job_process=> "remove", :kind=> e[:kind]} unless check_employee_presence.include?({:date=> e[:date], :kind=> e[:kind]})
                        check_employee_presence << {:date=> e[:date], :kind=> e[:kind]}
                      end
                    end
                    create_employee_presence = false
                  else
                    create_employee_presence = false
                  end
                end
                if create_employee_presence == true and att[:wrong_mode].to_i == 1
                  puts "[#{att[:period_shift]}] create status employee_presence duplicate_#{kind}"
                  update_employee_presence << {:id=> nil, :date=> att[:period_shift], :job_process=> "create", :kind=> "duplicate_#{kind}"}
                end
              end
            end
            puts "update_att_log"
            # puts update_att_log
            update_att_log.each do |a|
              att_log = AttendanceLog.find_by(:id=> a[:id])
              if att_log.present?
                case a[:status]
                when 'remove'
                  att_log.update_columns(:status=> 'remove', :possibly_wrong_push=> a[:possibly_wrong_push])
                when 'update'
                  att_log.update_columns(:possibly_wrong_push=> a[:possibly_wrong_push], :date=> a[:date])
                # when 'change_mode_presence'
                #   puts update_att_log
                #   puts "[#{a[:id]}] #{att_log.without_repair_period_shift}"
                #   if att_log.without_repair_period_shift.to_i == 0
                #     case a[:mode_presence].downcase
                #     when 'att'
                #       type_presence = 'in'
                #     else
                #       type_presence = 'out'
                #     end
                #     att_log.update_columns(:mode_presence=> a[:mode_presence], :type_presence=> type_presence)
                #   end
                end
              end
            end
            puts "update_employee_presence"
            # puts update_employee_presence
            update_employee_presence.each do |a|
              case a[:job_process]
              when "create"
                # puts a
                # puts ":sys_plant_id=> #{plant}, :kind=> #{a[:kind]}, :date=> #{a[:date]}, :hrd_employee_id=> #{hrd_employee_id}"
                record = EmployeePresence.find_by(:company_profile_id=> plant, :kind=> a[:kind], :date=> a[:date], :employee_id=> employee_id)
                if record.present?
                  if record.status != 'active'
                    record.update_columns(:status=> 'active')
                    puts "update success"
                  end
                else
                  employee_presence = EmployeePresence.new(
                    :company_profile_id=> plant, 
                    :kind=> a[:kind], 
                    :employee_id=> employee_id, :id_number=> id_number,
                    :period=> period_yyyymm, 
                    :date=> a[:date],
                    :status=> 'active', :note=> nil,
                    :created_at=> DateTime.now(),
                    :created_by=> 1
                  )
                  employee_presence.save! 
                  puts "create success "
                end
              else
                case a[:kind]
                when 'all'
                  # tidak termasuk 'schedule_without_hk'
                  EmployeePresence.where(:company_profile_id=> plant, :status=> 'active', :date=> a[:date], :employee_id=> employee_id, :kind=> ['hk_without_schedule','duplicate_in','duplicate_out','att_in_without_out','att_out_without_in','working_hour_over_20h','working_hour_under_2h']).each do |record|
                    record.update_columns(:status=> a[:job_process], :updated_at=> DateTime.now(), :updated_by=> 1)
                  end
                else
                  record = EmployeePresence.find_by(:kind=> a[:kind], :date=> a[:date], :employee_id=> employee_id)
                  if record.present?
                    case a[:job_process]
                    when "active", "remove"
                      record.update_columns(:status=> a[:job_process], :updated_at=> DateTime.now(), :updated_by=> 1)
                    end
                  end
                end
              end
            end

            # update schedule tanpa hk
            # schedule_without_hk(plant, period_begin.to_date.strftime("%Y%m"), nil, hrd_employee_id)
          end
        else
          puts "#{att_user.id_number} status #{att_user.status}"
          EmployeePresence.where(:status=> 'active', :company_profile_id=> plant, :employee_id=> att_user.employee_id, :period=> period_yyyymm).order("date asc").each do |a|
            a.update_columns(:status=> 'remove')
          end
        end
      end
    end

    def update_working_hour_summary(plant_id, period_yyyymm, employee_id)
      period_yyyymmdd        = ("#{period_yyyymm}01").to_date.beginning_of_month().strftime("%Y-%m-%d")
      period_begin  = period_yyyymmdd.to_date+20.day if period_yyyymmdd.present?
      period_end    = period_yyyymmdd.to_date+1.month+19.day if period_yyyymmdd.present?

      # array untuk digunakan oleh function get_absence
      holiday_date_array = []
      HolidayDate.where(:status=> 'active').where("date between ? and ?", period_begin, period_end).each do |hd|
        holiday_date_array << {
          :date=> hd.date,
          :holiday=> hd.holiday,
          :description=> hd.description
        }
      end

      hrd_schedule = []
      Schedule.where(:status=> 'active').each do |schedule|
        hrd_schedule << {
          :id=> schedule.id, 
          :company_profile_id=> schedule.company_profile_id,
          :code=> schedule.code,
          :monday_in=> schedule.monday_in, :monday_out=> schedule.monday_out, 
          :tuesday_in=> schedule.tuesday_in, :tuesday_out=> schedule.tuesday_out, 
          :wednesday_in=> schedule.wednesday_in, :wednesday_out=> schedule.wednesday_out, 
          :thursday_in=> schedule.thursday_in, :thursday_out=> schedule.thursday_out, 
          :friday_in=> schedule.friday_in, :friday_out=> schedule.friday_out, 
          :saturday_in=> schedule.saturday_in, :saturday_out=> schedule.saturday_out, 
          :sunday_in=> schedule.sunday_in, :sunday_out=> schedule.sunday_out
        }
      end 
      holiday_in_month = 0
      employee_schedule_array = []
      EmployeeSchedule.where(:employee_id=> employee_id, :status=> 'active', :company_profile_id=> plant_id).where("date between ? and ?", period_begin, period_end).each do |employee_schedule|
        hrd_schedule.each do |schedule|
          if schedule[:id].to_i == employee_schedule.schedule_id.to_i
            employee_schedule_array << {
              :schedule_id=> employee_schedule.schedule_id,
              :period_shift=> employee_schedule.date,
              :schedule_code => schedule[:code],
              :employee_id=> employee_id
            }

            holiday_in_month+=1 if schedule[:code] == 'L'
          end
        end
      end

      employee_absence_type = []
      EmployeeAbsenceType.where(:status=> 'active').each do |at|
        employee_absence_type << {
          :id=> at.id,
          :code=> at.code,
          :name=> at.name,
          :description=> at.description,
          :max_day=> at.max_day,
          :special=> at.special
        }
      end
      employee      = Employee.find_by(:id=> employee_id)
      employee_pin = AttendanceUser.find_by(:employee_id=>employee.id)
        puts 'jajajajaj'
      if employee.present?
        puts 'jahjajajja'
        employee_name         = employee.name
        sys_plant_id          = employee.company_profile_id
        hrd_employee_id       = employee.id
        
        att_user              = AttendanceUser.find_by(:employee_id=> employee_id, :company_profile_id=> sys_plant_id, :status=> 'active')
        # 2021-12-21 preventif jika ada double data
        WorkingHourSummary.where(:company_profile_id=> sys_plant_id, :period_begin=> period_begin, :period_end=> period_end, :employee_id=> employee_id).each do |working_hour_summary|
          working_hour_summary.update_columns(:status=> 'disabled')
        end
        working_hour_summary  = WorkingHourSummary.find_by(:company_profile_id=> sys_plant_id, :period_begin=> period_begin, :period_end=> period_end, :employee_id=> employee_id)
        
        check_schedule = EmployeeSchedule.where(:company_profile_id=> sys_plant_id, :employee_id=> hrd_employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end)
        if check_schedule.present?
          puts employee.resign_date
          if employee.resign_date.present? and (employee.resign_date < period_begin)
            puts "--------------------------------------------------------------------------"
            puts "tgl.resign: #{employee.resign_date} < periode awal: #{period_begin} = #{employee.resign_date < period_begin}"
            puts "USER DI NON-AKTIF KAN KARENA HABIS KONTRAK SEBELUM PERIODE #{period_yyyymm}"
            puts "--------------------------------------------------------------------------"
            att_user.update_columns(:status=> 'suspend') if att_user.present?
            working_hour_summary.update_columns(:status=> 'disabled') if working_hour_summary.present?
          else
            update_employee      = false
            record_employee      = []
            record_working_hour_summary = false
            update_working_hour_summary = []
            
            if att_user.present?
              precompile_process  = false

              # if employee.hrd_work_status.present? and employee.hrd_work_status.payroll == 1 and employee.join_date.to_date <= period_end.to_date
              #   precompile_process  = true
              # end
              if employee.company_profile_id.present?  and employee.join_date.to_date <= period_end.to_date
                precompile_process  = true
              end
              # puts "#{employee.hrd_work_status.payroll if employee.hrd_work_status.present?}; join_date: #{employee.join_date.to_date} < period_end: #{period_end.to_date} => #{precompile_process}"
              puts "#{employee.company_profile.name if employee.company_profile.present?}; join_date: #{employee.join_date.to_date} < period_end: #{period_end.to_date} => #{precompile_process}"
              
              if precompile_process == true
                attendences = AttendanceLog.where(:company_profile_id=> sys_plant_id, :employee_id=> hrd_employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date_time asc")
                count = 0
                att_log_array = []
                attendences.each do |att|
                  case att.type_presence
                  when 'in'
                    acc_code = 'Att'
                  else
                    acc_code = 'Ext'
                  end
                  att_log_array << {
                    :manual_presence=> false, 
                    :empl_code=> att.id_number, 
                    :period_shift=> att.date.strftime("%Y-%m-%d"), 
                    :tr_date=> att.date_time.strftime("%Y-%m-%d"), 
                    :tr_time=> att.date_time.strftime("%H:%M:%S"), 
                    :acc_code=> acc_code, 
                    :without_repair_period_shift=> att.without_repair_period_shift, 
                    :type_presence=> att.type_presence
                  }
                  count += 1
                end
                # employee_schedules    = HrdEmployeeSchedule.where(:sys_plant_id=> sys_plant_id, :hrd_employee_id=> hrd_employee_id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date asc")
                # holiday_in_month = 0
                # employee_schedules.each do |employee_schedule|
                #   if employee_schedule.hrd_schedule_id == 1
                #     holiday_in_month+=1
                #   end
                # end
                # holiday_in_month      = employee_schedules.where(:hrd_schedule_id=> 1).count() 
           
                if employee.work_schedule == ''
                  case holiday_in_month
                  when 4
                    record_employee << {:id=> employee.id, :work_schedule=> '6-0', :job_process=> 'update'}
                    # employee.update_columns(:work_schedule=> '6-0')
                    puts "update work_schedule => '6-0'"
                    update_employee  = true
                  when 8
                    record_employee << {:id=> employee.id, :work_schedule=> '5-0', :job_process=> 'update'}
                    # employee.update_columns(:work_schedule=> '5-0')
                    puts "update work_schedule => '5-0'"
                    update_employee  = true
                  end
                end

                sys_department_id     = employee.department_id
                period                = period_begin.to_date.strftime("%Y%m")
                period_begin          = period_begin
                period_end            = period_end          
              end
              
              if working_hour_summary.present?
                if employee.company_profile.present? and employee.company_profile_id == 1
                  puts "[#{period}] update working hour summary #{employee.name}"  
                  working_hour_summary.update_columns(:status=> 'active' ) if working_hour_summary.status == 'disabled'
                else
                  if employee.join_date.to_date > period_begin.to_date
                    note = "tidak masuk payroll #{employee_name} => join_date: #{employee.join_date.to_date}" 
                  else  
                    note = "tidak masuk payroll #{employee_name} => #{employee.company_profile.name if employee.company_profile.present?}"  
                  end 
                  working_hour_summary.update_columns(:status=> 'disabled', :note=> note)
                end
              else            
                if precompile_process == true
                  working_hour_summary = WorkingHourSummary.new({
                    :company_profile_id=> sys_plant_id,
                    :employee_id=> hrd_employee_id,
                    :department_id=> sys_department_id,
                    :period=> period, :period_begin=> period_begin, :period_end=> period_end,
                    :working_weekday=> 0,
                    :working_off_day=> 0,
                    :overtime_hour=> 0,
                    :working_weekend=> 0,
                    :working_hour=> 0,
                    :overtime_first_hour=> 0,
                    :overtime_second_hour=> 0,
                    :overtime_4_7=> 0,
                    :overtime_8_11=> 0,
                    :overtime_11plus=> 0,
                    :overtime_5_8=> 0,
                    :overtime_8plus=> 0,
                    :absence_a=> 0,
                    :absence_i=> 0,
                    :absence_s=> 0,
                    :absence_c=> 0,
                    :absence_l=> 0,
                    :late_come=> 0,
                    :home_early=> 0,
                    :status=> 'active', 
                    :created_by=> 1, :created_at=> DateTime.now()
                  })
                  working_hour_summary.save!
                  puts "[#{period}] create working hour summary #{employee.name}"   
                end
              end
              puts "---------------------------------------------------------"

              if precompile_process == true
                if working_hour_summary.present?
                  sum_working_hour = 0
                  sum_overtime  = 0
                  sum_absence_a = 0
                  sum_absence_i = 0
                  sum_absence_s = 0
                  sum_absence_c = 0
                  sum_absence_l = 0
                  sum_late_come = 0
                  sum_home_early = 0

                  # 2022-01-24 aden: solusi jika ada penghapusan schedule
                  WorkingHourSummaryItem.where(:working_hour_summary_id=> working_hour_summary.id, :status=> 'active').each do |whs_item|
                    whs_item.update_columns(:status=> 'suspend')
                  end
                  employee_schedule_array.each do |es|
                    att_time_in = nil
                    att_time_out = nil

                    att_log_array.each do |att_log|
                      if att_log[:period_shift].to_date == es[:period_shift].to_date
                        case att_log[:type_presence] 
                        when 'in'
                          # jika terjadi 2x sepasang IN OUT dalam periode yg sama, untuk IN ambil yg awal
                          att_time_in = att_log[:tr_time] if att_time_in.blank?
                        when 'out'
                          att_time_out = att_log[:tr_time]
                        end
                      end
                    end

                    day_name = es[:period_shift].to_date.strftime("%A").downcase
                    schedule_code     = nil
                    schedule_overday  = nil
                    schedule_time_in  = nil
                    schedule_time_out = nil
                    hrd_schedule.each do |schedule|
                      if schedule[:id].to_i == es[:schedule_id].to_i
                        schedule_code     = schedule[:code]
                        schedule_overday  = schedule[:overday]
                        schedule_time_in  = schedule["#{day_name}_in".to_sym]
                        schedule_time_out = schedule["#{day_name}_out".to_sym]

                      end
                    end
                    puts "===================================================="
                    if schedule_code.present?
                      working_hour     = get_working_hour(sys_plant_id, att_user.id_number, es[:period_shift], schedule_time_in, schedule_time_out, schedule_code)
                      overtime_per_day = get_overtime(sys_plant_id, att_log_array, hrd_employee_id, att_user.id_number, 'all', es[:period_shift], es[:period_shift])

                      absence_a        = get_absence(sys_plant_id, hrd_employee_id, att_log_array, holiday_date_array, hrd_schedule, employee_schedule_array, employee_absence_type, 'A', es[:period_shift], es[:period_shift])
                      absence_i        = get_absence(sys_plant_id, hrd_employee_id, att_log_array, holiday_date_array, hrd_schedule, employee_schedule_array, employee_absence_type, 'I', es[:period_shift], es[:period_shift])
                      absence_s        = get_absence(sys_plant_id, hrd_employee_id, att_log_array, holiday_date_array, hrd_schedule, employee_schedule_array, employee_absence_type, 'S', es[:period_shift], es[:period_shift])
                      absence_c        = get_absence(sys_plant_id, hrd_employee_id, att_log_array, holiday_date_array, hrd_schedule, employee_schedule_array, employee_absence_type, 'C', es[:period_shift], es[:period_shift])
                      absence_l        = get_absence(sys_plant_id, hrd_employee_id, att_log_array, holiday_date_array, hrd_schedule, employee_schedule_array, employee_absence_type, 'L', es[:period_shift], es[:period_shift])
                    puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                    else
                      working_hour     = 0
                      overtime_per_day = 0
                      absence_a        = 0
                      absence_i        = 0
                      absence_s        = 0
                      absence_c        = 0
                      absence_l        = 0
                    end
                    # mencari jam kerja (aktual)
                    count = 0
                    att_array  = []
                    att_log_array.each do |att|
                      if att[:period_shift].to_date == es[:period_shift].to_date
                        att_array << {
                          :id_number=> att[:empl_code], 
                          :date=> att[:period_shift], 
                          :time=> att[:tr_time], 
                          :date_time=> "#{att[:tr_date]} #{att[:tr_time]}", 
                          :type_presence=> att[:type_presence] }
                        count += 1
                      end
                    end
                    att_array_new  = []
                    (0..count).each do |c|
                      if att_array[c+1].present?
                        if att_array[c][:type_presence] == 'in' and att_array[c+1][:type_presence] == 'out'
                          att_array_new << {:id_number=> att_array[c][:id_number], :date=> att_array[c][:date], :att_in=> att_array[c][:date_time], :att_out=> att_array[c+1][:date_time] }
                        end
                      end
                    end
                    # puts att_array
                    working_hour_actual = 0
                    att_array_new.each do |x|
                      working_hour_actual += TimeDifference.between(x[:att_in], x[:att_out]).in_hours
                    end

                    if schedule_time_in.present? and schedule_time_out.present?
                      late_come        = get_late_in(att_array, es[:period_shift].to_date, "#{es[:period_shift].to_date} #{schedule_time_in.strftime("%H:%M:%S")}".to_time)
                      home_early       = get_leave_early(att_array, es[:period_shift].to_date, "#{es[:period_shift].to_date} #{schedule_time_out.strftime("%H:%M:%S")}".to_time)
                    else
                      late_come        = 0
                      home_early       = 0
                    end
                    puts "    => #{es[:period_shift].to_date} working_hour: #{working_hour}"
                    puts "    => #{es[:period_shift].to_date} working_hour_actual: #{working_hour_actual}"
                    puts "    => #{es[:period_shift].to_date} overtime: #{overtime_per_day}"
                    puts "    => #{es[:period_shift].to_date} datang telat: #{late_come}"
                    puts "    => #{es[:period_shift].to_date} pulang awal: #{home_early}"
                    puts "    => #{es[:period_shift].to_date} Absen [A]: #{absence_a}"
                    puts "    => #{es[:period_shift].to_date} Absen [I]: #{absence_i}"
                    puts "    => #{es[:period_shift].to_date} Absen [S]: #{absence_s}"
                    puts "    => #{es[:period_shift].to_date} Absen [C]: #{absence_c}"
                    puts "    => #{es[:period_shift].to_date} Absen [L]: #{absence_l}"
                    # puts "#{att_user.sys_plant_id} PIN: #{att_user.id_number} => in: #{att_time_in}; out: #{att_time_out}"
                    
                    WorkingHourSummaryItem.where(:working_hour_summary_id=> working_hour_summary.id, :date=> es[:period_shift].to_date, :status=> 'active').each do |whs_item|
                      whs_item.update_columns(:status=> 'suspend')
                    end
                    whs_item = WorkingHourSummaryItem.find_by(:working_hour_summary_id=> working_hour_summary.id, :date=> es[:period_shift].to_date)
                    if whs_item.present?
                      whs_item.schedule_id = es[:schedule_id]
                      whs_item.att_time_in     = (att_time_in.present? ? att_time_in : nil)
                      whs_item.att_time_out    = (att_time_out.present? ? att_time_out : nil)
                      whs_item.working_hour    = working_hour
                      whs_item.working_hour_actual = working_hour_actual
                      whs_item.overtime        = overtime_per_day
                      whs_item.absence_a       = absence_a
                      whs_item.absence_i       = absence_i
                      whs_item.absence_s       = absence_s
                      whs_item.absence_c       = absence_c
                      whs_item.absence_l       = absence_l
                      whs_item.late_come       = late_come
                      whs_item.home_early      = home_early
                      whs_item.status          = 'active'

                      if whs_item.changed?
                        puts "update item: #{es[:period_shift].to_date} => #{whs_item.changes}"
                        whs_item.update_columns({
                          :schedule_id=> es[:schedule_id],
                          :att_time_in=> (att_time_in.present? ? att_time_in : nil),
                          :att_time_out=> (att_time_out.present? ? att_time_out : nil),
                          :working_hour=> working_hour, :working_hour_actual=> working_hour_actual,
                          :overtime=> overtime_per_day,
                          :absence_a=> absence_a, 
                          :absence_i=> absence_i, 
                          :absence_s=> absence_s, 
                          :absence_c=> absence_c, 
                          :absence_l=> absence_l, 
                          :late_come=> late_come,
                          :home_early=> home_early,
                          :status=> 'active', :updated_by=> 1, :updated_at=> DateTime.now()
                        })
                      end
                      puts "updated #{whs_item.id}"
                    else
                      whs_item = WorkingHourSummaryItem.new({
                        :working_hour_summary_id=> working_hour_summary.id ,
                        :schedule_id=> es[:schedule_id],
                        :date=> es[:period_shift].to_date,
                        :att_time_in=> (att_time_in.present? ? att_time_in : nil),
                        :att_time_out=> (att_time_out.present? ? att_time_out : nil),
                        :working_hour=> working_hour, :working_hour_actual=> working_hour_actual,
                        :overtime=> overtime_per_day,
                        :absence_a=> absence_a, 
                        :absence_i=> absence_i, 
                        :absence_s=> absence_s, 
                        :absence_c=> absence_c, 
                        :absence_l=> absence_l,
                        :late_come=> late_come,
                        :home_early=> home_early,
                        :status=> 'active', :created_by=> 1, :created_at=> DateTime.now()
                      })
                      whs_item.save
                      puts "create item: #{es[:period_shift].to_date}"
                    end
                    sum_working_hour += working_hour.to_f
                    sum_overtime  += overtime_per_day.to_f
                    sum_absence_a += absence_a.to_f
                    sum_absence_i += absence_i.to_f
                    sum_absence_s += absence_s.to_f
                    sum_absence_c += absence_c.to_f
                    sum_absence_l += absence_l.to_f
                    sum_late_come += late_come.to_f
                    sum_home_early += home_early.to_f
                    puts "summary ot: #{sum_overtime}; #{es[:period_shift]} => #{overtime_per_day}"
                  end

                  puts "-----------------------------------------------------------"
                  working_weekday       = employee.working_weekday(att_log_array, hrd_schedule, period_begin, period_end) #done
                  # puts "employee.working_weekday(att_log_array, hrd_schedule, #{period_begin}, #{period_end})"
                  # puts "working_weekday: #{working_weekday}"
                  working_off_day       = employee.working_off_day(holiday_date_array, employee_schedule_array, period_begin, period_end) #done
                  # overtime_hour         = employee.ot_period(period_begin, period_end)
                  overtime_hour         = sum_overtime.to_i
                  working_weekend       = employee.working_weekend(period_begin, period_end) #done
                  # working_hours         = employee.working_hour(period_begin, period_end).round(2)
                  working_hours         = sum_working_hour.to_i

                  overtime_first_hour   = employee.first_hour_ot(att_log_array, period_begin, period_end)
                  overtime_second_hour  = employee.second_hour_ot(att_log_array, period_begin, period_end)
                  overtime_4_7          = employee.four_to_seven_hour_ot(att_log_array, period_begin, period_end)
                  overtime_8_11         = employee.eight_to_eleven_hour_ot(att_log_array, period_begin, period_end)
                  overtime_11plus       = employee.above_eleven_hour_ot(att_log_array, period_begin, period_end)
                  overtime_5_8          = employee.five_to_eight_hour_ot(att_log_array, period_begin, period_end)
                  overtime_8plus        = employee.above_eight_hour_ot(att_log_array, period_begin, period_end)

                  # sum_absence_a = get_absence(sys_plant_id, att_user.id_number, 'A', period_begin, period_end)
                  working_hour_summary.working_weekday  = working_weekday
                  working_hour_summary.working_off_day  = working_off_day
                  working_hour_summary.overtime_hour    = overtime_hour
                  working_hour_summary.working_weekend  = working_weekend
                  working_hour_summary.working_hour     = working_hours
                  working_hour_summary.overtime_first_hour  = overtime_first_hour.to_i
                  working_hour_summary.overtime_second_hour = overtime_second_hour.to_i
                  working_hour_summary.overtime_4_7     = overtime_4_7.to_i
                  working_hour_summary.overtime_8_11    = overtime_8_11.to_i
                  working_hour_summary.overtime_11plus  = overtime_11plus.to_i
                  working_hour_summary.overtime_5_8     = overtime_5_8.to_i
                  working_hour_summary.overtime_8plus   = overtime_8plus.to_i
                  working_hour_summary.absence_a        = sum_absence_a
                  working_hour_summary.absence_i        = sum_absence_i
                  working_hour_summary.absence_s        = sum_absence_s
                  working_hour_summary.absence_c        = sum_absence_c
                  working_hour_summary.absence_l        = sum_absence_l
                  working_hour_summary.late_come        = sum_late_come
                  working_hour_summary.home_early       = sum_home_early


                  if working_hour_summary.changed?
                    puts "update: [#{employee_pin.id_number}] #{employee_name} => #{working_hour_summary.changes}"
                    working_hour_summary.update_columns({ 
                      :working_weekday=> working_weekday,
                      :working_off_day=> working_off_day,
                      :overtime_hour=> overtime_hour,
                      :working_weekend=> working_weekend,
                      :working_hour=> working_hours,
                      :overtime_first_hour=> overtime_first_hour,
                      :overtime_second_hour=> overtime_second_hour,
                      :overtime_4_7=> overtime_4_7,
                      :overtime_8_11=> overtime_8_11,
                      :overtime_11plus=> overtime_11plus,
                      :overtime_5_8=> overtime_5_8,
                      :overtime_8plus=> overtime_8plus,               
                      :absence_a=> sum_absence_a,
                      :absence_i=> sum_absence_i,
                      :absence_s=> sum_absence_s,
                      :absence_c=> sum_absence_c,
                      :absence_l=> sum_absence_l,
                      :late_come=> sum_late_come,
                      :home_early=> sum_home_early,
                      :status=> 'active'
                    })
                  end
                end

                puts "-----------------------------------------------------------"
                puts "summary working hour [#{employee_pin.id_number}] #{employee_name}"
                puts "-----------------------------------------------------------"
                puts "  :sys_plant_id=> #{sys_plant_id},"
                puts "  :hrd_employee_id=> #{hrd_employee_id},"
                puts "  :sys_department_id=> #{sys_department_id},"
                puts "  :period=> #{period},"
                puts "  :period_begin=> #{period_begin}, :period_end=> #{period_end},"
                puts "  :working_weekday=> #{working_weekday},"
                puts "  :working_off_day=> #{working_off_day},"
                puts "  :overtime_hour=> #{overtime_hour},"
                puts "  :working_weekend=> #{working_weekend},"
                puts "  :working_hour=> #{working_hours},"
                puts "  :overtime_first_hour=> #{overtime_first_hour},"
                puts "  :overtime_second_hour=> #{overtime_second_hour},"
                puts "  :overtime_4_7=> #{overtime_4_7},"
                puts "  :overtime_8_11=> #{overtime_8_11},"
                puts "  :overtime_11plus=> #{overtime_11plus},"
                puts "  :overtime_5_8=> #{overtime_5_8},"
                puts "  :overtime_8plus=> #{overtime_8plus},"
                puts "  :absence_a=> #{sum_absence_a},"   
                puts "  :absence_i=> #{sum_absence_i},"   
                puts "  :absence_s=> #{sum_absence_s},"   
                puts "  :absence_c=> #{sum_absence_c},"   
                puts "  :absence_l=> #{sum_absence_l},"
                puts "  :late_come=> #{sum_late_come},"
                puts "  :home_early=> #{sum_home_early},"
                puts "-----------------------------------------------------------"
                # if working_weekday == 0
                #   working_hour_summary.update_columns(:status=> 'disabled') 
                # end
              end
              puts note
            else
              puts "[#{sys_plant_id}] employee_id=> #{employee_id}; status non-aktif"
              working_hour_summary.update_columns(:status=> 'disabled') if working_hour_summary.present?
            end


            
            puts "employee update: "
            record_employee.each do |record|
              case record[:job_process]
              when 'update'
                employee.update_columns({:work_schedule=> record[:work_schedule]})
                puts "update work_schedule: #{record[:work_schedule]}"
              end
            end
          end
        else
          puts "tidak ada schedule"
          working_hour_summary.update_columns(:status=> 'disabled') if working_hour_summary.present?
        end
      end
    end
  #perbaiki ---- end -----  

  def presence_period(periode)
    case periode.to_s.last(2)
    when "01"
      result = "21 Jan - 20 Feb"
    when "02"
      result = "21 Feb - 20 Mar"
    when "03"
      result = "21 Mar - 20 Apr"
    when "04"
      result = "21 Apr - 20 Mei"
    when "05"
      result = "21 Mei - 20 Jun"
    when "06"
      result = "21 Jun - 20 Jul"
    when "07"
      result = "21 Jul - 20 Aug"
    when "08"
      result = "21 Aug - 20 Sep"
    when "09"
      result = "21 Sep - 20 Oct"
    when "10"
      result = "21 Oct - 20 Nov"
    when "11"
      result = "21 Nov - 20 Dec"
    when "12"
      result = "21 Dec - 20 Jan"
    end
    return "#{result}"
    # return "#{result} #{periode.to_s.first(4)}"
  end
end
