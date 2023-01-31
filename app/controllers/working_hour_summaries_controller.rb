class WorkingHourSummariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_working_hour_summary, only: [:show, :edit, :update]
  before_action :set_instance_variable  

  include UserPermissionsHelper
  include EmployeePresenceHelper
  
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /employee_presences
  # GET /employee_presences.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end


    date = Date.parse("2016-12-31")
    stop = Date.today.beginning_of_month+1.months
    # puts "---------------------"
    @periods = Array.new()
    while (date <= stop)
      date = date.advance(months: 1)
      @periods.push(date.strftime("%Y%m") )
    end
    # period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
    # period_begin = period.to_date+20.day if period.present?
    # period_end = period.to_date+1.month+19.day if period.present?
    # HrdAttendanceUser.where(:status=> 'active').each do |att_user|
    #   get_checkinout('checkinout', period_begin, period_end, att_user.id_number,'Today')
    # end
    # puts "------------"

    
    # period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
    # period_begin = period.to_date+20.day if period.present?
    # period_end = period.to_date+1.month+19.day if period.present?

    if params[:partial]=='precompile_process'
      if params[:precompile_process] == "start"
        precompile_user = []
        params[:max_count] = 0  
        case params[:kind_tbl]
        when 'manual'
          hrd_manual_presence_period = ManualPresencePeriod.find_by(:company_profile_id=> current_user.company_profile_id, :period_yyyymm=> params[:period])
          att_manual = ManualPresence.where(:manual_presence_period_id=> manual_presence_period.id, :status=> 'approved', :precompile_status=> 0).order("status asc, id_number asc, date_time asc")
          
          attendance_users = AttendanceUser.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active', :id_number=> att_manual.group("id_number").select(:id_number))
          attendance_users.order("id_number asc").each do |att_user|
            precompile_user << {:id_number=> att_user.id_number, :status=> "open", :name=> att_user.name}
            params[:max_count] += 1
          end
        else
          employees = Employee.where(:company_profile_id=> current_user.company_profile_id)
          attendance_users = AttendanceUser.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active', :employee_id=> employees.select(:id))
          attendance_users = attendance_users.where(:department_id=> params[:department_id]) if params[:department_id].present?
          attendance_users.order("id_number asc").each do |att_user|
            employee_name = employees.find_by(:id=>att_user.employee_id)
            precompile_user << {:id_number=> att_user.id_number, :status=> "open", :name=> employee_name.name}
            params[:max_count] += 1
          end
        end
        session[:max_count] = params[:max_count]
        session[:precompile_user] = precompile_user 
      end

      params[:counter] = (params[:counter].present? ? (params[:counter]) : 0) 
      
      if params[:counter].present? and params[:counter].to_i > session[:max_count] 
        params[:precompile_process] = "stop"
      end

      case params[:precompile_process]
      when "start"
      when "stop"
        puts "done"
        session[:precompile_user] = nil
        params[:diff_time_summary] = session[:diff_time_summary]
        session[:diff_time_summary] = nil

        case params[:kind_tbl]
        when 'manual'
          record = ManualPresencePeriod.find_by(:company_profile_id=> current_user.company_profile_id, :period_yyyymm=> params[:period])
          record.update({:status=>'approved3' , :approved3_by=>current_user.id,:approved3_at=>DateTime.now},:without_protection=>true) if record.present?
        end
      when "running"
        if session[:precompile_user].present?
          if session[:precompile_user][params[:counter].to_i-1].present? 
            params[:next_id] = session[:precompile_user][params[:counter].to_i-1]['id_number']
            params[:employee_name] = session[:precompile_user][params[:counter].to_i-1]['name']
          end
          begin_time = DateTime.now()

          period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
          period_begin = period.to_date+20.day if period.present?
          period_end = period.to_date+1.month+19.day if period.present?
          
          AttendanceUser.where(:company_profile_id=> current_user.company_profile_id, :id_number=> params[:next_id], :status=> 'active').each do |att_user|
            update_working_hour_summary(current_user.company_profile_id.to_i, params[:period], att_user.employee_id)
          end

          end_time = DateTime.now()
          puts "begin_time: #{begin_time}; end_time: #{end_time}"
          params[:kind_tbl] = params[:kind_tbl] if params[:kind_tbl].present?

          params[:diff_time] = TimeDifference.between(begin_time, end_time).in_seconds
          session[:diff_time_summary] = 0 if session[:diff_time_summary].blank?
          session[:diff_time_summary] += params[:diff_time].to_f
          params[:job_process] = "Done"
          params[:precompile_process] = "running"
          params[:precompile_info] = "#{((params[:counter].to_f/session[:max_count].to_f)*100).round(2)} %"
        else
          puts "tidak ada precompile_user"
        end
      end
        
      # rescue StandardError => error
      #   params[:job_process] = 'warning'
      #   params[:note] = error 
      # end
    

    elsif params[:partial]=='change_employee'
      if params[:view_kind] == 'header'
        department_id = (params[:department_id] == "" ? nil : params[:department_id])
        working_hour_summaries = WorkingHourSummary.where(:department_id=>department_id, :company_profile_id=> current_user.company_profile_id, :status=> 'active', :period_begin=> @period_begin.to_date, :period_end=> @period_end.to_date )
        .includes({employee: :position}, :department)
        working_hour_summaries  = working_hour_summaries.where(:employee_id=> params[:employee_id]) if params[:employee_id].present?
        @working_hour_summaries = working_hour_summaries
      else
        @attendance_user = AttendanceUser.find_by(:employee_id=>params[:employee_id], :status=> 'active')
        edit_working_hour_data(current_user.company_profile_id.to_i, params[:period], params[:employee_id], @period_begin, @period_end)
      end
    else
      @department_selected = (params[:department_id].present? ? params[:department_id] : current_user.department_id)
      @department_selected = (params[:department_id] == "" ? nil : @department_selected)

     
      working_hour_summaries = WorkingHourSummary.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active', :period_begin=> @period_begin.to_date, :period_end=> @period_end.to_date )
      working_hour_summaries = working_hour_summaries.where(:department_id=> @department_selected) if @department_selected.present?
      
      working_hour_summaries  = working_hour_summaries.where(:employee_id=> params[:employee_id]) if params[:employee_id].present?
      working_hour_summaries  = working_hour_summaries.includes({employee: :position}, :department)
      @employee_schedules = EmployeeSchedule.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').where("date between ? and ?", @period_begin, @period_end).where.not("hrd_schedule_id in (5,6,11,12)")

      pagy_items = 10
      @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
      @pagy, @working_hour_summaries = pagy(working_hour_summaries, page: params[:page], items: pagy_items)
    end
  end

  # GET /employee_presences/1
  # GET /employee_presences/1.json
  def show
  end

  # GET /employee_presences/new
  def new
    @employee_presence = EmployeePresence.new
  end

  # GET /employee_presences/1/edit
  def edit
    @attendance_user = @attendance_users
    edit_working_hour_data(current_user.company_profile_id.to_i, params[:period], params[:id], @period_begin, @period_end)
    # att_users = AttendanceUser.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
    # user = []
    # att_users.each do |e|
    #   user << e.employee_id
    # end
    # @employees = @employees.where(:id=> user)
    # @employee_absences = EmployeeAbsence.where(:company_profile_id=> current_user.company_profile_id)
    # @record = @employees.find_by(:id=> params[:id])
    # @att_user = AttendanceUser.find_by(:employee_id=> @record.id) if @record.present?

    # if @att_user.present?
    #   period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
    #   period_begin = period.to_date+20.day if period.present?
    #   period_end = period.to_date+1.month+20.day if period.present?
    #   @employee_schedules = EmployeeSchedule.where(:employee_id=> @record.id, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date asc")
    #   @attendences = AttendanceLog.where(:company_profile_id=> 1 , :employee_id=> @att_user.employee_id, :status=> 'active').where("date between ? and ?", period_begin-1.days, period_end).order("date_time asc") if @att_user.present?
      
    #   # if @record.present? 
    #   #   if @record.attributes.has_key? 'edit_lock_by' and @record.edit_lock_by != session[:id]
    #   #     @att_manual = ManualPresence.where(:sys_plant_id=> @selected_plant, :id_number=> @record.pin).where("date between ? and ?", period_begin, period_end).order("date_time asc").paginate(page: params[ :page], per_page: 10)
    #   #   else
    #   #     @att_manual = ManualPresence.where(:sys_plant_id=> @selected_plant, :id_number=> @record.pin).where("date between ? and ?", period_begin, period_end).order("date_time asc")
    #   #   end
    #   # end
    #   # get_checkinout('checkinout', period_begin, period_end, @att_user.id_number,'Today')
    # else
    #   flash[:info] = "Data not found"
    # end

  end

  # POST /employee_presences
  # POST /employee_presences.json
  def create
    # params[:employee_presence]["user_id"] = current_user.id
    # params[:employee_presence]["date"] = DateTime.current.to_date
    # params[:employee_presence]["created_at"] = DateTime.now()
    # params[:employee_presence]["status"] = "active"
    # case params[:kind]
    # when "Clock IN"
    #   params[:employee_presence]["kind"] = "in"
    #   params[:employee_presence]["clock_in"] = DateTime.now()
    # when "Clock Out"
    #   params[:employee_presence]["kind"] = "out"
    #   params[:employee_presence]["clock_out"] = DateTime.now()
    # end
    @employee_presence = EmployeePresence.find_by(:user_id=> current_user.id, :date=> DateTime.current.to_date)
    if @employee_presence.present?
      respond_to do |format|
        if @employee_presence.update(employee_presence_params)
          format.html { redirect_to @employee_presence, notice: 'EmployeePresence was successfully updated.' }
          format.json { render :show, status: :ok, location: @employee_presence }
        else
          format.html { render :edit }
          format.json { render json: @employee_presence.errors, status: :unprocessable_entity }
        end
      end
    else
      @employee_presence = EmployeePresence.new(employee_presence_params)

      respond_to do |format|
        if @employee_presence.save
          format.html { redirect_to @employee_presence, notice: 'EmployeePresence was successfully created.' }
          format.json { render :show, status: :created, location: @employee_presence }
        else
          format.html { render :new }
          format.json { render json: @employee_presence.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /employee_presences/1 
  # PATCH/PUT /employee_presences/1.json
  def update
    employee_id = params[:id]

    period_begin = "#{params[:periode_yyyy]}-#{params[:periode_mm]}-21".to_date
    period_end   = (period_begin+1.month).to_date.strftime("%Y-%m-20").to_date
    
    precompile_working_hour_summary = false
    att_employees = []
    params[:att].each do |key,value|
      if key[:id].present?

        check_att_log = AttendanceLog.find_by(:id=> key[:id])
        
        if check_att_log.present?
          if key[:remove].present?
            puts "remove"
            check_att_log.update_columns(:status=> "remove", :deleted_by=> current_user.id, :deleted_at=> DateTime.now())
            att_manual = ManualPresence.find_by(:company_profile_id=> current_user.company_profile_id, :id_number=> check_att_log.id_number, :date_time=> check_att_log.date_time, :type_presence=> key[:type_presence])
            if att_manual.present?
              att_manual.update_columns(:status=> 'remove')
            end
            att_employees << {:employee_id=> key[:employee_id]} unless att_employees.include?(:employee_id=> key[:employee_id])
            precompile_working_hour_summary = true
            # hk_without_schedule(@selected_plant, "#{params[:edit_select_period_yyyy]}#{params[:edit_select_period_yyyymm]}", nil, key[:hrd_employee_id]) if key[:hrd_employee_id].present?
          else
            if key.key?("period_shift") and check_att_log.date.to_date != key[:period_shift].to_date
              check_att_log.update_columns(:date=> key[:period_shift], :without_repair_period_shift=> 1)
              att_employees << {:employee_id=> key[:employee_id]} unless att_employees.include?(:employee_id=> key[:employee_id])
              precompile_working_hour_summary = true
              puts "perubahan periode #{check_att_log.date} != #{key[:period_shift]}"
            end
            if key[:type_presence].present? and check_att_log.type_presence != key[:type_presence]
              puts "#{check_att_log.type_presence} => #{key[:type_presence]}"
              case key[:type_presence]
              when 'in'
                mode_presence = 'ATt'
              else
                mode_presence = 'EXt'
              end
              check_att_log.update_columns(:type_presence=> key[:type_presence], :mode_presence=> mode_presence, :without_repair_period_shift=> 1)
              att_employees << {:employee_id=> key[:employee_id]} unless att_employees.include?(:employee_id=> key[:employee_id])
              precompile_working_hour_summary = true
            end
          end

        end
      end
    end if params[:att].present?

    params[:new_att].each do |key,value|
      puts key
      if key[:date].present? and key[:time].present? and key[:period_shift].present? and key[:type_presence].present? and key[:employee_id].present?
        puts "[#{key[:id_number]}] #{key[:date]} #{key[:time]}:59"
        check_att_log = AttendanceLog.find_by(:company_profile_id=> current_user.company_profile_id, :employee_id=> key[:employee_id], :date_time=> "#{key[:date]} #{key[:time]}:59".to_datetime)
        if check_att_log.blank?
          case key[:type_presence]
          when 'in'
            mode_presence = 'atT'
            tr_time = "#{key[:time]}:00"
          else
            mode_presence = 'exT'
            tr_time = "#{key[:time]}:59"
          end     
          att_manual = ManualPresence.find_by(
            :company_profile_id=> current_user.company_profile_id, 
            :id_number=> key[:id_number], 
            :date_time=> "#{key[:date]} #{tr_time}",
            :type_presence=> key[:type_presence])
          if att_manual.blank?
            ManualPresence.create(
              :company_profile_id=> current_user.company_profile_id, 
              :date => key[:period_shift],
              :time => tr_time,
              :date_time=> "#{key[:date]} #{tr_time}", 
              :type_presence=> key[:type_presence],
              :pin=> key[:id_number], :id_number=> key[:id_number], 
              :status=> 'approved',
              :created_by=> current_user.id, :created_at=> DateTime.now(),
              :approved_by=> current_user.id, :approved_at=> DateTime.now()
              )
            # untuk perbaikan presensi tanpa persetujuan ke pak johnny, (report only)
            AttendanceLog.create({
              :possibly_wrong_push=> 0,
              :company_profile_id=> current_user.company_profile_id, 
              :employee_id=> key[:employee_id],
              :date => key[:period_shift],
              :time => tr_time,
              :date_time => "#{key[:date]} #{tr_time}",
              :id_number=> key[:id_number],
              :type_presence=> key[:type_presence], :mode_presence=> mode_presence,
              :status=> 'active',
              :note=> 'penambahan manual',
              :updated_at=> DateTime.now(),
              :updated_by=> session[:id]
            })
            att_employees << {:employee_id=> key[:employee_id]} unless att_employees.include?(:employee_id=> key[:employee_id])
            precompile_working_hour_summary = true
          end
        end
        puts "#{key[:date]} #{tr_time}".to_datetime
      end
    end if params[:new_att].present?

    if params[:att_manual].present?
      att_manual_period_id = []
      params[:att_manual].each do |key,value|
        att_manual = ManualPresence.find_by(:id=> key[:id])
        if att_manual.present? 
          att_user = AttendanceUser.find_by(:company_profile_id=> att_manual.company_profile_id, :id_number=> key[:id_number])
          employee_id = att_user.employee_id
          if employee_id.present?     
            case key[:type_presence]
            when 'in'
              mode_presence = 'aTt'
            else
              mode_presence = 'eXt'
            end     

            case att_manual.status
            when 'new','cancel_approve'
              if key[:approved].to_i == 1
                att_manual.update_columns({
                  :status=> 'approved',
                  :approved_at=> DateTime.now(),
                  :approved_by=> session[:id],
                  :cancel_approved_at=> nil,
                  :cancel_approved_by=> nil
                })

                att = AttendanceLog.find_by(:company_profile_id=> current_user.company_profile_id, :date=> key[:date], :employee_id=> employee_id, :type_presence=> key[:type_presence])
                att_date = key[:date]
                att_time = key[:time]
                att_date_time =  key[:date_time]
                # att_date_time = "#{att_date} #{att_time}"
                if att.present? and att.status == 'suspend'
                  att.update_columns({                      
                    :possibly_wrong_push=> 0,
                    :employee_id=> employee_id,
                    :time => att_time,
                    :date_time => att_date_time,
                    :mode_presence=> mode_presence,
                    :status=> 'active',
                    :note=> 'perubahan manual',
                    :updated_at=> DateTime.now(),
                    :updated_by=> current_user.id
                  })
                else                        
                  AttendanceLog.create({
                    :possibly_wrong_push=> 0,
                    :company_profile_id=> current_user.company_profile_id, 
                    :employee_id=> employee_id,
                    :date => att_date,
                    :time => att_time,
                    :date_time => att_date_time,
                    :id_number=> key[:id_number],
                    :type_presence=> key[:type_presence], :mode_presence=> mode_presence,
                    :status=> 'active',
                    :note=> 'penambahan manual',
                    :updated_at=> DateTime.now(),
                    :updated_by=> current_user.id
                  })
                end
                att_employees << {:employee_id=> employee_id} unless att_employees.include?(:employee_id=> employee_id)
                flash[:notice]= "Approved Successfull"
              end
            when 'approved'
              if key[:approved].blank? or key[:approved].to_i == 0
                att_manual.update_columns({
                  :status=> 'cancel_approve',
                  :cancel_approved_at=> DateTime.now(),
                  :cancel_approved_by=> session[:id],
                  :approved_at=> nil,
                  :approved_by=> nil
                })


                att = AttendanceLog.find_by(:company_profile_id=> current_user.company_profile_id, :date=> key[:date], :employee_id=> employee_id, :type_presence=> key[:type_presence])
                att_date = key[:date]
                att_time = key[:time]
                att_date_time =  key[:date_time]
                # att_date_time = "#{att_date} #{att_time}"
                if att.present? and att.status == 'active'
                  att.update_columns({
                    :status=> 'suspend',
                    :note=> 'manual update',
                    :updated_at=> DateTime.now(),
                    :updated_by=> session[:id]
                  })
                end
                att_employees << {:employee_id=> employee_id} unless att_employees.include?(:employee_id=> employee_id)
                flash[:notice]= "Cancel Approved Successfull"
              else
                if key[:approved].to_i == 1
                  # update kolom date_time
                  att = AttendanceLog.find_by(:company_profile_id=> current_user.company_profile_id, :date=> key[:date], :employee_id=> employee_id, :type_presence=> key[:type_presence], :status=> 'suspend')
                  att_date = key[:date]
                  att_time = key[:time]
                  att_date_time =  key[:date_time]
                  # att_date_time = "#{att_date} #{att_time}"
                  if att.present?
                    att.update_columns({
                      :time => att_time,
                      :date_time => att_date_time,
                      :mode_presence=> mode_presence,
                      :status=> 'active',
                      :note=> 'perubahan manual',
                      :updated_at=> DateTime.now(),
                      :updated_by=> session[:id]
                    })
                  end
                  flash[:notice]= "Approved Successfull"
                end
              end
            end
          end
          att_manual_period_id << {:id=> att_manual.manual_presence_period_id} unless att_manual_period_id.include?(:id=> att_manual.manual_presence_period_id)
        else
          puts "tidak ada"
          # puts "#{key[:id]} => approve: #{ key[:approved]}"
        end
      end
      att_manual_period_id.each do |x|
        period = ManualPresencePeriod.find_by(:id=> x[:id])
        # period.update_columns(:edit_lock_by=> nil, :edit_lock_at=> nil) if period.present?
      end
    end

    # perbaikan schedule without hk
    params[:new_att2].each do |key,value|
      if key[:use].to_i == 1
        check_att_in = AttendanceLog.find_by(:company_profile_id=> current_user.company_profile_id, 
          :employee_id=> key[:employee_id], 
          :date_time=> "#{key[:date_in]} #{key[:time_in]}", 
          :type_presence=> 'in')
        att_in_manual = ManualPresence.find_by(:company_profile_id=> current_user.company_profile_id, :id_number=> key[:id_number], :date_time=> "#{key[:date_in]} #{key[:time_in]}", :type_presence=> 'in')
        if att_in_manual.blank?
          ManualPresence.create(
            :company_profile_id=> current_user.company_profile_id, 
            :date => key[:date_in],
            :time => "#{key[:time_in]}",
            :date_time=> "#{key[:date_in]} #{key[:time_in]}", 
            :type_presence=> 'in',
            :pin=> key[:id_number], :id_number=> key[:id_number], 
            :status=> 'approved',
            :created_by=> current_user.id, :created_at=> DateTime.now(),
            :approved_by=> current_user.id, :approved_at=> DateTime.now()
            )
        end

        if check_att_in.present?
          check_att_in.update_columns(:status=> 'active')
        else      
          puts ":date => #{key[:date_in]}"  
          puts ":time => #{key[:time_in]}"  
          puts ":date_time => #{key[:date_in]} #{key[:time_in]}"  
          puts "IN"

          AttendanceLog.create({
            :possibly_wrong_push=> 0,
            :company_profile_id=> current_user.company_profile_id, 
            :employee_id=> key[:employee_id],
            :date => key[:date_in],
            :time => key[:time_in],
            :date_time => "#{key[:date_in]} #{key[:time_in]}",
            :id_number=> key[:id_number],
            :type_presence=> 'in', :mode_presence=> 'atT',
            :status=> 'active',
            :note=> 'penambahan manual',
            :updated_at=> DateTime.now(),
            :updated_by=> current_user.id
          })
        end

        check_att_out = AttendanceLog.find_by(:company_profile_id=> current_user.company_profile_id, :employee_id=> key[:employee_id], :date_time=> "#{key[:date_out]} #{key[:time_out]}", :type_presence=> 'out')
        att_out_manual = ManualPresence.find_by(:company_profile_id=> current_user.company_profile_id, :id_number=> key[:id_number], :date_time=> "#{key[:date_out]} #{key[:time_out]}", :type_presence=> 'out')

        if att_out_manual.blank?
          ManualPresence.create(
            :company_profile_id=> current_user.company_profile_id, 
            :date => key[:period_shift],
            :time => "#{key[:time_out]}",
            :date_time=> "#{key[:date_out]} #{key[:time_out]}", 
            :type_presence=> 'out',
            :pin=> key[:id_number], :id_number=> key[:id_number], 
            :status=> 'approved',
            :created_by=> session[:id], :created_at=> DateTime.now(),
            :approved_by=> session[:id], :approved_at=> DateTime.now()
            )
        end

        if check_att_out.present?
          check_att_out.update_columns(:status=> 'active')
        else      
          puts ":date => #{key[:period_shift]}" 
          puts ":time => #{key[:time_out]}" 
          puts ":date_time => #{key[:date_out]} #{key[:time_out]}"  
          puts "OUT"    
          AttendanceLog.create({
            :possibly_wrong_push=> 0,
            :company_profile_id=> current_user.company_profile_id, 
            :employee_id=> key[:employee_id],
            :date => key[:period_shift],
            :time => key[:time_out],
            :date_time => "#{key[:date_out]} #{key[:time_out]}",
            :id_number=> key[:id_number],
            :type_presence=> 'out', :mode_presence=> 'exT',
            :status=> 'active',
            :note=> 'penambahan manual',
            :updated_at=> DateTime.now(),
            :updated_by=> session[:id]
          })
        end

        att_employees << {:employee_id=> key[:employee_id]} unless att_employees.include?(:employee_id=> key[:employee_id])
        precompile_working_hour_summary = true
      end
    end if params[:new_att2].present?
    
    if precompile_working_hour_summary
      if params[:id].present?
        # update by person
        # summary_working_hour(@selected_plant, params[:id], period_begin, period_end)

        AttendanceUser.where(:company_profile_id=> current_user.company_profile_id, :employee_id=> params[:id], :status=> 'active').each do |att_user|
          update_report(current_user.company_profile_id.to_i, params[:period], att_user.id_number)
        end
      else
        att_employees.each do |att|
          # summary_working_hour(@selected_plant, att[:hrd_employee_id], period_begin, period_end)

          AttendanceUser.where(:company_profile_id=> current_user.company_profile_id, :employee_id=> att[:employee_id], :status=> 'active').each do |att_user|
            update_report(current_user.company_profile_id.to_i, params[:period], att_user.id_number)
          end
        end if att_employees.present?
      end
    end

    # respond_to do |format|
    #   format.html { redirect_to , notice: 'Employee Presence was successfully updated.' }
    #   format.json { render :edit, status: :ok, location: @employee_presence }
    # end


    # respond_to do |format|
    #   case params[:kind]
    #   when "Clock IN"
    #     params[:employee_presence]["kind"] = "in"
    #     params[:employee_presence]["clock_in"] = DateTime.now()
    #   when "Clock Out"
    #     params[:employee_presence]["kind"] = "out"
    #     params[:employee_presence]["clock_out"] = DateTime.now()
    #   end
    #   if @employee_presence.update(employee_presence_params)
    #     format.html { redirect_to @employee_presence, notice: 'EmployeePresence was successfully updated.' }
    #     format.json { render :show, status: :ok, location: @employee_presence }
    #   else
    #     format.html { render :edit }
    #     format.json { render json: @employee_presence.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # def approve
    #   if params[:multi_id].present?
    #     if @employee_absence.present?
    #       @employee_absence.each do |abs|
    #         employee_absence = EmployeeAbsence.find_by(:id=>abs.id)
    #         case params[:status]
    #         when 'approve1'
    #           employee_absence.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()})
    #           notif_by_hierarchy(abs.employee.department_id, 'approved1', abs.id) 
    #         when 'approve2'
    #           employee_absence.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()})
    #           notif_by_hierarchy(abs.employee.department_id, 'approved2', abs.id) 
    #         when 'approve3'
    #           approve3_absence(abs)
    #           notif_by_hierarchy(abs.employee.department_id, 'approved3', abs.id)
    #         end
    #         update_absence_same_nik(abs.employee.nik, DateTime.now())
    #       end
    #     end
    #   else
    #     case params[:status]
    #     when 'approve1'
    #       @employee_absence.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    #     when 'cancel_approve1'
    #       @employee_absence.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    #     when 'approve2'
    #       if @employee_absence.created_by.to_i == current_user.id.to_i and DepartmentHierarchy.find_by(:approved2_by=> current_user.id, :department_id=> @employee_absence.employee.department_id).present?
    #         flash[:error] = "Pembuat Tidak Boleh Approval2"
    #       else
    #         @employee_absence.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    #       end
    #     when 'cancel_approve2'
    #       if @employee_absence.created_by.to_i == current_user.id.to_i and DepartmentHierarchy.find_by(:cancel2_by=> current_user.id, :department_id=> @employee_absence.employee.department_id).present?
    #         flash[:error] = "Pembuat Tidak Boleh Cancel Approval2"
    #       else
    #         @employee_absence.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()}) 
    #       end
    #     when 'approve3'
    #       approve3_absence(@employee_absence)
    #     when 'cancel_approve3'
    #       leave = EmployeeLeave.find_by(:period=> @employee_absence.begin_date.to_date.strftime("%Y"), :employee_id=> @employee_absence.employee_id, :status=> 'active')
    #       absence_types = EmployeeAbsenceType.find_by(:id=> @employee_absence.employee_absence_type_id, :special=> nil)

    #       if absence_types.present?
    #         puts "Ijin spesial"
    #         if leave.present? 
    #           leave.update(
    #             :day=> (leave.day.to_i - @employee_absence.day.to_i),
    #             :outstanding=> (leave.outstanding + @employee_absence.day.to_i) 
    #           ) 
    #           puts "update cuti"
    #         end
    #       end
    #       @employee_absence.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
    #     when 'void'
    #       @employee_absence.update({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()}) 
    #     when 'cancel_void'
    #       check = EmployeeAbsence.find_by(
    #         :employee_id=> @employee_absence.id,
    #         :begin_date=> @employee_absence.begin_date,
    #         :end_date=> @employee_absence.end_date
    #       )
    #       if check.present?
    #         flash[:error] = "Absence document date between #{check.begin_date} until #{check.end_date} date have been created before with notes : #{check.employee_absence_type.name}, Check it please!"
    #       else
    #         @employee_absence.update({:status=> 'new', :canceled1_by=> nil, :canceled1_at=> nil}) 
    #       end
    #     when 'approve'
    #       flash[:error] = "No record has been approved "
    #     end
    #     notif_by_hierarchy(@employee_absence.employee.department_id, params[:status], @employee_absence.id)
    #   end
    #   respond_to do |format|
    #     if flash[:error].blank?
    #       if params[:multi_id].present?
    #         format.html { redirect_to employee_absences_url, notice: "Employee absence was successfully #{params[:status]}." }
    #       else
    #         format.html { redirect_to employee_absence_path(:id=> @employee_absence.id), notice: "Employee absence was successfully #{@employee_absence.status}." }
    #       end
    #       format.json { head :no_content }
    #     else
    #       format.html { redirect_to (params[:multi_id].present? ? employee_absences_url : employee_absence_path(:id=> @employee_absence.id)), alert: flash[:error] }
    #       format.json { render json: @employee_absence.errors, status: :unprocessable_entity }
    #     end
    #   end
  # end

  def export
    template_report(controller_name, params[:employee_id], params[:department_id])
  end

  # DELETE /employee_presences/1
  # DELETE /employee_presences/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to employee_presences_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_working_hour_summary
      if params[:id]=='export'
        id = params[:employee_id]
      else
        id = params[:id]
      end
      employee_presence = EmployeePresence.where(:period=>params[:period]).group('employee_id')
      @employee_presence = employee_presence.find_by(:employee_id=>params[:id])
    end

    def set_instance_variable
      @departments = Department.where(:status=>'active').order("name asc")
      @employees = Employee.where(:company_profile_id=> current_user.company_profile_id, :employee_status=>'Aktif')
      @attendance_users = AttendanceUser.where(:status=> 'active')
      params[:period] = (params[:period].blank? ? nil  : params[:period] )
      date = Date.parse("2016-12-31")
      stop = Date.today.beginning_of_month+1.months 
      @periods = Array.new()
      while (date <= stop)
        date = date.advance(months: 1)
        @periods.push(date.strftime("%Y%m") )
      end

      period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      period_begin = period.to_date+20.day if period.present?
      period_end = period.to_date+1.month+19.day if period.present?
      @period_begin =  period.to_date+20.day if period.present?
      @period_end = period.to_date+1.month+19.day if period.present?

      # @department_selected = (params[:department_id].present? ? params[:department_id] : session[:department_id])
      # @department_selected = (params[:department_id] == "" ? nil : @department_selected)

      # @employees = @employees.where(:department_id=> @department_selected) if @department_selected.present?
      # @employees = @employees.where(:id=> params[:employee_id]) if params[:employee_id].present?
    end

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
      return "#{result} #{periode.to_s.first(4)}"
    end

    def edit_working_hour_data(plant_param, period_param, id_param, period_begin, period_end)
      @att_users = AttendanceUser.where(:company_profile_id=> plant_param, :status=> 'active')
      @employees = Employee.where(:company_profile_id=> current_user.company_profile_id, :employee_status=>'Aktif')
      # @employees = Employee.where(:company_profile_id=> plant_param, :id=> @att_users.map { |e| [e.employee_id] }).includes([:department, :position]) 
      @record = Employee.find_by(:id=> id_param)
      @att_user = @att_users.find_by(:employee_id=> @record.id)

      @holiday = HolidayDate.where(:status=> 'active')
      @employee_absences = EmployeeAbsence.where(:employee_id=> @record.id).where("begin_date >= ? and end_date <= ?", period_begin, period_end)

      @working_hour_summary = WorkingHourSummary.find_by(:employee_id=> @record.id, :period_begin=> period_begin, :period_end=> period_end, :status=> 'active')
      if @working_hour_summary.present?
        @working_hour_summary_items = WorkingHourSummaryItem.where(:working_hour_summary_id=> @working_hour_summary.id, :status=> 'active' ).order("date asc")
        .includes(:schedule)
      end
      @employee_overtimes = EmployeeOvertime.where(:employee_id=> @record.id, :status=> 'app3').where("date between ? and ?", period_begin, period_end).order("date asc")
    end

    def employee_presence_report(plant, period, dept_id, kind_tbl)    
      period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      period_begin = period.to_date+20.day if period.present?
      period_end = period.to_date+1.month+19.day if period.present?

      # work_status = HrdWorkStatus.where(:payroll=> 1, :status=> 'active')
      # employees = HrdEmployee.where(:hrd_employee_payroll_id=> @selected_plant).where(:hrd_work_status_id=> work_status.select(:id))
      # 2020-05-20: 
      employees = Employee.where(:company_profile_id=> plant)
      employees = employees.where(:department_id=> dept_id) if dept_id.present?
      attendance_users = AttendanceUser.where(:employee_id=> employees.select(:id), :company_profile_id=> plant, :status=> 'active') if employees.present?
      attendance_logs = AttendanceLog.where(:company_profile_id=> plant, :employee_id=> attendance_users.select(:employee_id), :status=> 'active').where("date between ? and ?", period_begin, period_end) if attendance_users.present?
      
      sys_department = []
      Department.where(:status=> 'active').each do |dept|
        sys_department << {
          :id=> dept.id,
          :name=> dept.name
        }
      end 
      employee = []
      employee_select = []
      attendance_users.each do |att_user|
        employee_select << att_user.employee_id
        employee << {
          :id=> att_user.employee_id,
          :name=> att_user.employee.name,
          :department_id=> att_user.department_id
        }
      end if attendance_users.present?
      # employees.each do |employee|
      #   hrd_employee << {
      #     :id=> employee.id,
      #     :name=> employee.name,
      #     :sys_department_id=> employee.sys_department_id
      #   }
      # end
      
      employees_lists = []
      EmployeePresence.where(:company_profile_id=> plant, :kind=> kind_tbl, :status=> 'active', :employee_id=> employee_select).where("date between ? and ?", period_begin, period_end).each do |a|
        employees_lists << a.employee_id unless employees_lists.include?(a.employee_id)
      end       

      employee_list = employees_lists.split(", ") if employees_lists.length > 0 
      case kind_tbl
      when 'possibly_wrong_push'                    
        att_array = []
        count = 0 

        attendance_logs.where(:possibly_wrong_push=> 1).order("id_number asc, date_time asc").each do |att|           
          employee_name = nil
          department_name = nil
          employee.each do |employee|
            if employee[:id].to_i == att.employee_id.to_i
              employee_name = employee[:name]
              sys_department.each do |dept|
                if employee[:department_id].to_i == dept[:id].to_i
                  department_name = dept[:name]
                end
              end
            end
          end
          att_array << {
              :id=> att.id,
              :employee_id => att.employee_id, 
              :employee_name => employee_name, 
              :department_name => department_name,
              :id_number=> att.id_number,
              :period_shift=> att.date.to_date.strftime("%Y-%m-%d"),
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
        wrong_mode_count = 0
        wrong_mode_id_number = []
        (0..count).each do |c|
          if att_array[c+1].present? and att_array[c+1][:id_number] == att_array[c][:id_number]
          
            if att_array[c][:type_presence] == att_array[c+1][:type_presence]
              att_array[c][:wrong_mode] = true
              att_array[c+1][:wrong_mode] = true
              
              wrong_mode_count += 1 unless wrong_mode_id_number.include?(att_array[c][:id_number])
              wrong_mode_id_number << att_array[c][:id_number] unless wrong_mode_id_number.include?(att_array[c][:id_number])
            end
          end
        end
        puts wrong_mode_count
      when 'working_hour_over_20h','working_hour_under_2h' 
        att_array = []
        att_out_without_in = 0
        att_out_without_in_employee_id = []
        EmployeePresence.where(:company_profile_id=> plant, :kind=> kind_tbl, :status=> 'active', :employee_id=> employee_list).where("date between ? and ?", period_begin, period_end).order("employee_id asc, date asc").each do |att|
          puts "#{att.date} #{att.employee_id}"
          employee_schedule = EmployeeSchedule.find_by(:company_profile_id=> plant, :employee_id=> att.employee_id, :date=> att.date, :status=> 'active')
          if employee_schedule.present?
            schedule = employee_schedule.schedule
            schedule_time_in = (schedule["#{att.date.strftime("%A").downcase}_in"].present? ? schedule["#{att.date.strftime("%A").downcase}_in"].strftime("%H:%M:%S") : nil)
            schedule_time_out = (schedule["#{att.date.strftime("%A").downcase}_out"].present? ? schedule["#{att.date.strftime("%A").downcase}_out"].strftime("%H:%M:%S") : nil)
          end
          att_log_in = AttendanceLog.find_by(:company_profile_id=> plant, :employee_id=> att.employee_id, :status=> 'active', :date=> att.date, :type_presence=> 'in')
          att_log_date_time_in  = (att_log_in.present? ? att_log_in.date_time.strftime("%Y-%m-%d %H:%M:%S") : nil)
          att_log_out = AttendanceLog.find_by(:company_profile_id=> plant, :employee_id=> att.employee_id, :status=> 'active', :date=> att.date, :type_presence=> 'out')
          att_log_date_time_out  = (att_log_out.present? ? att_log_out.date_time.strftime("%Y-%m-%d %H:%M:%S") : nil)
          if att_log_date_time_in.present? and att_log_date_time_out.present?
            working_hour = TimeDifference.between(att_log_date_time_in, att_log_date_time_out).in_hours
          else
            working_hour = 0
          end
            att_array << {
              :id=> att.id,
              :employee_id => att.employee_id, 
              :employee_name => "#{att.employee.name if att.employee.present?}", 
              :department_name => "#{att.employee.department.name if att.employee.present? and att.employee.department.present?}",
              :id_number=> att.id_number,
              :period_shift=> att.date,
              :att_date_time_in=> att_log_date_time_in,
              :att_date_time_out=> att_log_date_time_out,
              :working_hour=> working_hour,
              :schedule_code=>(schedule.code if schedule.present?),
              :schedule_time_in=> schedule_time_in,
              :schedule_time_out=> schedule_time_out
            }
        end
      when 'duplicate_in', 'duplicate_out','hk_without_schedule'    
        attendance_logs = attendance_logs.where(:employee_id=> employee_list).order("id_number asc, date_time asc")
        if employee_list.present?
          att_array = []
          count = 0
          attendance_logs.each do |att|
            att_array << {
              :id=> att.id,
              :employee_id => att.employee_id, 
              :employee_name => "#{att.employee.name if att.employee.present?}", 
              :department_name => "#{att.employee.department.name if att.employee.present? and att.employee.department.present?}",
              :id_number=> att.id_number,
              :period_shift=> att.date.to_date.strftime("%Y-%m-%d"),
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

          wrong_mode_count = 0
          att_out_without_in_id_number = []

          (0..count).each do |c|
            case kind_tbl
            when 'duplicate_in','duplicate_out'
              if att_array[c+1].present? and att_array[c+1][:id_number] == att_array[c][:id_number] and att_array[c][:type_presence] == kind_tbl.gsub("duplicate_","")
                if att_array[c][:type_presence] == att_array[c+1][:type_presence]
                  att_array[c-2][:possibly_trouble] = true if att_array[c-2].present?
                  att_array[c-1][:possibly_trouble] = true if att_array[c-1].present?
                  att_array[c][:possibly_trouble] = true
                  att_array[c+1][:possibly_trouble] = true if att_array[c+1].present?
                  att_array[c+2][:possibly_trouble] = true if att_array[c+2].present?

                  att_array[c][:wrong_mode] = true
                  att_array[c+1][:wrong_mode] = true
                  wrong_mode_count += 1 unless att_out_without_in_id_number.include?(att_array[c][:id_number])
                  att_out_without_in_id_number << att_array[c][:id_number] unless att_out_without_in_id_number.include?(att_array[c][:id_number])
                     
                end

                #  1 hari double in dan out
                if att_array[c].present? and att_array[c+1].present? and att_array[c+2].present? and att_array[c+3].present?
                  if att_array[c+1][:id_number] == att_array[c][:id_number] and att_array[c+1][:id_number] == att_array[c+2][:id_number] and att_array[c+2][:id_number] == att_array[c+3][:id_number]
                    if att_array[c+1][:period_shift] == att_array[c][:period_shift] and att_array[c+1][:period_shift] == att_array[c+2][:period_shift] and att_array[c+2][:period_shift] == att_array[c+3][:period_shift]
                      att_array[c-2][:possibly_trouble] = true if att_array[c-2].present?
                      att_array[c-1][:possibly_trouble] = true if att_array[c-1].present?
                      att_array[c][:possibly_trouble] = true
                      att_array[c+1][:possibly_trouble] = true if att_array[c+1].present?
                      att_array[c+2][:possibly_trouble] = true if att_array[c+2].present?
                      att_array[c+3][:possibly_trouble] = true if att_array[c+3].present?
                      att_array[c+4][:possibly_trouble] = true if att_array[c+4].present?
                      att_array[c+5][:possibly_trouble] = true if att_array[c+5].present?


                      att_array[c][:wrong_mode] = true
                      att_array[c+1][:wrong_mode] = true if att_array[c+1].present?
                      att_array[c+2][:wrong_mode] = true if att_array[c+2].present?
                      att_array[c+3][:wrong_mode] = true if att_array[c+3].present?
                      
                      wrong_mode_count += 1 unless att_out_without_in_id_number.include?(att_array[c][:id_number])
                      att_out_without_in_id_number << att_array[c][:id_number] unless att_out_without_in_id_number.include?(att_array[c][:id_number])
                    end
                  end
                end
              end

            when 'hk_without_schedule'
              att_array[c][:possibly_trouble] = true if att_array[c].present?
            end
          end
          puts wrong_mode_count
        end

        att_array = att_array.select{ |item| item[:possibly_trouble] == true } if att_array.present?                
      when 'schedule_without_hk'    
        att_array = []
        EmployeePresence.where(:company_profile_id=> plant, :kind=> kind_tbl, :status=> 'active', :employee_id=> employee_list).where("date between ? and ?", period_begin, period_end).each do |att|
          # legal_id  = att.hrd_employee.hrd_employee_legal_id
          # schedule_employee = HrdEmployeeSchedule.find_by(:sys_plant_id=> legal_id, :hrd_employee_id=> att.hrd_employee_id, :date=> att.date)
          # hrd_employee_payroll_id = att.hrd_employee.hrd_employee_payroll_id
          schedule_employee = EmployeeSchedule.find_by(:company_profile_id=> plant, :employee_id=> att.employee_id, :date=> att.date, :status=> 'active')
          schedule_att_in   = (schedule_employee.present? ? (schedule_employee.schedule.present? ? schedule_employee.schedule["#{att.date.strftime("%A").downcase}_in"] : nil) : nil)
          schedule_att_out  = (schedule_employee.present? ? (schedule_employee.schedule.present? ? schedule_employee.schedule["#{att.date.strftime("%A").downcase}_out"] : nil) : nil)
          schedule_att_time_in = (schedule_att_in.present? ? schedule_att_in.strftime("%H:%M:%S") : nil)
          schedule_att_time_out = (schedule_att_out.present? ? schedule_att_out.strftime("%H:%M:%S") : nil)
          if schedule_att_time_in.present? and schedule_att_time_out.present?
            schedule_att_date_out = (schedule_att_time_in > schedule_att_time_out ? att.date+1.days : att.date)
          else
            schedule_att_date_out = att.date
          end

          att_array << {
            :id=> att.id,
            :employee_id => att.employee_id, 
            :employee_name => "#{att.employee.name if att.employee.present?}", 
            :department_name => "#{att.employee.epartment.name if att.employee.present? and att.employee.department.present?}",
            :id_number=> att.id_number,
            :period_shift=> att.date, 
            :schedule_att_date_in=>  att.date,
            :schedule_att_date_out=> schedule_att_date_out,
            :schedule_att_time_in=> schedule_att_time_in,
            :schedule_att_time_out=> schedule_att_time_out
          }
        end
      when 'att_in_without_out','att_out_without_in'      
        att_array = []
        att_out_without_in = 0
        att_out_without_in_employee_id = []
        wrong_mode_count = 0
        wrong_mode_id_number = []
        attendence_log = []
        attendance_logs.order("date_time asc").each do |att_log|
        # HrdAttendanceLog.where(:sys_plant_id=> @selected_plant, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date_time asc").each do |att_log|
          # attendence_log << att_log.as_json
          attendence_log << {
            :id=> att_log.id, 
            # :sys_plant_id=> att_log.sys_plant_id, 
            :employee_id=> att_log.employee_id, 
            :date=> att_log.date.to_date.strftime("%Y-%m-%d"), 
            :time=> att_log.time.to_datetime.strftime("%H:%M:%S"), 
            :date_time=> att_log.date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S"),
            :mode_presence=> att_log.mode_presence,
            :type_presence=> att_log.type_presence,
            :possibly_wrong_push=> att_log.possibly_wrong_push,
            :status=> att_log.status
          }
        end
        manual_presence = []
        ManualPresence.where(:company_profile_id=> plant, :status=> 'active').where("date between ? and ?", period_begin, period_end).order("date_time asc").each do |att_manual|
          manual_presence << {
            :id=> att_manual.id, 
            :id_number=> att_manual.id_number,
            :date=> att_manual.date.to_date.strftime("%Y-%m-%d"), 
            :date_time=> att_manual.date_time.to_datetime.strftime("%Y-%m-%d %H:%M:%S"),
            :type_presence=> att_manual.type_presence
          }
        end

        EmployeePresence.where(:company_profile_id=> plant, :kind=> kind_tbl, :status=> 'active', :employee_id=> employee_list).where("date between ? and ?", period_begin, period_end).each do |att|
          # puts "#{att.date} #{att.hrd_employee_id}"
          att_out_without_in += 1 unless att_out_without_in_employee_id.include?(att.employee_id)
          att_out_without_in_employee_id << att.employee_id unless att_out_without_in_employee_id.include?(att.employee_id)
          
          att_log_date_time_in = nil
          att_log_date_out = nil
          att_log_date_time_out = nil

          mode_presence_in = nil
          mode_presence_out = nil
          attendence_log.each do |att_array|
            if att_array[:employee_id].to_i == att.employee_id.to_i
              if att_array[:date].to_date == att.date.to_date
                case att_array[:type_presence]
                when 'in'
                  att_log_date_time_in = att_array[:date_time].to_datetime.strftime("%H:%M:%S")
                  mode_presence_in     = att_array[:mode_presence]
                when 'out'
                  att_log_date_out      = att_array[:date_time].to_datetime.strftime("%Y-%m-%d")
                  att_log_date_time_out = att_array[:date_time].to_datetime.strftime("%H:%M:%S")
                  mode_presence_out      = att_array[:mode_presence]
                end
              end
            end
          end

          att_manual_status = nil
          att_manual_date_in  = nil
          att_manual_time_in  = nil
          att_manual_date_out = nil
          att_manual_time_out = nil
          manual_presence.each do |att_array|
            if att_array[:id_number].to_s == att.id_number.to_s
              if att_array[:date].to_date == att.date.to_date
                att_manual_status = att_array[:status]
                case att_array[:type_presence]
                when 'in'
                  att_manual_date_in  = att_array[:date_time].to_datetime.strftime("%Y-%m-%d")
                  att_manual_time_in  = att_array[:date_time].to_datetime.strftime("%H:%M:%S")
                when 'out'
                  att_manual_date_out  = att_array[:date_time].to_datetime.strftime("%Y-%m-%d")
                  att_manual_time_out  = att_array[:date_time].to_datetime.strftime("%H:%M:%S")
                end
              end
            end
          end
          employee_name = nil
          department_name = nil
          employee.each do |employee|
            if employee[:id].to_i == att.employee_id.to_i
              employee_name = employee[:name]
              sys_department.each do |dept|
                if employee[:department_id].to_i == dept[:id].to_i
                  department_name = dept[:name]
                end
              end
            end
          end


          # if (att_log_in.present? and att_log_out.blank?) or (att_log_in.blank? and att_log_out.present?)
            att_array << {
              :id=> att.id,
              :employee_id => att.employee_id, 
              :employee_name => employee_name, 
              # :employee_name => "#{att.hrd_employee.name if att.hrd_employee.present?}", 
              :department_name => department_name,
              # :department_name => "#{att.hrd_employee.sys_department.name if att.hrd_employee.present? and att.hrd_employee.sys_department.present?}",
              :id_number=> att.id_number,
              :period_shift=> att.date.to_date.strftime("%Y-%m-%d"),  
              :att_date_in=> att.date,
              :att_time_in=> att_log_date_time_in,
              :att_date_out=> att_log_date_out,
              :att_time_out=> att_log_date_time_out,
              :att_manual_status=> att_manual_status,
              :att_manual_date_in=> att_manual_date_in,
              :att_manual_time_in=> att_manual_time_in,
              :att_manual_date_out=> att_manual_date_out,
              :att_manual_time_out=> att_manual_time_out,
              :mode_presence_out=> mode_presence_out,
              :mode_presence_in=> mode_presence_in

            }

            wrong_mode_count += 1 unless wrong_mode_id_number.include?(att.id_number)
            wrong_mode_id_number << att.id_number unless wrong_mode_id_number.include?(att.id_number)
          # end
        end
        puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        puts wrong_mode_count
      end
      return att_array
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_presence_params
      params.require(:employee_presence).permit(:date, :clock_in, :clock_out, :coordinate_latitude, :coordinate_langitude, :user_id, :created_at, :status, :kind)
    end
end
