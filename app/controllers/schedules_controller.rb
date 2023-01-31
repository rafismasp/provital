class SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: [:show, :edit, :update]
  # before_action :set_instance_variable

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

    schedule = Schedule.all
    
    # filter select - begin
      # @option_filters = [['Doc.Status','status'],['Nama Karyawan','employee_id']] 
      # @option_filter_records = schedule

      # if params[:filter_column].present?
      #   case params[:filter_column] 
      #   when 'employee_id'
      #     @option_filter_records = Employee.where(:company_profile_id=> current_user.company_profile_id, :employee_status=> 'Aktif').order("name asc")
      #   end

      #  schedule = schedule.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      # end

    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @schedules = pagy(schedule, page: params[:page], items: pagy_items)

    #------------------------------------------------------------------------------
  end

  def show
  end

  def new
    @schedule = Schedule.new
  end

  def edit    
  end

  def create
    params[:schedule]["created_by"] = current_user.id
    params[:schedule]["created_at"] = DateTime.now()
    @schedule = Schedule.new(schedule_params)

    respond_to do |format|
      if @schedule.save
        format.html { redirect_to @schedule, notice: 'Schedule was successfully created.' }
        format.json { render :show, status: :created, location: @schedule }
      else
        puts @schedule.errors.full_messages
        format.html { render :new }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
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

  # def export
  #   template_report(controller_name, current_user.id, nil)
  # end

  private
    def set_schedule
      @schedule = Schedule.find_by(:id=> params[:id])
    end

    # def set_instance_variable  
    #   @employees = Employee.where(:employee_status=>'Aktif').order("name asc").includes(:department, :position)
    #   @absence_types = EmployeeAbsenceType.where(:status=> 'active').order('name asc')
    #   @departments = Department.where(:status=>'active').order('name asc')

    #   @employee_alls = Employee.where(:employee_status=>'Aktif').order("name asc")
    #   @tahun        = (params[:tahun].blank? ? Time.now.year : params[:tahun]).to_s
    #   period_begin  = "#{@tahun}0101".to_date.beginning_of_year()
    #   period_end    = "#{@tahun}0101".to_date.end_of_year() 

    #   if !params[:multi_id].present?
    #     absences              = EmployeeAbsence.where(:employee_id=> (params[:employee_id].present? ? params[:employee_id] : (@employee_absence.present? ? @employee_absence.employee_id : nil)), :status=> 'approved3').where("end_date between ? and ?", period_begin, period_end).includes(:employee_absence_type)
    #     @absences             = absences.where(:employee_absence_types => {:special=> nil}).order("begin_date asc")    
    #     @special_absences     = absences.where(:employee_absence_types => {:special=> 1}).order("begin_date asc")
    #   end
    # end

    # Never trust parameters from the scary internet, only allow the white list through.
    def schedule_params
      params.require(:schedule).permit(:code, :overday, :overday2, :break, :monday_in, :monday_out, :tuesday_in, :tuesday_out, :wednesday_in, :wednesday_out, :thursday_in, :thursday_out, :friday_in, :friday_out, :saturday_in, :saturday_out, :sunday_in, :sunday_out, :description, :created_by, :created_at, :updated_by, :updated_at)
    end
end
