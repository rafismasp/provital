class EmployeeSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_schedule, only: [:show, :edit, :update]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  # before_action only: [:approve] do
  #   require_permission_approve(params[:status])
  # end

  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    # date = Date.parse("2016-12-31")
    # stop = Date.today.beginning_of_month+1.months 
    # @periods = Array.new()
    # while (date <= stop)
    #   date = date.advance(months: 1)
    #   @periods.push(date.strftime("%Y%m") )
    # end
    params[:period] = (params[:period].blank? ? (DateTime.now()-1.month).strftime("%Y%m")  : params[:period] )
    period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
    period_begin = period.to_date+20.day if period.present?
    period_end = period.to_date+1.month+19.day if period.present?
    # update_employee_presence(period_begin,period_end)
    @period_begin =  period.to_date+20.day if period.present?
    @period_end = period.to_date+1.month+19.day if period.present?

    @department_selected = (params[:department_id].present? ? params[:department_id] : current_user.department_id)
    @department_selected = (params[:department_id] == "" ? nil : @department_selected)

    @employees = @employees.where(:department_id=> @department_selected) if @department_selected.present?
    @employees = @employees.where(:id=> params[:employee_id]) if params[:employee_id].present?

    # employee_schedules = EmployeeSchedule.where(:company_profile_id=> current_user.company_profile_id).group('employee_id')
    # .includes(employee: [:department, :position])
    # .where("employees.employee_status = ?", 'Aktif').references(:employees)
    
    employee_schedules = EmployeeScheduleRecap.where(:company_profile_id=> current_user.company_profile_id, :periode=>params[:period])
    .includes(employee: [:department, :position])
    .where("employees.employee_status = ?", 'Aktif').references(:employees)

    employee_schedules = employee_schedules.where("employees.department_id = ?", @department_selected).references(:employees) if @department_selected.present?
    employee_schedules = employee_schedules.where("employees.id = ?", params[:employee_id]) if params[:employee_id].present?

    if params[:partial]=='change_employee' && params[:view_kind]==""
      @employee = Employee.find_by(:id=> params[:employee_id])

      schedule_items(params[:id], params[:employee_id], params[:period])
    end    

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @employee_schedules = pagy(employee_schedules, page: params[:page], items: pagy_items)

    #------------------------------------------------------------------------------
  end

  def show
  end

  def new
    @employee_schedule = EmployeeSchedule.new
  end

  def edit    
  end

  def create
    # params[:employee_schedule]["created_by"] = current_user.id
    # params[:employee_schedule]["created_at"] = DateTime.now()
    # @employee_schedule = EmployeeSchedule.new(employee_schedule_params) 

    if params[:file].present?  
      content =  params[:file][:attachment].tempfile
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet.open(content.to_path.to_s)

      #Sheet1
      sheet1 = book.worksheet 'schedule kerja'
      working_hour_summary_disabled = []

      c=6
      periode = sheet1.row(2)[2].to_s.split('.')[0] #hasil import periode nya , cth : 202201

      sheet1.each do |re| #looping Sheet1
        row  = sheet1.row(c)
        nik = row[1]
        # puts row1[4]
        if row[0].present? and row[0].to_i >= 1 #check no urut
          employees   = Employee.where(:nik=> nik)
          employees.each do |employee|
            puts employee.name
            (5..35).each do |column|
            # (0..3).each do |column|
              if row[column].present? and row[column] != nil
                # begin
                  date = sheet1.row(4)
                  day = date[column][0,2]
                  month = date[column][3,2]
                  # jika yg diupload periode 202212 => desember, dan hasil looping masuk ke januari, maka tahunnya +1
                  if periode[4,2].to_s == '12' and month.to_s == '01'
                    period = "#{periode[0,4].to_i+1}-#{month}-#{day}"
                  else
                    period = "#{periode[0,4]}-#{month}-#{day}"
                  end
                  period_begin = "#{periode[0,4]}-#{periode[4,2]}-21"
                  period_end = (period_begin.to_date+1.months).strftime("%Y-%m-20")
                  # nik.value
                  # puts "#{period[0,4]}-#{month}-#{day}" #input date nya

                  # sched_column = sheet1.row(c)
                  # schedule_code = sched_column[column] #untuk looping data schedule sesuai tanggal
                  schedule_code = "#{row[column].to_s.split('.')[0]}"
                  # puts row[column].to_s.split('.')[0]
                  schedule = Schedule.find_by(:code=> schedule_code, :company_profile_id=> employee.company_profile_id ).id 
                  # puts schedule.code

                  check = EmployeeSchedule.find_by(:company_profile_id=> employee.company_profile_id, :employee_id=>employee.id, :date=>period, :status=> 'active')
                  if check.present? 
                    if schedule.present?
                      if schedule.to_i != check.schedule_id.to_i
                        check.update({:status=> 'suspend', :remarks=> 'perubahan schedule'})
                        puts "perubahan schedule"
                        employee_schedule = EmployeeSchedule.create({
                          :company_profile_id=> employee.company_profile_id,
                          :employee_id=>employee.id,
                          :schedule_id=>schedule,
                          :date=> period,
                          :status=> 'active' ,
                          :created_at=> DateTime.now,
                          :created_by=> current_user.id
                        })
                        employee_schedule.save!    

                      end
                    else
                      check.update({:status=> 'suspend', :remarks=> 'hapus schedule'})
                      working_hour_summary_disabled << {
                        :company_profile_id=> employee.company_profile_id, 
                        :period_begin=> period_begin, 
                        :period_end=> period_end, 
                        :employee_id=> employee.id
                      } unless working_hour_summary_disabled.include?({
                        :company_profile_id=> employee.company_profile_id, 
                        :period_begin=> period_begin, 
                        :period_end=> period_end, 
                        :employee_id=> employee.id
                      })
                    end
                  else
                    if schedule.present?
                      employee_schedule = EmployeeSchedule.new({
                        :company_profile_id=> employee.company_profile_id,
                        :employee_id=>employee.id,
                        :schedule_id=>schedule,
                        :date=> period,
                        :status=> 'active' ,
                        :created_at=> DateTime.now,
                        :created_by=> current_user.id
                      })
                      employee_schedule.save!  
                    end
                  end 


                # rescue StandardError => error 
                  # puts error
                # end
                column += 1
              end
            end
          end
          # puts '================='
        end
        c += 1
      end

      working_hour_summary_disabled.each do |array_record|
        puts array_record
        working_hour_summary  = WorkingHourSummary.find_by(
          :company_profile_id=> array_record[:company_profile_id], 
          :period_begin=> array_record[:period_begin], 
          :period_end=> array_record[:period_end], 
          :employee_id=> array_record[:employee_id])
        working_hour_summary.update_columns(:status=> 'disabled') if working_hour_summary.present?
      end
      flash[:info]="Upload Successfull"
    end
    respond_to do |format|
      format.html { redirect_to "/employee_schedules", notice: flash[:info] }
      format.json { head :no_content }
    end
  end

  def update
    params[:schedule]["company_profile_id"] = @schedule.company_profile_id
    params[:schedule]["updated_by"] = current_user.id
    params[:schedule]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @schedule.update(schedule_params)
        format.html { redirect_to @schedule, notice: 'Schedule was successfully updated.' }
        format.json { render :show, status: :created, location: @schedule }
      else
        puts @schedule.errors.full_messages
        format.html { render :edit }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, params[:period])
  end

  def upload
  end

  private
    def set_employee_schedule
      @employee_schedule = EmployeeSchedule.find_by(:employee_id=> params[:id])
      schedule_items(params[:id], nil, params[:period])
      # period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      # period_begin = period.to_date+20.day if period.present?
      # period_end = period.to_date+1.month+19.day if period.present?
      # @employee_schedule_items = EmployeeSchedule.where(:employee_id=> params[:id], :company_profile_id=> @employee_schedule.company_profile_id, :status=> 'active')
      #   .where("date between ? and ?", period_begin,period_end)
      #   .includes(:schedule)
      #   .order("date asc")
      # @attendance_user = AttendanceUser.find_by(:employee_id=>@employee_schedule.employee_id)
    end

    def set_instance_variable  
      @departments = Department.where(:status=>'active').order("name asc")
      @employees = Employee.where(:employee_status=>'Aktif')
      params[:period] = (params[:period].blank? ? (DateTime.now()-1.month).strftime("%Y%m")  : params[:period] )
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
      # update_employee_presence(period_begin,period_end)
      @period_begin =  period.to_date+20.day if period.present?
      @period_end = period.to_date+1.month+19.day if period.present?

      # @date   = period.present?  ? (params[:controller]+"_"+params[:tbl]).camelize.constantize.where(:status=>'active', :company_profile_id=> current_user.company_profile_id).where("date between ? and ?", period_begin,  period_end).group('date') : nil
      
      @department_selected = (params[:dept_id].present? ? params[:dept_id] : session[:department_id])
      @department_selected = (params[:dept_id] == "" ? nil : @department_selected)

      @employees = @employees.where(:department_id=> @department_selected) if @department_selected.present?
      @employees = @employees.where(:id=> params[:employee_id]) if params[:employee_id].present?
      # @absence_types = EmployeeAbsenceType.where(:status=> 'active').order('name asc')
      # @departments = Department.where(:status=>'active').order('name asc')

      # @employee_alls = Employee.where(:employee_status=>'Aktif').order("name asc")
      # @tahun        = (params[:tahun].blank? ? Time.now.year : params[:tahun]).to_s
      # period_begin  = "#{@tahun}0101".to_date.beginning_of_year()
      # period_end    = "#{@tahun}0101".to_date.end_of_year() 

      # if !params[:multi_id].present?
      #   absences              = EmployeeAbsence.where(:employee_id=> (params[:employee_id].present? ? params[:employee_id] : (@employee_absence.present? ? @employee_absence.employee_id : nil)), :status=> 'approved3').where("end_date between ? and ?", period_begin, period_end).includes(:employee_absence_type)
      #   @absences             = absences.where(:employee_absence_types => {:special=> nil}).order("begin_date asc")    
      #   @special_absences     = absences.where(:employee_absence_types => {:special=> 1}).order("begin_date asc")
      # end
    end

    def schedule_items(id, employee_id, periode)

      period = periode.present? ? (periode.to_s+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      period_begin = period.to_date+20.day if period.present?
      period_end = period.to_date+1.month+19.day if period.present?
      @employee_schedule_items = EmployeeSchedule.where(:employee_id=> (employee_id.present? ? employee_id : params[:id]), :status=> 'active')
        .where("date between ? and ?", period_begin,period_end)
        .includes(:schedule)
        .order("date asc")
      @attendance_user = AttendanceUser.find_by(:employee_id=>(employee_id.present? ? employee_id : @employee_schedule.employee_id))
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_schedule_params
      params.require(:employee_schedule).permit(
        :created_by, 
        :created_at
      )
    end
end
