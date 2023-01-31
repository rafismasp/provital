class EmployeeOvertimesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_overtime, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    # employee_overtimes = EmployeeOvertime.where("date between ? and ?", session[:date_begin], session[:date_end]).order("date desc")
    
    # filter select - begin
      # @option_filters = [['Doc.Status','status'],['Nama Karyawan','employee_id']] 
      # @option_filter_records = employee_absences

      # if params[:filter_column].present?
      #   case params[:filter_column] 
      #   when 'employee_id'
      #     @option_filter_records = Employee.where(:company_profile_id=> current_user.company_profile_id, :employee_status=> 'Aktif').order("name asc")
      #   end

      #  employee_overtimes = employee_overtimes.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      # end

    # filter select - end

    params[:year] = (params[:year].blank? ? DateTime.now().strftime("%Y")  : params[:year] )
    params[:month] = (params[:month].blank? ? (DateTime.now()-1.month).strftime("%m")  : params[:month] )

    # period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
    period = params[:month].present? ? (params[:year]+params[:month]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
    period_begin = period.to_date+20.day if period.present?
    period_end = period.to_date+1.month+19.day if period.present?
    # update_employee_presence(period_begin,period_end)
    # @period_begin =  period.to_date+20.day if period.present?
    # @period_end = period.to_date+1.month+19.day if period.present?

    @department_selected = (params[:department_id].present? ? params[:department_id] : current_user.department_id)
    @department_selected = (params[:department_id] == "" ? nil : @department_selected)

    @employees = @employees.where(:department_id=> @department_selected) if @department_selected.present?
    @employees = @employees.where(:id=> params[:employee_id]) if params[:employee_id].present?

    status = ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3']
    employee_overtimes = EmployeeOvertime.where(:company_profile_id=> current_user.company_profile_id, :status=>status).where("date between ? and ?", period_begin, period_end ).order("status asc")
        
    employee_overtimes = employee_overtimes.joins(:employee).where("employees.department_id = ?", @department_selected) if @department_selected.present?
    employee_overtimes = employee_overtimes.joins(:employee).where("employees.id = ?", params[:employee_id]) if params[:employee_id].present?


    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @employee_overtimes = pagy(employee_overtimes, page: params[:page], items: pagy_items)

    if params[:partial].present?
      if params[:partial] == "approve_all"
        period_yyyy = "#{params[:period].to_s[0..3]}"
        period_mmdd = "#{params[:period].to_s[4..5]}21"

        periode_begin = "#{period_yyyy}#{period_mmdd}".to_date
        periode_end   = (periode_begin+1.month).strftime("%Y-%m-20")
        puts "#{periode_begin} sd #{periode_end}"
        
        # @departments = @departments

        select_status = nil
        @check_permission = nil
        case params[:select_status]
        when 'approve1'
          select_status = ['new', 'canceled1']
          @check_permission = UserPermission.where(:user_id=>current_user, :permission_base_id=> 141, :access_approve1=> 1)
        when 'approve2'
          select_status = ['approved1', 'canceled2']
          @check_permission = UserPermission.where(:user_id=>current_user, :permission_base_id=> 141, :access_approve2=> 1)
        when 'approve3'
          select_status = ['approved2', 'canceled3']
          @check_permission = UserPermission.where(:user_id=>current_user, :permission_base_id=> 141, :access_approve3=> 1)
        end
        records = EmployeeOvertime.where(:status=> select_status).where("date between ? and ?", periode_begin, periode_end)
        @records = records.includes(employee: [:department])
      else
        period = "#{params[:year]}-#{params[:period_id]}-01".to_date.beginning_of_month().strftime("%Y-%m-%d")
        @period_begin =  period.to_date+20.day if period.present?
        @period_end = period.to_date+1.month+19.day if period.present?

        if params[:input_date].present?
          if params[:input_date].to_date.strftime('%d').to_i <= 20
            period_date = params[:input_date].to_date - 1.month
          else
            period_date = params[:input_date].to_date
          end      
          status = ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3']
          employee_overtime = EmployeeOvertime.where(:date=>params[:input_date], :status=>status)
          @employees = Employee.where(:employee_status=>'Aktif', :department=>current_user.department_id).where.not(:id=>employee_overtime.collect { |e| e.employee_id}).order("name asc").includes(:department, :position)
          @emp_schedules = EmployeeScheduleRecap.find_by(:employee_id=>params[:candidate_id], :periode=>period_date.strftime('%Y%m'), :status=>'active')
        end
      end
    end

    #------------------------------------------------------------------------------
  end

  def show
  end

  def new
    @employee_overtime = EmployeeOvertime.new
  end

  def edit
  end

  def create
    employee_overtime = nil
    if params[:new_record_item].present?
      record = EmployeeOvertime.where(:company_profile_id=>current_user.company_profile_id).group('seq')
      record.last.blank? ? last = 1 : last = record.last.seq+1
      seq = last
      params[:new_record_item].each do |item|
        if item['overtime_begin'] > item['overtime_end']
          ot_date_begin =  params[:employee_overtime]["date"].to_date
          ot_date_end =  params[:employee_overtime]["date"].to_date + 1.days
        elsif item['overtime_begin'] < item['overtime_end']
          ot_date_begin = ot_date_end = params[:employee_overtime]["date"].to_date
        end
        employee_overtime = EmployeeOvertime.create({
          :company_profile_id=>current_user.company_profile_id,
          :employee_id=>item['employee_id'],
          :seq=> seq,
          :period_shift=> params[:employee_overtime]["date"].to_date,
          :date=> params[:employee_overtime]["date"].to_date,
          :schedule=>item['schedule'],
          :datetime_overtime_begin=> ("#{ot_date_begin} #{item["overtime_begin"]}"),
          :datetime_overtime_end=> ("#{ot_date_end} #{item["overtime_end"]}"),
          :overtime_begin=> item["overtime_begin"],
          :overtime_end=> item["overtime_end"],
          :description=> item["description"],
          :status=> 'new',
          :created_at=> DateTime.now(), :created_by=> current_user.id
        })
        employee_overtime.save!
      end if params[:new_record_item].present?
    end
    respond_to do |format|
      format.html { redirect_to employee_overtime, notice: 'Employee Overtime was successfully updated.' }
      format.json { render :show, status: :ok, location: employee_overtime }
    end

    # respond_to do |format|
    #     format.html { redirect_to employee_overtimes_path(), notice: "Document was successfully created" }
    #     format.json { render :show, status: :created, location: @employee_overtime }
    #   else
    #     format.html { render :new }
    #     format.json { render json: record.errors, status: :unprocessable_entity }
    #   end
    #   # logger.info @employee_overtime.errors
    # end
  end

  def update
    params[:new_record_item].each do |item|
      if item['overtime_begin'] > item['overtime_end']
        ot_date_begin =  @employee_overtime.date
        ot_date_end =  @employee_overtime.date + 1.days
      elsif item['overtime_begin'] < item['overtime_end']
        ot_date_begin = ot_date_end = @employee_overtime.date
      end
      employee_overtime = EmployeeOvertime.create({
        :company_profile_id=>current_user.company_profile_id,
        :employee_id=>item['employee_id'],
        :seq=> @employee_overtime.seq,
        :period_shift=> @employee_overtime.date,
        :date=>  @employee_overtime.date,
        :schedule=>item['schedule'],
        :datetime_overtime_begin=> ("#{ot_date_begin} #{item["overtime_begin"]}"),
        :datetime_overtime_end=> ("#{ot_date_end} #{item["overtime_end"]}"),
        :overtime_begin=> item["overtime_begin"],
        :overtime_end=> item["overtime_end"],
        :description=> item["description"],
        :status=> 'new',
        :created_at=> DateTime.now(), :created_by=> current_user.id
      })
    end if params[:new_record_item]

    params[:record_item].each do |item|
      if item['overtime_begin'] > item['overtime_end']
        ot_date_begin =  @employee_overtime.date
        ot_date_end =  @employee_overtime.date + 1.days
      elsif item['overtime_begin'] < item['overtime_end']
        ot_date_begin = ot_date_end = @employee_overtime.date
      end
      employee_overtime = EmployeeOvertime.find_by(:id=> item["id"])
      case item["status"]
      when 'deleted'
        employee_overtime.update({
          :status=> item["status"],
          :updated_at=> DateTime.now(), :updated_by=> current_user.id,
          :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
        })
      else
        employee_overtime.update({
          :datetime_overtime_begin=> ("#{@ot_date_begin} #{item["overtime_begin"]}"),
          :datetime_overtime_end=> ("#{@ot_date_end} #{item["overtime_end"]}"),
          :overtime_begin=> item["overtime_begin"],
          :overtime_end=> item["overtime_end"],
          :updated_at=> DateTime.now(), :updated_by=> current_user.id
        })
      end if employee_overtime.present?
    end if params[:record_item].present?

    respond_to do |format|
      format.html { redirect_to @employee_overtime, notice: 'Employee Overtime was successfully updated.' }
      format.json { render :show, status: :ok, location: @employee_overtime }
    end
  end


  def approve
    if params[:multi_id].present?
      if @employee_overtime.present?
        @employee_overtime.each do |abs|
          employee_overtime = EmployeeOvertime.find_by(:id=>abs.id)
          case params[:status]
          when 'approve1'
            employee_overtime.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()})
          when 'approve2'
            employee_overtime.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()})
          when 'approve3'
            employee_overtime.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})
          end
        end
      end
    else
      notif_msg = nil
      notif_type = "notice"
      employee_overtime = EmployeeOvertime.where(:seq=>@employee_overtime.seq)
      case params[:status]
      when 'approve1'
        employee_overtime.update_all({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now(), :canceled1_by=>nil}) 
      when 'cancel_approve1'
        employee_overtime.update_all({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now(), :approved1_by=> nil}) 
      when 'approve2'
        employee_overtime.update_all({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now(), :canceled2_by=>nil}) 
      when 'cancel_approve2'
        employee_overtime.update_all({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now(), :approved2_by=> nil})
      when 'approve3'
        employee_overtime.update_all({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now(), :canceled3_by=>nil})
      when 'cancel_approve3'
        employee_overtime.update_all({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now(), :approved3_by=> nil})
      end

      notif_msg = "Employee Overtime was successfully #{params[:status]}."
    end

    respond_to do |format|
      if flash[:error].blank?
        if params[:multi_id].present?
          format.html { redirect_to employee_overtimes_url, notice: "Employee overtime was successfully #{params[:status]}." }
        else
          format.html { redirect_to employee_overtime_path(:id=> @employee_overtime.id), notice: "Employee overtime was successfully #{@employee_overtime.status}." }
        end
        format.json { head :no_content }
      else
        format.html { redirect_to employee_overtime_path(:id=> @employee_overtime.id), notif_type.to_sym=> notif_msg}
        format.json { head :no_content }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    def set_employee_overtime
      if params[:multi_id].present?
        @employee_overtime = EmployeeOvertime.where(:id=> params[:multi_id].split(','))
      elsif params[:multi_id] == '' || params[:status]=='approve'
        flash[:error] = 'No record has been approved'
      else
        status = ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3']
        @employee_overtime = EmployeeOvertime.find_by(:id=> params[:id])
        @employee_overtime_items = EmployeeOvertime.where(:seq=> @employee_overtime.seq, :status=>status)
      end

      if !@employee_overtime.present? 
        respond_to do |format|
          format.html { redirect_to employee_absences_url, alert: flash[:error] }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable  
      @employees = Employee.where(:employee_status=>'Aktif').order("name asc").includes(:department, :position)
      @schedules = Schedule.where(:company_profile_id=> current_user.company_profile_id, :status=>'active')
      @departments = Department.where(:status=>'active').order("name asc")

      params[:year] = (params[:year].blank? ? (DateTime.now()).strftime("%Y")  : params[:year] )
      params[:month] = (params[:month].blank? ? (DateTime.now()).strftime("%m")  : params[:month] )
      date = Date.parse("2016-12-31")
      stop = Date.today.beginning_of_month+1.months 
      @periods = Array.new()
      while (date <= stop)
        date = date.advance(months: 1)
        @periods.push(date.strftime("%Y%m") )
      end
      period = params[:month].present? ? (params[:year]+params[:month]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")

      # period = params[:period].present? ? (params[:period]+'01').to_date.beginning_of_month().strftime("%Y-%m-%d") : DateTime.now().beginning_of_month().strftime("%Y-%m-%d")
      period_begin = period.to_date+20.day if period.present?
      period_end = period.to_date+1.month+19.day if period.present?
      # update_employee_presence(period_begin,period_end)
      @period_begin =  period.to_date+20.day if period.present?
      @period_end = period.to_date+1.month+19.day if period.present?

      # @date   = period.present?  ? (params[:controller]+"_"+params[:tbl]).camelize.constantize.where(:status=>'active', :company_profile_id=> current_user.company_profile_id).where("date between ? and ?", period_begin,  period_end).group('date') : nil
      
      @department_selected = (params[:dept_id].present? ? params[:dept_id] : session[:department_id])
      @department_selected = (params[:dept_id] == "" ? nil : @department_selected)

      # @employees = @employees.where(:sys_department_id=> @department_selected) if @department_selected.present?
      # @employees = @employees.where(:id=> params[:employee_id]) if params[:employee_id].present?
    end

    def check_status
      if @employee_overtime.status == 'approved1' || @employee_overtime.status == 'approved2' || @employee_overtime.status == 'approved3'
        if params[:status] == "cancel_approve3" || params[:status] == "cancel_approve2"
        else 
          puts "-------------------------------"
          puts  @employee_overtime.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to employee_overtime_path(:id=> @employee_overtime.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @employee_overtime }
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_overtime_params
      params.require(:employee_overtime).permit(
        :employee_id, 
        :period_shift, 
        :date, 
        :group, 
        :schedule, 
        :early_overtime, 
        :datetime_overtime_begin, 
        :datetime_overtime_end, 
        :overtime_begin,
        :overtime_end,
        :description,
        :data_source,
        :created_by, 
        :created_at, 
        :updated_by, 
        :updated_at
      )
    end
end
