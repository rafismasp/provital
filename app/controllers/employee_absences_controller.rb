class EmployeeAbsencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee_absence, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable

  include UserPermissionsHelper
  include EmployeeAbsencesHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status] == 'deleted' ? 'void' : params[:status])
  end

  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    employee_absences = EmployeeAbsence.where("begin_date between ? and ?", session[:date_begin], session[:date_end]).order("begin_date desc")
    
    # filter select - begin
      @option_filters = [['Doc.Status','status'],['Nama Karyawan','employee_id']] 
      @option_filter_records = employee_absences

      if params[:filter_column].present?
        case params[:filter_column] 
        when 'employee_id'
          @option_filter_records = Employee.where(:company_profile_id=> current_user.company_profile_id, :employee_status=> 'Aktif').order("name asc")
        end

       employee_absences = employee_absences.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    # filter select - end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @employee_absences = pagy(employee_absences, page: params[:page], items: pagy_items)

    #------------------------------------------------------------------------------
    if params[:partial] == "change_employee"
      leaves                = EmployeeLeave.where(:period=> @tahun, :status=> 'active')
      @employee             = @employees.find_by(:id=> params[:employee_id])
      @os_leave             = (leaves.find_by(:employee_id=> params[:employee_id]).present? ? leaves.find_by(:employee_id=> params[:employee_id]).outstanding : leave_this_years(@employee.id, @employee.join_date, @tahun)[:outstanding]) # cuti
    elsif params[:partial] == "approve_all"
      period_yyyy = "#{params[:period].to_s[0..3]}"
      period_mmdd = "#{params[:period].to_s[4..5]}21"

      periode_begin = "#{period_yyyy}#{period_mmdd}".to_date
      periode_end   = (periode_begin+1.month).strftime("%Y-%m-20")
      puts "#{periode_begin} sd #{periode_end}"
      
      @departments = @departments

      select_status = nil
      @check_permission = nil
      case params[:select_status]
      when 'approve1'
        select_status = ['new', 'canceled1']
        select_dept_hierarchy = DepartmentHierarchy.where("approved1_by = ? ", current_user.id).group(:department_id).map { |e| e.department_id }
        @check_permission = DepartmentHierarchy.where(:approved1_by=> current_user.id, :status=> 'active')
      when 'approve2'
        select_status = ['approved1', 'canceled2']
        select_dept_hierarchy = DepartmentHierarchy.where("approved2_by = ? ", current_user.id).group(:department_id).map { |e| e.department_id }
        @check_permission = DepartmentHierarchy.where(:approved2_by=> current_user.id, :status=> 'active')
      when 'approve3'
        select_status = ['approved2', 'canceled3']
        select_dept_hierarchy = DepartmentHierarchy.where("approved3_by = ? ", current_user.id).group(:department_id).map { |e| e.department_id }
        @check_permission = DepartmentHierarchy.where(:approved3_by=> current_user.id, :status=> 'active')
      end
      select_department = (select_dept_hierarchy.present? ? select_dept_hierarchy : nil)
      records = EmployeeAbsence.where(:status=> select_status).where("begin_date >= ? and end_date <= ?", periode_begin, periode_end)
      records = records.where(:employee_absence_type_id=> params[:select_absence_type]) if params[:select_absence_type].present?
      @records = records.includes([:employee_absence_type, :creator]).includes(employee: [:department]).where(:employees => {:department_id => (params[:select_department].present? ? params[:select_department] : select_department)})
    end
  end

  def show
    leaves                = EmployeeLeave.where(:period=> @employee_absence.begin_date.year, :status=> 'active')        
    employee              = Employee.find_by_id(params[:partial] == "change_employee" ? employee_id : @employee_absence.employee_id)
    @os_leave             = (leaves.find_by(:employee_id=> employee.id).present? ? leaves.find_by(:employee_id=> employee.id).outstanding : leave_this_years(employee.id, employee.join_date, @tahun)[:outstanding])
  end

  def new
    @employee_absence = EmployeeAbsence.new
  end

  def edit
    leaves                = EmployeeLeave.where(:period=> @employee_absence.begin_date.year, :status=> 'active')
    @employee             = @employees.find_by(:id=> @employee_absence.employee_id)
    @os_leave             = (leaves.find_by(:employee_id=> @employee_absence.employee_id).present? ? leaves.find_by(:employee_id=> @employee_absence.employee_id).outstanding : leave_this_years(@employee.id, @employee.join_date, @tahun)[:outstanding]) # cuti
  end

  def create
    params[:employee_absence]["created_by"] = current_user.id
    params[:employee_absence]["created_at"] = DateTime.now()
    @employee_absence = EmployeeAbsence.new(employee_absence_params)
    leave_this_years(@employee_absence.employee_id, @employee_absence.employee.join_date, nil)
    notif_by_hierarchy(@employee_absence.employee.department_id, 'new', @employee_absence.id)
    update_absence_same_nik(@employee_absence.employee.nik, DateTime.now())

    respond_to do |format|
      status = ['new','approved1','canceled1','approved2','canceled2','approved3','canceled3']
      check = EmployeeAbsence.find_by(
        :employee_id=> params[:employee_absence]['employee_id'],
        :begin_date=> params[:employee_absence]['begin_date'],
        :end_date=> params[:employee_absence]['end_date'],
        :status=> status
       )
      
      if check.present?
        flash[:alert] = "Absence document date between #{check.begin_date} until #{check.end_date} date have been created before with notes : #{check.employee_absence_type.name}"
        format.html { render :new }
        format.json { render json: @employee_absence.errors, status: :unprocessable_entity }
      else
        if @employee_absence.save
          if params[:file].present?
            cek_attach = EmployeeAbsenceType.find_by(:id=>@employee_absence.employee_absence_type_id) 
            if cek_attach.attachment_required == '1'
              params["file"].each do |attach|
                content =  attach[:attachment].read
                hash = Digest::MD5.hexdigest(content)
                af = EmployeeAbsenceFile.where(:employee_absence_id=>@employee_absence.id)
                pf = af.find_by(:file_hash=>hash)
                if pf.blank?
                  filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+attach[:attachment].original_filename
                  ext=File.extname(filename_original)
                  filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
                  dir = "public/uploads/employee_absence/"
                  FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
                  path = File.join(dir, "#{hash}#{ext}")
                  tmp_path_filename=File.join('/tmp', filename)
                  File.open(path, 'wb') do |file|
                    file.write(content)
                    EmployeeAbsenceFile.create({
                      :employee_absence_id=> @employee_absence.id,
                      :filename_original=>filename_original,
                      :file_hash=> hash ,
                      :filename=> filename,
                      :path=> path,
                      :ext=> ext,
                      :created_at=> DateTime.now,
                      :created_by=> current_user.id
                    })             
                  end
                end 
              end
            end
          else
           flash[:error] ='Berhasil Tersimpan Dengan Lampiran!'
          end

          format.html { redirect_to @employee_absence, notice: 'Document was successfully created.' }
          format.json { render :show, status: :created, location: @employee_absence }
        else
          puts @employee_absence.errors.full_messages
          format.html { render :new }
          format.json { render json: @employee_absence.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    params[:employee_absence]["updated_by"] = current_user.id
    params[:employee_absence]["updated_at"] = DateTime.now()
    respond_to do |format|
      check = EmployeeAbsence.find_by(
        :employee_id=> @employee_absence.employee_id,
        :begin_date=> params[:employee_absence]['begin_date'],
        :end_date=> params[:employee_absence]['end_date']
       )
      if check.present?
        flash[:alert] = "Absence document date between #{check.begin_date} until #{check.end_date} date have been created before with notes : #{check.employee_absence_type.name}"
        format.html { render :new }
        format.json { render json: @employee_absence.errors, status: :unprocessable_entity }
      else
        if @employee_absence.update(employee_absence_params)
          if params[:file].present?
            params["file"].each do |attach|
              content =  attach[:attachment].read
              hash = Digest::MD5.hexdigest(content)
              af = EmployeeAbsenceFile.where(:employee_absence_id=>@employee_absence.id)
              pf = af.find_by(:file_hash=>hash)
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+attach[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/employee_absence/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
              end
              if af.blank?
                EmployeeAbsenceFile.create({
                  :employee_absence_id=> @employee_absence.id,
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :status=>'active',
                  :created_at=> DateTime.now(),
                  :created_by=> current_user.id
                })             
              else
                af.update_all({
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :status=>'active',
                  :created_at=> DateTime.now(),
                  :created_by=> current_user.id
                })
              end 
            end
          else
            absence_type = EmployeeAbsenceType.find_by(:id=>@employee_absence.employee_absence_type_id)
            if absence_type.attachment_required == '0'
              attachment = EmployeeAbsenceFile.find_by(:employee_absence_id=>@employee_absence.id, :status=>'active')
              if attachment.present?
                attachment.update({
                  :status=>'suspend',
                  :updated_at=>DateTime.now(),
                  :updated_by=>current_user.id
                })
              end
            end
          end
          update_absence_same_nik(@employee_absence.employee.nik, DateTime.now())

          format.html { redirect_to @employee_absence, notice: 'Document was successfully updated.' }
          format.json { render :show, status: :ok, location: @employee_absence }
        else
          format.html { render :edit }
          format.json { render json: @employee_absence.errors, status: :unprocessable_entity }
        end
      end
    end
  end


  def approve
    if params[:multi_id].present?
      if @employee_absence.present?
        @employee_absence.each do |abs|
          employee_absence = EmployeeAbsence.find_by(:id=>abs.id)
          case params[:status]
          when 'approve1'
            employee_absence.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()})
            notif_by_hierarchy(abs.employee.department_id, 'approved1', abs.id) 
          when 'approve2'
            employee_absence.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()})
            notif_by_hierarchy(abs.employee.department_id, 'approved2', abs.id) 
          when 'approve3'
            approve3_absence(abs)
            notif_by_hierarchy(abs.employee.department_id, 'approved3', abs.id)
          end
          update_absence_same_nik(abs.employee.nik, DateTime.now())
        end
      end
    else
      case params[:status]
      when 'approve1'
        @employee_absence.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
      when 'cancel_approve1'
        @employee_absence.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
      when 'approve2'
        if @employee_absence.created_by.to_i == current_user.id.to_i and DepartmentHierarchy.find_by(:approved2_by=> current_user.id, :department_id=> @employee_absence.employee.department_id).present?
          flash[:error] = "Pembuat Tidak Boleh Approval2"
        else
          @employee_absence.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
        end
      when 'cancel_approve2'
        if @employee_absence.created_by.to_i == current_user.id.to_i and DepartmentHierarchy.find_by(:cancel2_by=> current_user.id, :department_id=> @employee_absence.employee.department_id).present?
          flash[:error] = "Pembuat Tidak Boleh Cancel Approval2"
        else
          @employee_absence.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()}) 
        end
      when 'approve3'
        approve3_absence(@employee_absence)
      when 'cancel_approve3'
        leave = EmployeeLeave.find_by(:period=> @employee_absence.begin_date.to_date.strftime("%Y"), :employee_id=> @employee_absence.employee_id, :status=> 'active')
        absence_types = EmployeeAbsenceType.find_by(:id=> @employee_absence.employee_absence_type_id, :special=> nil)

        if absence_types.present?
          puts "Ijin spesial"
          if leave.present? 
            leave.update(
              :day=> (leave.day.to_i - @employee_absence.day.to_i),
              :outstanding=> (leave.outstanding + @employee_absence.day.to_i) 
            ) 
            puts "update cuti"
          end
        end
        @employee_absence.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()}) 
      when 'void','deleted'
        @employee_absence.update({:status=> 'deleted', :deleted_by=> current_user.id, :deleted_at=> DateTime.now()}) 
      when 'cancel_void'
        check = EmployeeAbsence.find_by(
          :employee_id=> @employee_absence.id,
          :begin_date=> @employee_absence.begin_date,
          :end_date=> @employee_absence.end_date
        )
        if check.present?
          flash[:error] = "Absence document date between #{check.begin_date} until #{check.end_date} date have been created before with notes : #{check.employee_absence_type.name}, Check it please!"
        else
          @employee_absence.update({:status=> 'new', :canceled1_by=> nil, :canceled1_at=> nil}) 
        end
      when 'approve'
        flash[:error] = "No record has been approved "
      end
      notif_by_hierarchy(@employee_absence.employee.department_id, params[:status], @employee_absence.id)
    end
    respond_to do |format|
      if flash[:error].blank?
        if params[:multi_id].present?
          format.html { redirect_to employee_absences_url, notice: "Employee absence was successfully #{params[:status]}." }
        else
          format.html { redirect_to employee_absence_path(:id=> @employee_absence.id), notice: "Employee absence was successfully #{@employee_absence.status}." }
        end
        format.json { head :no_content }
      else
        format.html { redirect_to (params[:multi_id].present? ? employee_absences_url : employee_absence_path(:id=> @employee_absence.id)), alert: flash[:error] }
        format.json { render json: @employee_absence.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    def set_employee_absence
      if params[:multi_id].present?
        @employee_absence = EmployeeAbsence.where(:id=> params[:multi_id].split(','))
        @employee_files = EmployeeAbsenceFile.find_by(:employee_absence_id=>params[:multi_id].split(','), :status=>'active')
      elsif params[:multi_id] == '' || params[:status]=='approve'
        flash[:error] = 'No record has been approved'
      else
        @employee_absence = EmployeeAbsence.find_by(:id=> params[:id])
        @employee_files = EmployeeAbsenceFile.find_by(:employee_absence_id=>@employee_absence.id, :status=>'active')
        @department_hierarchies = DepartmentHierarchy.where(:department_id=> (@employee_absence.employee.department_id), :status=> 'active')
      end


      if !@employee_absence.present? 
        respond_to do |format|
          format.html { redirect_to employee_absences_url, alert: flash[:error] }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable  
      @employees = Employee.where(:employee_status=>'Aktif').order("name asc").includes(:department, :position)
      @absence_types = EmployeeAbsenceType.where(:status=> 'active').order('name asc')
      @departments = Department.where(:status=>'active').order('name asc')

      @employee_alls = Employee.where(:employee_status=>'Aktif').order("name asc")
      @tahun        = (params[:tahun].blank? ? Time.now.year : params[:tahun]).to_s
      period_begin  = "#{@tahun}0101".to_date.beginning_of_year()
      period_end    = "#{@tahun}0101".to_date.end_of_year() 

      if !params[:multi_id].present?
        absences              = EmployeeAbsence.where(:employee_id=> (params[:employee_id].present? ? params[:employee_id] : (@employee_absence.present? ? @employee_absence.employee_id : nil)), :status=> 'approved3').where("end_date between ? and ?", period_begin, period_end).includes(:employee_absence_type)
        @absences             = absences.where(:employee_absence_types => {:special=> nil}).order("begin_date asc")    
        @special_absences     = absences.where(:employee_absence_types => {:special=> 1}).order("begin_date asc")
      end
    end

    def check_status
      if @employee_absence.status == 'approved1' || @employee_absence.status == 'approved2' || @employee_absence.status == 'approved3'
        if params[:status] == "cancel_approve3" || params[:status] == "cancel_approve2"
        else 
          puts "-------------------------------"
          puts  @employee_absence.status
          puts "-------------------------------"
          respond_to do |format|
            format.html { redirect_to employee_absence_path(:id=> @employee_absence.id), alert: 'Cannot be edited because it has been approved' }
            format.json { render :show, status: :created, location: @employee_absence }
          end
        end
      end
    end

    def approve3_absence(record)
      leave = EmployeeLeave.find_by(:period=> record.begin_date.to_date.strftime("%Y"), :employee_id=> record.employee_id, :status=> 'active')
      absence_types = EmployeeAbsenceType.find_by(:id=> record.employee_absence_type_id, :special=> nil)

      if absence_types.present?
        puts "Ijin spesial"
        if leave.present? 
          if (leave.outstanding - record.day.to_i) >= 0
            new_day = (leave.day.to_i + record.day.to_i)
            new_outstanding = (leave.outstanding - record.day.to_i)
            leave.update(
              :day=> new_day,
              :outstanding=> new_outstanding 
            )
            puts "update cuti"
          else
            flash[:error] = "#{record.employee.name}=> Sisa Cuti tidak cukup"
          end
        else
          outs = leave_this_years(record.employee_id, record.employee.join_date, nil)[:outstanding]
          if outs != 0
            EmployeeLeave.create(
              :period=> record.begin_date.to_date.strftime("%Y"),
              :employee_id=> record.employee_id,
              :day=> record.day,
              :outstanding=> (outs - record.day.to_i),
              :status=> 'active',
              :created_at=> DateTime.now(),
              :created_by=> session[:id]
              )
            puts "Create cuti"
          else
            flash[:error] = "#{record.employee.name}=> tidak memiliki cuti as"
            puts "tidak ada data cuti"   
          end
        end
      end
      if flash[:error].blank?
        record.update({:status=>'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()})
        params[:period] = "#{params[:select_period_yyyy]}#{params[:select_period_yyyymm]}"
      else
        flash[:error] = "Pengajuan #{absence_types.name} #{record.employee.name} pada tanggal #{record.begin_date} s/d #{record.end_date} tidak bisa diproses karena : Jumlah cuti yang tersisa kurang dari pengajuan cuti"
      end
    end

    def notif_by_hierarchy(dept_id, status, id)
      DepartmentHierarchy.where(:department_id=> dept_id, :status=> 'active').each do |record|
        case status
        when 'deleted'
          create_job_list_report(record.created_by, id, 0)
        when 'new','canceled1'
          create_job_list_report(record.approved1_by, id, 1)
        when 'approved1','canceled2'
          create_job_list_report(record.approved2_by, id, 2)
        when 'approved2','canceled3'
          create_job_list_report(record.approved3_by, id, 3)
        end
      end
    end

    def create_job_list_report(account_id, id, approval_level)
      record = EmployeeAbsence.find_by(:id=> id)
      if record.present?
        requested_by = record.employee.name
        periode_begin = record.begin_date
        periode_end   = record.end_date
        absence_type_code  = (record.employee_absence_type.present? ? record.employee_absence_type.code : "-")
        absence_type_name  = (record.employee_absence_type.present? ? record.employee_absence_type.name : "-")
        case record.status
        when 'canceled1', 'canceled2', 'canceled3', 'deleted'
          subject_mail = "Info: izin/cuti #{absence_type_code} dari #{requested_by} status #{record.status}!"
          # note_void    = nil

          case record.status
          when 'canceled1'
            canceled_by  = record.canceled1.name
          when 'canceled2'
            canceled_by  = record.canceled2.name
          when 'canceled3'
            canceled_by  = record.canceled3.name
          when 'deleted'
            canceled_by  = record.voided.name
            # note_void    = record.note_void
          end
          content_mail = "Tidak disetujui oleh: #{canceled_by} untuk izin/cuti #{absence_type_code} #{absence_type_name} dari #{requested_by} periode #{periode_begin} sd #{periode_end};"
        when 'new', 'approved1', 'approved2'
          subject_mail = "approval #{approval_level} izin/cuti #{absence_type_code} dari #{requested_by}"
          content_mail = "Mohon untuk approve izin/cuti #{absence_type_code} #{absence_type_name} dari #{requested_by} periode #{periode_begin} sd #{periode_end};"
        end

        diff_day = TimeDifference.between(record.created_at, record.begin_date).in_days
        case absence_type_code
        when 'CT', 'C02'
          if diff_day > 14
            content_mail += "note: Cuti paling lambat 14 hari dari tanggal pembuatan!"
          end
        when 'CHM', 'CML'
          if diff_day > 45
            content_mail += "note: Cuti paling lambat 45 hari dari tanggal pembuatan!"
          end
        when 'IS'
          if diff_day > 1
            content_mail += "note: Cuti paling lambat 1 hari dari tanggal pembuatan!"
          end
        when 'ITM'
          if diff_day > 2
            content_mail += "note: Izin 1 hari sebelumnya"
          end
        end
          # Cuti tahunan diajukan paling lambat 14 hari sebelumnya.
          # maksimal pengajuan cuti dalam satu kali pengajuan adalah 3 hari.
          # Cuti nikah diajukan palng lambat 14 hari sebelumnya.
          # cuti lahir diajukan paling lambat 45 hari sebelumnya ( untuk wanita ) kecuali keadaan yang tidak memungkinkan, untuk suami 2 hari untuk menemani istrinya melahirkan.
          # Sakit paling lambat saat masuk kerja.
          # Izin 1 hari sebelumnya.

        joblist_report = JobListReport.find_by(
            :company_profile_id=>1,
            :user_id=> account_id, 
            :name=> subject_mail, 
            :description=> content_mail
          )

        if joblist_report.blank?
          user = User.find_by(:id=>account_id)
          joblist_report = JobListReport.new({
            :company_profile_id=>1,
            :user_id=> account_id,
            :department_id=> user.department_id,
            :job_category_id=>1,               
            :name=> subject_mail, 
            :description=> content_mail,
            :due_date=> periode_begin,
            :date=> periode_begin,
            :status=> 'active',
            :created_by=> record.created_by,
            :created_at=> DateTime.now()
          })

          joblist_report.save!
          puts "create job list report #{account_id}"
        else
          joblist_report.update({
            :company_profile_id=>1,
            :user_id=> account_id, 
            :name=> subject_mail, 
            :description=> content_mail,
            :due_date=> periode_begin,
            :status=> 'active'
            })
        end

        User.where(:id=> account_id).each do |account|
          if account.email.present?
            UserMailer.tiki(account.email, subject_mail, content_mail.html_safe, nil).deliver! 
            UserMailer.tiki("aden@techno.co.id", subject_mail, content_mail.html_safe, nil).deliver! 
            puts "send email to #{account.email}"
          else
            puts "SMTP To address Blank! "
            UserMailer.tiki("aden@techno.co.id", subject_mail, "Employee_Absence_id #{record.id} => SMTP To address Blank! ", nil).deliver! 
          end
        end
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_absence_params
      params.require(:employee_absence).permit(:employee_id, :employee_absence_file_id, :employee_absence_type_id, :day, :description, :begin_date, :end_date, :created_by, :created_at, :updated_by, :updated_at, :file)
    end
end
