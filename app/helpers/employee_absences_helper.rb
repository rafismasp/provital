module EmployeeAbsencesHelper
	def update_absence_same_nik(nik, periode)
    periode_yyyy = periode.to_date.strftime("%Y")
    record = {}
    employees = Employee.where(:nik=> nik, :employee_status=> 'Aktif')
    employee_selected = employees.map { |e| e.id }

    if employees.count() > 1
      EmployeeAbsence.where(:employee_id=> employee_selected).where('extract(year from begin_date) = ?', periode_yyyy).order("begin_date asc, updated_at asc").includes(:employee).each do |absence|
        puts "[#{absence.employee_id}] #{absence.employee.name} #{absence.begin_date} sd #{absence.end_date} => #{absence.employee_absence_type.present? ? absence.employee_absence_type.name : "-"} [#{absence.status}]"
        item = absence.as_json
        record[absence.id] = item.except("id", "employee_id")
      end
      # puts JSON.pretty_generate(record)
      employees.each do |employee|
        cek = {}
        record.each do |k, v|
          v.merge!({:employee_id=> employee.id})

          # puts JSON.pretty_generate(v)
          cek[:employee_id] = v[:employee_id]
          cek[:employee_absence_type_id] = v["employee_absence_type_id"]
          cek[:begin_date] = v["begin_date"]
          cek[:end_date] = v["end_date"]
          employee_absence = EmployeeAbsence.find_by(cek)
          if employee_absence.present?
            employee_absence.update_columns({
              :status=> v["status"],
              :updated_at=> v["updated_at"], :updated_by=> v["updated_by"],
              :deleted_at=> v["deleted_at"], :deleted_by=> v["deleted_by"],
              :approved1_by=> v["approved1_by"], :approved1_at=> v["approved1_at"],
              :canceled1_by=> v["canceled1_by"], :canceled1_at=> v["canceled1_at"],
              :approved2_by=> v["approved2_by"], :approved2_at=> v["approved2_at"],
              :canceled2_by=> v["canceled2_by"], :canceled2_at=> v["canceled2_at"],
              :approved3_by=> v["approved3_by"], :approved3_at=> v["approved3_at"],
              :canceled3_by=> v["canceled3_by"], :canceled3_at=> v["canceled3_at"]
            }) if v["status"] != employee_absence.status
          else
            # insert form cuti izin dengan data karyawan yg NIK nya sama
            puts "[#{employee.nik}] [absence_id: #{k}] Absen employee #{employee.id} not found"
            # puts JSON.pretty_generate(cek)
            EmployeeAbsence.create(v)
          end
        end
        # update sisa cuti
        if EmployeeLeave.find_by(:period=> periode_yyyy, :status=> 'active', :employee_id=> employee.id).blank?
          EmployeeLeave.create({
            :period=> periode_yyyy, 
            :status=> 'active', 
            :employee_id=> employee.id,
            :created_at=> DateTime.now(), :created_by=> 1
          })
        end
        leave_this_years(employee.id, employee.join_date, periode_yyyy)[:outstanding]
        puts "---------------------------------------"
      end
    end
  end

	def leave_this_years(employee_id, join_date, tahun)
    if tahun.blank? or tahun == ''
      tahun = Time.now.year 
    end
    puts "employee_id=> #{employee_id}, join_date=> #{join_date}, tahun=> #{tahun}"
    result = []
    total_cuti = 0
    employee = Employee.find(employee_id)
    if employee.present?
      leaves = EmployeeLeave.find_by(:period=> tahun, :status=> 'active', :employee_id=> employee_id)
      puts tahun
      if tahun.to_i == DateTime.now().strftime("%Y").to_i
        now         = ("#{tahun}#{Time.now.strftime("%m%d")}").to_date
      else
        now         = ("#{tahun}1231").to_date
      end
      puts now
      difference  = TimeDifference.between(now, join_date).in_months
      puts "NIK        : #{employee.nik};"
      puts "Schedule   : #{employee.work_schedule};"
      puts "Nama       : #{employee.name};"
      puts "Masuk Kerja: #{join_date};"
      puts "saat ini   : #{now};"
      puts "selisih    : #{difference} bulan;"
        if now.to_date.strftime("%Y").to_i- join_date.to_date.strftime("%Y").to_i > 1
          prorata = 12
        else
          prorata = (12-join_date.month) #jika baru sethaun kerja dapat cuti maka cuti prorata
        end

      puts "prorata    : #{join_date.end_of_year.month}-#{join_date.month} => #{prorata};"

      if employee.work_status.present? and employee.work_status.name == "Magang"
        # 20210105 penomoran NIK magang tidak ngikutin pola yg ada, info sandra itu pak johnny tau
        hak_cuti = 0
        puts "Pekerja dengan kontrak magang tidak dapat cuti"
      elsif employee.work_status.present? and employee.work_status.name == "Tetap"
        # harusnya ngambil dari cuti nik sebelumnya
        hak_cuti = 12
        puts "karyawan tetap"
      else
        puts "hak putus, jika selisih antara TMK dengan saat ini "
        if difference == 12 or difference > 12
          hak_cuti = prorata
        else
          hak_cuti = 0
        end
      end

      if leaves.present?
        # cuti tahunan = hrd_employee_absence_type_id=>9 
        # total_cuti = HrdEmployeeAbsence.where(:hrd_employee_id=> employee_id, :hrd_employee_absence_type_id=>9,:status=>"app3").where("begin_date >= ? and end_date <= ?","#{tahun}0101".to_date,"#{tahun}1231".to_date).sum(:day)
        total_cuti = 0
        EmployeeAbsence.where(:employee_id=> employee_id, :employee_absence_type_id=>9, :status=>"approved3").where("begin_date >= ? and end_date <= ?","#{tahun}0101".to_date,"#{tahun}1231".to_date).each do |item|
          total_cuti += item.day
          (item.begin_date..item.end_date).each do |dt|
            puts "#{dt} #{dt.strftime("%A")}"
            case employee.work_schedule
            when '6-0', '6-2'
              case dt.strftime("%A")
              when 'Sunday'
                total_cuti -= 1
              end
            when '5-0'
              case dt.strftime("%A")
              when 'Saturday', 'Sunday'
                total_cuti -= 1
              end
            end
          end
        end
        
        # total_cuti = HrdEmployeeAbsence.where(:hrd_employee_id=> employee_id, :hrd_employee_absence_type_id=>9,:status=>"app3").where("begin_date > ? ","#{tahun}0101".to_date).sum(:day)
        
        puts "total_cuti :#{total_cuti}"
        result = (hak_cuti-total_cuti.to_i)    
        leaves.update_columns({
          :day=> total_cuti,
          :outstanding=> result
        })    
      elsif join_date.present?
        result = hak_cuti
      end
      
      puts "hak cuti   : #{hak_cuti};"
      puts "sisa cuti  : #{result};"
      puts "-----------------------"
    end
    return {:day=> total_cuti, :outstanding=> result}
  end
end
