class MeetingMinutesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_meeting_minute, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /meeting_minutes
  # GET /meeting_minutes.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @attendences = MeetingMinuteAttendence.all
    attendences = @attendences.where(:user_id=> current_user.id)
    @pagy, @meeting_minutes = pagy(MeetingMinute.where(:company_profile_id=> current_user.company_profile_id).where("date between ? and ?", session[:date_begin], session[:date_end]).where("created_by = ? or id in (?)", current_user.id, attendences.select(:meeting_minute_id)).where(:status=> 'active').order("created_at desc"), page: params[:page], items: pagy_items)
    @users = User.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')
  end

  # GET /meeting_minutes/1
  # GET /meeting_minutes/1.json
  def show
    @meeting_minute_attendences = MeetingMinuteAttendence.where(:meeting_minute_id=> @meeting_minute.id, :status=> ['active','canceled','approved'])
    @meeting_minute_items = MeetingMinuteItem.where(:meeting_minute_id=> @meeting_minute.id)
  end

  # GET /meeting_minutes/new
  def new
    @meeting_minute = MeetingMinute.new
  end

  # GET /meeting_minutes/1/edit
  def edit
    @meeting_minute_attendences = MeetingMinuteAttendence.where(:meeting_minute_id=> @meeting_minute.id)
    @meeting_minute_items = MeetingMinuteItem.where(:meeting_minute_id=> @meeting_minute.id)
  end

  # POST /meeting_minutes
  # POST /meeting_minutes.json
  def create    
    params[:meeting_minute]["company_profile_id"] = current_user.company_profile_id
    params[:meeting_minute]["created_by"] = current_user.id
    params[:meeting_minute]["created_at"] = DateTime.now()
    @meeting_minute = MeetingMinute.new(meeting_minute_params)

    respond_to do |format|
      if @meeting_minute.save        
        params[:new_attendence].each do |item|
          MeetingMinuteAttendence.create({
            :meeting_minute_id=> @meeting_minute.id,
            :user_id=> item["user_id"],
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_attendence].present?
        params[:new_record_item].each do |item|
          meeting_item = MeetingMinuteItem.create({
            :meeting_minute_id=> @meeting_minute.id,
            :description=> item["description"],
            :action=> item["action"],
            :due_date=> item["due_date"],
            :pic1=> (item["pic1"].present? ? item["pic1"] : nil), 
            :pic2=> (item["pic2"].present? ? item["pic2"] : nil), 
            :pic3=> (item["pic3"].present? ? item["pic3"] : nil), 
            :pic4=> (item["pic4"].present? ? item["pic4"] : nil), 
            :pic5=> (item["pic5"].present? ? item["pic5"] : nil), 
            :status=> 'active', :status_job=> 'on progress',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          logger.info meeting_item.errors.full_messages
        end if params[:new_record_item].present?

        create_joblist(@meeting_minute.id)
        format.html { redirect_to @meeting_minute, notice: 'Meeting minute was successfully created.' }
        format.json { render :show, status: :created, location: @meeting_minute }
      else
        format.html { render :new }
        format.json { render json: @meeting_minute.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meeting_minutes/1
  # PATCH/PUT /meeting_minutes/1.json
  def update
    respond_to do |format|
      params[:meeting_minute]["updated_by"] = current_user.id
      params[:meeting_minute]["updated_at"] = DateTime.now()
      if @meeting_minute.update(meeting_minute_params) 
        # attendence
          params[:attendence].each do |item|
            attendence = MeetingMinuteAttendence.find_by(:id=> item["id"])
            if attendence.present? and item["status"].present?
              if item["status"] == "deleted"
                attendence.update_columns({
                  :status=> item[:status],
                  :deleted_by=> current_user.id,
                  :deleted_at=> DateTime.now()
                })
              else
                attendence.update_columns({
                  :status=> item[:status],
                  :updated_by=> current_user.id,
                  :updated_at=> DateTime.now()
                })
              end
            end
          end if params[:attendence].present?
          params[:new_attendence].each do |item|
            MeetingMinuteAttendence.create({
              :meeting_minute_id=> @meeting_minute.id,
              :user_id=> item["user_id"],
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end if params[:new_attendence].present?
        # item
          params[:new_record_item].each do |item|
            meeting_item = MeetingMinuteItem.create({
              :meeting_minute_id=> @meeting_minute.id,
              :description=> item["description"],
              :action=> item["action"],
              :due_date=> item["due_date"],
              :pic1=> (item["pic1"].present? ? item["pic1"] : nil), 
              :pic2=> (item["pic2"].present? ? item["pic2"] : nil), 
              :pic3=> (item["pic3"].present? ? item["pic3"] : nil), 
              :pic4=> (item["pic4"].present? ? item["pic4"] : nil), 
              :pic5=> (item["pic5"].present? ? item["pic5"] : nil), 
              :status=> 'active', :status_job=> 'on progress',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
            logger.info meeting_item.errors.full_messages
          end if params[:new_record_item].present?

        create_joblist(@meeting_minute.id)

        format.html { redirect_to @meeting_minute, notice: 'Meeting minute was successfully updated.' }
        format.json { render :show, status: :ok, location: @meeting_minute }
      else
        format.html { render :edit }
        format.json { render json: @meeting_minute.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meeting_minutes/1
  # DELETE /meeting_minutes/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to meeting_minutes_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meeting_minute
      @meeting_minute = MeetingMinute.find(params[:id])
    end

    def create_joblist(meeting_minute_id)
      puts "create JobListReport"
      # masukan meeting minute ke job list jika sudah di approve oleh pic  
      MeetingMinuteAttendence.where(:meeting_minute_id=> meeting_minute_id, :status=> ['active', 'approved'] ).each do |attendence|
        MeetingMinuteItem.where(:meeting_minute_id=> meeting_minute_id).each do |mm_item|
          mm_subject = mm_item.meeting_minute.subject
          puts "name: #{attendence.user.first_name}; description: #{mm_item.description}; action: #{mm_item.action}; due_date: #{mm_item.due_date}"
          (1..5).each do |i|
            if mm_item["pic#{i}"].present?
              joblist_report = JobListReport.find_by(:meeting_minute_item_id=> mm_item.id, :user_id=> mm_item["pic#{i}"], :status=> 'active')
              if joblist_report.present?
                joblist_report.update_columns({
                  :job_category_id=> 1, #meeting minutes
                  :department_id=> current_user.department_id,
                  :user_id=> mm_item["pic#{i}"],
                  :company_profile_id=> current_user.company_profile_id,
                  :name=> "MM #{mm_subject}",
                  :description=> mm_item.action,
                  :due_date=> mm_item.due_date,
                  :status=> 'active'
                  })
              else
                joblist_report = JobListReport.new({
                  :meeting_minute_item_id=> mm_item.id,
                  :job_category_id=> 1, #meeting minutes
                  :department_id=> current_user.department_id,
                  :user_id=> mm_item["pic#{i}"],
                  :company_profile_id=> current_user.company_profile_id,
                  :name=> "MM #{mm_subject}",
                  :description=> mm_item.action,
                  :due_date=> mm_item.due_date,
                  :created_by=> mm_item.created_by,
                  :created_at=> DateTime.now(),
                  :date=> DateTime.now()
                })
                joblist_report.save!
              end
            end
          end

        end
      end
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def meeting_minute_params
      params.require(:meeting_minute).permit(:company_profile_id, :subject, :venue, :note, :date, :created_by, :created_at, :updated_by, :updated_at)
    end
end
