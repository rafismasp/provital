namespace :attendances do
  desc "Attendances" 
  # cek sisa cuti
  # rake attendances:sisa_cuti

  task :perbaikan_absen_manual => :environment do |t, args|
    ManualPresence.where("id_number like ?", '%.0').each do |item|
      puts item.id_number.to_s[0..3]
      item.update({
        :id_number=> item.id_number.to_s[0..3],
        :pin=> item.id_number.to_s[0..3]
      })
    end
  end
	# pastikan mesin HK sudah tarik data

	# tarik data mesin absensi
	# rake attendances:get_attendance

  
  task :check_att_ngaco => :environment do |t, args|
    # BWXP201160762 Security Techno
    # A5NM180261243 lobby TSSI
    # BWXP191161373 Kantin TSSI
    # BWXP201160583 Security TSSI
    ActiveRecord::Base.establish_connection :development
    arr_record = [
      {:sn=> 'BWXP201160769', :kind=> 'provital', :company_profile_id=> 1}
    ]

    AttendanceLog.where(:company_profile_id=> args[:plant], :id_number=> ['2348']).where("date between ? and ?", '2020-09-21', '2020-10-20').order("date_time asc").each do |record|
      puts "name: #{record.employee.name};"
      puts "id_number: #{record.id_number};"
      puts "loc_code: #{record.loc_code};"
      puts "date: #{record.date};"
      puts "time: #{record.time};"
      puts "I/O: #{record.type_presence};"
      puts "status: #{record.status};"
      arr_record.each do |x|
        if x[:sn] == record.loc_code
          if x[:company_profile_id].to_i != record.employee.company_profile_id.to_i
            record.update_columns(:status=> 'remove')
            puts "#{x[:sn]}                                X" 
          else
            record.update_columns(:status=> 'active')
          end
        end
      end
      puts "-----------------------------------------------"
    end
  end

  task :get_fingerprint_log => :environment do |t, args|  	
  	# tarik dari mesin finger print
    ActiveRecord::Base.establish_connection :development

		# period_begin = "#{DateTime.now().strftime("%Y-%m")}-21".to_date
		# period_end   = (DateTime.now()+1.month).to_date.strftime("%Y-%m-20").to_date

    period_begin = '2022-10-20'.to_date
    period_end   = '2022-11-21'.to_date
    # period_begin = (DateTime.now()-1.days).to_date.strftime("%Y-%m-%d")
    # period_end   = DateTime.now().strftime("%Y-%m-%d")
		puts period_begin
		puts period_end
		user_id_not_found = []
		# employee_id_not_found = []
		# tarik data presensi dari DB mesin Finger Print
		# case args[:plant].to_i
		# when 1
			# 2020-04-06 => finger print baru digunakan di TSSI
	    FpAbsensiLog.where(:plant_mark=>'Provital').where("tr_date between ? and ?", period_begin, period_end).order("tr_date asc, tr_time asc").each do |att|
	    	puts "[#{att.emp_code}] #{att.tr_date} #{att.tr_time.strftime("%H:%M:%S")}"
	    	if att.emp_code.present?
		    	check = AbsensiFpabsen.find_by(:empl_code=> att.emp_code, :tr_date=> att.tr_date, :tr_time=> att.tr_time.strftime("%H:%M:%S"), :acc_code=> att.acc_code)
		    	if check.blank?
		    		puts "[FP] Create record"
		    		AbsensiFpabsen.create({
		    			:loc_code=> att.loc_code,
		    			:remoteno=> 0,
		    			:empl_code=> att.emp_code, 
		    			:tr_date=> att.tr_date, 
		    			:tr_time=> att.tr_time.strftime("%H:%M:%S"), 
		    			:acc_code=> att.acc_code
		    		})
		    	end	    	
		    else
		    	puts "user_id: #{att.user_id} tidak ada"
		    	user_id_not_found << {:user_id=> att.user_id} unless user_id_not_found.include?({:user_id=> att.user_id})
		    end
	    end
		# end    
    puts user_id_not_found
    # puts employee_id_not_found
  end
  

  task :get_attendance => :environment do | t, args| 
    # pengolahan presensi 
    # tarik data dari DB absensi (192.168.131.223)
    # table => fpabsen, habsen, pcabsen
    # disimpan ke DB sip_234.hrd_attendance_logs
    # include ApplicationHelper
    include EmployeePresenceHelper
    ActiveRecord::Base.establish_connection :development
    # period_begin = DateTime.now().strftime("%Y-%m-%d")
    # period_end   = DateTime.now().strftime("%Y-%m-%d")
    # period_begin = '2020-03-21'.to_date
    # period_end   = '2020-04-20'.to_date
    period_begin = '2022-11-21'.to_date
    period_end   = '2022-12-20'.to_date
    a_time = DateTime.now()
    Department.all.order("name asc").each do |dept|
    	merge_attendance(1, dept.id, period_begin, period_end, nil)
	  end

   	b_time = DateTime.now()
   	puts "process time: #{a_time.strftime("%Y-%m-%d %H:%M:%S")} sd #{b_time.strftime("%Y-%m-%d %H:%M:%S")} => #{TimeDifference.between(a_time.strftime("%Y-%m-%d %H:%M:%S"), b_time.strftime("%Y-%m-%d %H:%M:%S")).in_minutes}"
  end

  task :update_report, [:plant] => :environment do |t, args|
    Rails.logger.level = Logger::DEBUG
    include EmployeePresenceHelper
    ActiveRecord::Base.establish_connection :development
    period_begin = '2022-09-21'.to_date
    period_end   = '2022-10-21'.to_date
    c = 0
    plant = args[:plant]
    result = []
    path    = "#{Rails.root}/public/precompile_diff_time.txt"
    File.open(path, "ab+") do |f|
      f.puts "===================================="
      f.puts "plant: #{plant}"
      f.puts "periode: #{period_begin} sd #{period_end}"
      f.puts "===================================="
    end
    total_diff_in_second = 0
    all_user = HrdAttendanceUser.where(:sys_plant_id=> plant, :status=> 'active').count()
    HrdAttendanceUser.where(:sys_plant_id=> plant, :status=> 'active' ).each do |att_user|
      begin_time = DateTime.now()
      puts "[#{c}/#{all_user}] #{att_user.id_number} #{att_user.name} -------------------------------------------------- begin: #{begin_time.strftime("%Y-%m-%d %H:%M:%S")}"
      update_report(att_user.sys_plant_id, period_begin.to_date.strftime("%Y%m"), att_user.id_number)
      c += 1
      end_time = DateTime.now()
      diff_in_second = TimeDifference.between(begin_time, end_time).in_seconds
      total_diff_in_second += diff_in_second
      puts "[#{c}/#{all_user}] #{att_user.id_number} #{att_user.name} -------------------------------------------------- end: #{end_time.strftime("%Y-%m-%d %H:%M:%S")}; diff: #{diff_in_second}"
      
      result = "[#{c}/#{all_user}] PIN: #{att_user.id_number}; time diff: #{begin_time.strftime("%Y-%m-%d %H:%M:%S")} sd #{end_time.strftime("%Y-%m-%d %H:%M:%S")}; diff in second: #{diff_in_second}"
      
      File.open(path, "ab+") do |f|
        f.puts result
      end
    end
    total_diff_in_hour = (total_diff_in_second/3600).round(2)
    puts "plant: #{plant}"
    puts "periode: #{period_begin} sd #{period_end}"
    puts "jumlah user: #{c}"
    puts "total waktu yg dibutuhkan: #{total_diff_in_hour} Jam; #{total_diff_in_second}"
   File.open(path, "ab+") do |f|
      f.puts "===================================="
      f.puts "plant: #{plant}"
      f.puts "periode: #{period_begin} sd #{period_end}"
      f.puts "jumlah user: #{c}"
      f.puts "total waktu yg dibutuhkan: #{total_diff_in_hour} Jam"
      f.puts "===================================="
    end
    
  end

  task :check_working_hour_summary, [:plant] => :environment do |t, args|
    plant = args[:plant]
    period = '202010'
    end_period = "2020-11-20"
    ActiveRecord::Base.establish_connection :development
    # att_users = HrdAttendanceUser.where(:sys_plant_id=> plant, :status=> 'active').includes(hrd_employee: [:sys_department])
    # .where("hrd_employees.status = ?", 'active').where("hrd_employees.hrd_employee_payroll_id = ?", plant).references(:hrd_employees).order("hrd_employees.name asc")
    employees = HrdEmployee.where(:status=> 'active', :hrd_employee_payroll_id=> plant, :sys_plant_id=> plant).includes(:sys_department)
    .where("contract_begin <= ?", end_period)

    c = 1
    employees.each do |employee|
      working_hour_summary = HrdWorkingHourSummary.find_by(:sys_plant_id=> employee.sys_plant_id, :hrd_employee_id=> employee.id, :period=> period)
      schedule = HrdEmployeeSchedule.find_by(:sys_plant_id=> employee.sys_plant_id, :hrd_employee_id=> employee.id)
      if schedule.blank?
        puts "Schedule tidak ada"
      end
      if working_hour_summary.present?
        if working_hour_summary.working_hour.to_i == 0
          puts "#{employee.pin} Working Hour: #{working_hour_summary.working_hour}"
          puts "NIK: #{employee.nik}"
          puts "Name: #{employee.name}"
          puts "Dept: #{employee.sys_department.name}"
          puts "Status: #{employee.status}"
          puts "contract: #{employee.contract_begin} sd #{employee.contract_end}"
          puts " #{c} --------------------------------------------------"
          c+=1
        end
      else
        puts "#{employee.pin} Belum ada"
          puts "employee_id: #{employee.id}"
          puts "NIK: #{employee.nik}"
          puts "Name: #{employee.name}"
          puts "Dept: #{employee.sys_department.name}"
          puts "Status: #{employee.status}"
          puts "contract: #{employee.contract_begin} sd #{employee.contract_end}"
          puts " #{c} --------------------------------------------------"
          c+=1
      end
    end
  end

  task :update_working_hour_summary, [:plant] => :environment do |t, args|
    Rails.logger.level = Logger::DEBUG
    include HrdHelper
    ActiveRecord::Base.establish_connection :development
    period_begin = '2021-12-21'
    period_end   = '2022-01-21'
    c = 0
    plant = args[:plant]
    result = []
    path    = "#{Rails.root}/public/precompile_diff_time.txt"
    File.open(path, "ab+") do |f|
      f.puts "===================================="
      f.puts "plant: #{plant}"
      f.puts "periode: #{period_begin} sd #{period_end}"
      f.puts "===================================="
    end
    total_diff_in_second = 0
    # id_number_techno = ['1231', '0044', '0054', '0043', '1228', '0012', '3345', '1180', '1250', '1264', '1237', '1080', '1364', '0065', '1396', '1497', '1514', '1557', '1584', '9037', '0105', '0140', '1221', '0162', '2606', '2638', '2867', '2893', '2968', '3099', '1232', '3138', '3155', '3157', '3160', '0292', '3180', '3181', '3184', '3209', '3217', '3220', '3221', '3228', '3236', '3237', '3240', '3245', '3246', '3247', '3259', '3260', '3262', '3267', '3270', '0297', '3274', '3278', '3285', '3286', '3289', '3291', '3295', '3296', '3297', '3301', '3305', '3313', '3318', '3319', '3321', '3324', '3326', '2646', '3331', '3336', '3339', '3340', '3341', '0300', '3342', '3346', '3347', '3349', '0301', '3356', '3359', '3363', '3365', '3367', '3368', '0303', '3370', '3371', '3380', '3385', '3388', '3389', '3397', '3404', '3406', '3408', '3409', '3410', '3411', '3415', '3417', '3419', '3420', '3425', '3426', '3427', '3428', '3430', '3431', '3433', '3434', '3437', '3439', '3443', '3444', '3445', '3446', '3448', '3450', '3452', '3453', '3458', '3464', '3465', '3469', '2598', '2708', '2622', '0285', '2579', '2617', '3503', '2565', '2245', '3352']
    # id_number_tssi   = ['0114', '1538', '1449', '0265', '0046', '0039', '1528', '0044', '2037', '0059', '0060', '2192', '0216', '2026', '0309', '1914', '2341', '2346', '2359', '3154', '2505', '2538', '2539', '2540', '2140', '2167', '2569', '2588', '2590', '0394', '2615', '2648', '2651', '2658', '0342', '2689', '0385', '2711', '2256', '2284', '2286', '2333', '0346', '0348', '2302', '2303', '2394']

    # '1501', '2282','1222','8207','8159'
    id_number = [ '0315','0279','0292'] 
    all_user = AttendanceUser.where(:company_profile_id=> plant, :status=> 'active', :id_number=> id_number).count()
    AttendanceUser.where(:company_profile_id=> plant, :status=> 'active', :id_number=> id_number).each do |att_user|
      begin_time = DateTime.now()
      puts "[#{c}/#{all_user}] #{att_user.id_number} #{att_user.name} -------------------------------------------------- begin: #{begin_time.strftime("%Y-%m-%d %H:%M:%S")}"
      # update_report(att_user.sys_plant_id, '202002', att_user.id_number)
      update_working_hour_summary(att_user.company_profile_id, '202112', att_user.employee_id)
      c += 1
      end_time = DateTime.now()
      diff_in_second = TimeDifference.between(begin_time, end_time).in_seconds
      total_diff_in_second += diff_in_second
      puts "[#{c}/#{all_user}] #{att_user.id_number} #{att_user.name} -------------------------------------------------- end: #{end_time.strftime("%Y-%m-%d %H:%M:%S")}; diff: #{diff_in_second}"
      
      result = "[#{c}/#{all_user}] PIN: #{att_user.id_number}; time diff: #{begin_time.strftime("%Y-%m-%d %H:%M:%S")} sd #{end_time.strftime("%Y-%m-%d %H:%M:%S")}; diff in second: #{diff_in_second}"
      
      File.open(path, "ab+") do |f|
        f.puts result
      end
    end
    total_diff_in_hour = (total_diff_in_second/3600).round(2)
    puts "plant: #{plant}"
    puts "periode: #{period_begin} sd #{period_end}"
    puts "jumlah user: #{c}"
    puts "total waktu yg dibutuhkan: #{total_diff_in_hour} Jam; #{total_diff_in_second}"
   File.open(path, "ab+") do |f|
      f.puts "===================================="
      f.puts "plant: #{plant}"
      f.puts "periode: #{period_begin} sd #{period_end}"
      f.puts "jumlah user: #{c}"
      f.puts "total waktu yg dibutuhkan: #{total_diff_in_hour} Jam"
      f.puts "===================================="
    end
    
  end


  task :update_att_dept => :environment do |t, args|
  	HrdAttendanceUser.where("sys_department_id is null").each do |att|
  		if att.hrd_employee.present?
  			puts "#{att.id_number} - #{att.name} => #{att.sys_department_id}"
  			att.update_columns(:sys_department_id=> att.hrd_employee.sys_department_id)
  		end
  	end
  end
  task :fake_att => :environment do |t, args|
  	AbsensiHabsenTechnoFake.where("tr_date between ? and ?", '2020-03-21', '2020-04-08').order("tr_date asc").each do |att_fake|
  		
  		check = AbsensiHabsenTechno.find_by(
  			:empl_code=> att_fake.empl_code,
  			:tr_date=> att_fake.tr_date.to_date.strftime("%Y-%m-%d"), 
  			:tr_time=> att_fake.tr_time.to_datetime.strftime("%H:%M:%S"), 
  			:acc_code=> att_fake.acc_code)
  		if check.present?
  			puts "update_record [#{att_fake.empl_code}] #{att_fake.tr_date.to_date.strftime("%Y-%m-%d")} #{att_fake.tr_time.to_datetime().strftime("%H:%M:%S")} => #{att_fake.acc_code}"
  			
  			check.update_columns(
  				:tr_no => att_fake.tr_no)
  		else
  			puts "add_record [#{att_fake.empl_code}] #{att_fake.tr_date.to_date.strftime("%Y-%m-%d")} #{att_fake.tr_time.to_datetime().strftime("%H:%M:%S")} => #{att_fake.acc_code}"
  			AbsensiHabsenTechno.create(
	  			:loc_code=> att_fake.loc_code, 
	  			:remoteno=> att_fake.remoteno,
	  			:empl_code=> att_fake.empl_code,
	  			:tr_date=> att_fake.tr_date.to_date.strftime("%Y-%m-%d"), 
	  			:tr_time=> att_fake.tr_time.to_datetime.strftime("%H:%M:%S"), 
	  			:acc_code=> att_fake.acc_code
	  		)
  		end
  	end
  end


  task :att_update_id => :environment do |t, args|
  	count = 1
  	all_count = AbsensiHabsenTechno.all.count()
  	AbsensiHabsenTechno.all.order("tr_date asc").each do |att_fake|
  		puts "#{count}/#{all_count} => #{((count.to_f/all_count.to_f)*100).round(2)} %"
  		att_fake.update_columns(:tr_no_new=> count)
  		count += 1
  	end
  end

  task :update_absence_manual => :environment do |t, args|
    array = [
      {:pin=> "7101", :nik=> "1020003", :name=> "Yudia Risaldi", :in=> "2021-05-20 15:55:00", :out=> nil},
      {:pin=> "3548", :nik=> "2102002", :name=> "Andhika Cahaya", :in=> "2021-04-30 23:55:00", :out=> "2021-05-01 08:15:00"},
      {:pin=> "3548", :nik=> "2102002", :name=> "Andhika Cahaya", :in=> nil, :out=> "2021-04-29 08:15:00"},
      {:pin=> "7152", :nik=> "1040009", :name=> "Septiyan Duwi Kurniawan", :in=> nil, :out=> "2021-04-26 16:15:00"},
      {:pin=> "3393", :nik=> "1905013", :name=> "Ryan Nanda Muhammad Ichsan", :in=> "2021-05-02 15:55:00", :out=> nil},
      {:pin=> "3350", :nik=> "1903006", :name=> "Nuraeni", :in=> "2021-05-10 07:55:00", :out=> nil},
      {:pin=> "3372", :nik=> "1904007", :name=> "Aulia Febriani", :in=> nil, :out=> "2021-04-29 08:15:00"},
      {:pin=> "3407", :nik=> "1906006", :name=> "Azzmi Zuaninka", :in=> "2021-04-29 23:55:00", :out=> nil},
      {:pin=> "3552", :nik=> "2102006", :name=> "Danu Leagung Berto", :in=> nil, :out=> "2021-04-30 08:15:00"},
      {:pin=> "3534", :nik=> "2012011", :name=> "Moh. Afief", :in=> "2021-05-19 15:55:00", :out=> "2021-05-20 00:15:00"},
      {:pin=> "3534", :nik=> "2012011", :name=> "Moh. Afief", :in=> "2021-05-20 15:55:00", :out=> "2021-05-21 00:15:00"},
      {:pin=> "3450", :nik=> "1908223", :name=> "Gilang Dwi Cahyanto", :in=> nil, :out=> "2021-05-06 08:15:00"},
      {:pin=> "3450", :nik=> "1908223", :name=> "Gilang Dwi Cahyanto", :in=> "2021-05-06 23:55:00", :out=> "2021-05-07 08:15:00"},
      {:pin=> "0044", :nik=> "0703002", :name=> "Cahyo Sukmono", :in=> nil, :out=> "2021-05-18 08:15:00"},


    ]

    loc_code      = 'Manual'
    sys_plant_id  = 2
    array.each do |record|
      if record[:pin].present?
        hrd_employee = HrdEmployee.find_by(:sys_plant_id=> sys_plant_id, :nik=> record[:nik], :pin=> record[:pin])
        if record[:in].present?
          date = record[:in].to_date.strftime("%Y-%m-%d")
          time_in = record[:in].to_datetime.strftime("%H:%M:%S")
          time_out = ( record[:out].present? ? record[:out].to_datetime.strftime("%H:%M:%S") : nil)
        end

        if record[:out].present? and record[:in].blank?
          date = record[:out].to_date.strftime("%Y-%m-%d")
          time_in = nil
          time_out = record[:out].to_datetime.strftime("%H:%M:%S")
        end
        # puts ":id_number=> #{record[:pin]}," 
        # puts ":possibly_wrong_push=> 0,"
        # puts ":without_repair_period_shift=> 0," 
        # puts ":sys_plant_id=> #{sys_plant_id},"
        # puts ":hrd_employee_id=> #{hrd_employee.id},"
        # puts ":date=> #{date},"
        # puts ":time=> #{time_in},"
        # puts ":date_time=> #{record[:in]}, "
        # puts ":mode_presence=> Att,"
        # puts ":type_presence=> 'in',"
        puts "nik: #{record[:nik]}; pin: #{record[:pin]}; name: #{record[:name]}" if hrd_employee.blank? 
        if record[:in].present?
          check_in  = HrdAttendanceLog.find_by(:id_number=> record[:pin], :date_time=> record[:in], :type_presence=> 'in')
          if check_in.blank?
            check_in = HrdAttendanceLog.new({
              :loc_code=> loc_code,
              :id_number=> record[:pin],
              :possibly_wrong_push=> 0,
              :without_repair_period_shift=> 0, 
              :sys_plant_id=> sys_plant_id,
              :hrd_employee_id=> hrd_employee.id,
              :date=> date,
              :time=> time_in,
              :date_time=> record[:in],
              :mode_presence=> 'Att',
              :type_presence=> 'in',
              :status=> 'active',
              :updated_at=> DateTime.now(),
              :updated_by=> 1
            })
            check_in.save!
          end
        end
        if record[:out].present?
          check_out = HrdAttendanceLog.find_by(:id_number=> record[:pin], :date_time=> record[:out], :type_presence=> 'out')
          if check_out.blank?
            check_out = HrdAttendanceLog.new({
              :loc_code=> loc_code,
              :id_number=> record[:pin],
              :possibly_wrong_push=> 0,
              :without_repair_period_shift=> 0, 
              :sys_plant_id=> sys_plant_id,
              :hrd_employee_id=> hrd_employee.id,
              :date=> date,
              :time=> time_out,
              :date_time=> record[:out],
              :mode_presence=> 'Ext',
              :type_presence=> 'out',
              :status=> 'active',
              :updated_at=> DateTime.now(),
              :updated_by=> 1
            })
            check_out.save!
          end
        end
        puts " #{record[:pin]} insert #{date}-------------------- #{record[:name]}"
      end
    end
  end


  task :sisa_cuti => :environment do |t,args|    
    include EmployeeAbsencesHelper

    # ini dari branch adenpribadi
    # lagi lagi 
    # tahun = args[:year].to_s
    tahun = 2022#DateTime.now().strftime("%Y")

    employees = Employee.where(:status=> 'active', :nik=> ['205.21.11.0299'])
    count_employee = employees.count()
    c = 1
    employees.each do |rec|
      leave = EmployeeLeave.find_by(:period=> tahun, :employee_id=> rec.id)
      if leave.blank?
        cuti = leave_this_years(rec.id, rec.join_date, tahun)
        EmployeeLeave.create(
          :period=> tahun,
          :employee_id=> rec.id,
          :day=> cuti[:day],
          :outstanding=> cuti[:outstanding],
          :status=> 'active',
          :created_at=> DateTime.now(),
          :created_by=> 1
          )
        puts "cretead"
        # puts "=================="
        # puts "create #{rec.name}=>#{rec.nik}=>#{cuti[:outstanding]}"
        # puts "==================\n\n"
      else
        cuti = leave_this_years(rec.id, rec.join_date, tahun)
        puts "total cuti saat ini #{leave.day} seharusnya #{cuti[:day]};"
        puts "sisa cuti saat ini #{leave.outstanding} seharusnya #{cuti[:outstanding]};"
        leave.update(
          :period=> tahun,
          :employee_id=> rec.id,
          :day=> cuti[:day],
          :outstanding=> cuti[:outstanding],
          :status=> 'active',
          :created_at=> DateTime.now(),
          :created_by=> 1
          )
        puts "updated"
        # puts "=================="
        # puts "update #{rec.name}=>#{rec.nik}=>#{cuti[:outstanding]}"
        # puts "==================\n\n"
      end
      puts " #{c}/ #{count_employee} ------------------------------"
      c+=1
    end
  end

end