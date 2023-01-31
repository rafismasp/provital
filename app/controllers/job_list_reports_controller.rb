class JobListReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_job_list_report, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /job_list_reports
  # GET /job_list_reports.json
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

    @pagy, @job_list_reports = pagy(JobListReport.where(:company_profile_id=> current_user.company_profile_id, :user_id=> current_user.id, :status=> 'active').where("created_at between ? and ?", session[:date_begin], session[:date_end]).order("checked asc, created_at desc"), page: params[:page], items: pagy_items)
    quotes = [
              "<p><i>'Kerja keras mengalahkan bakat ketika bakat tidak bekerja keras.'</i><p><b> - Tim Notke</b>",
              "<p><i>'Keberuntungan itu hebat, tapi sebagian besar dari kehidupan adalah kerja keras.'</i><p><b> - Iain Duncan Smith</b>",
              "<p><i>'Kerja keras, tetap positif, dan bangun pagi. Itu adalah bagian terbaik hari ini.'</i><p><b> - George Allen, Sr.</b>",
              "<p><i>'Kamu harus bangun setiap pagi dengan tekad jika hendak pergi tidur dengan puas.'</i><p><b> - George Lorimer</b>",
              "<p><i>'Satu kunci penting untuk sukses adalah percaya diri. Sebuah kunci penting untuk bisa percaya diri adalah persiapan.'</i><p><b> - Arthur Ashe</b>",
              "<p><i>'Satu-satunya cara untuk melakukan pekerjaan yang hebat adalah dengan mencintai apa yang kamu lakukan.'</i><p><b> - Steve Jobs</b>",
              "<p><i>'Bekerja memberimu arti dan tujuan dan hidup terasa hampa tanpanya.'</i><p><b> - Stephen Hawking</b>",
              "<p><i>'Sudahkah anda bersyukur hari ini?'</i>",
              "<p><i>'Tuhan tidak akan memberikan cobaan melebihi kemampuan hambanya.'</i>",
              "<p><i>'Life is like riding a bicycle. To keep your balance, you must keep moving.'</i><p><b> - Albert Einstein</b>",
              # "<p><i>'Bahagia itu adalah pulang on-time.</i><p> <b> - Zainul Ahmad</b>'",
              "<p><i>'<b>Mengeluh</b> hanya akan membuat hidup kita semakin tertekan, sedangkan <b>Bersyukur</b> akan senantiasa membawa kita pada jalan <b>Kemudahan</b>.'</i>",
              # "<p><i>'Mau Gagal, Mau Sukses itu tidak penting, yang penting berhasil.'</i><p> <b> - Cak Lontong</b>",
              "<p><i>'Sukses bukanlah kebetulan, sukses adalah kerja keras, tekun belajar, berkorban dan yang terpenting ialah mencintai pekerjaan Anda.'</i><p> <b> - Pele</b>",
              "<p><i>'Bekerjalah tanpa suara, dan biarkan kesuksesan Anda yang berbunyi nyaring.'</i><p> <b> - Frank Ocean</b>",
              "<p><i>'Tanpa disiplin, kesuksesan tak mungkin terjadi, titik.'</i><p> <b> - Lou Holtz</b>",
              "<p><i>'Anda mungkin bisa menunda, tapi waktu tidak akan menunggu'</i> <p> <b> - Benjamin Franklin</b>",
              "<p><i>'Kesenangan dalam sebuah pekerjaan membuat kesempurnaan pada hasil yang dicapai'</i> <p> <b> - Aristoteles</b>",
              "<p><i>'Mulailah setiap hari dengan senyuman dan akhiri dengan senyuman'</i> <p> <b> - W. C. Field</b>",
              "<p><i>'Anda tidak bisa pergi dari tanggungjawab esok hari dengan menghindarinya hari ini'</i> <p> <b> - Abraham Lincoln</b>"
            ]

    flash[:notice] = "#{quotes.sample}"
  end

  # GET /job_list_reports/1
  # GET /job_list_reports/1.json
  def show
  end

  # GET /job_list_reports/new
  def new
    @job_list_report = JobListReport.new
    @job_category = JobCategory.all
    if current_user.department_id.present?
      @department = Department.where(:id=> current_user.department_id)
    else
      @department = Department.all
    end
    @users = User.where(:id=> current_user.id)
  end

  # GET /job_list_reports/1/edit
  def edit
    @job_category = JobCategory.all
    @department = Department.all
    @users = User.where(:id=> current_user.id)
  end

  # POST /job_list_reports
  # POST /job_list_reports.json
  def create
    params[:job_list_report]['company_profile_id'] = current_user.company_profile_id
    @job_list_report = JobListReport.new(job_list_report_params)

    respond_to do |format|
      if @job_list_report.save
        format.html { redirect_to @job_list_report, notice: 'Job list report was successfully created.' }
        format.json { render :show, status: :created, location: @job_list_report }
      else
        format.html { render :new }
        format.json { render json: @job_list_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /job_list_reports/1
  # PATCH/PUT /job_list_reports/1.json
  def update
    respond_to do |format|
      if @job_list_report.update(job_list_report_params)
        format.html { redirect_to @job_list_report, notice: 'Job list report was successfully updated.' }
        format.json { render :show, status: :ok, location: @job_list_report }
      else
        format.html { render :edit }
        format.json { render json: @job_list_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /job_list_reports/1
  # DELETE /job_list_reports/1.json
  def destroy
    @job_list_report.destroy
    respond_to do |format|
      format.html { redirect_to job_list_reports_url, notice: 'Job list report was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job_list_report
      @job_list_report = JobListReport.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_list_report_params
      params[:job_list_report]["created_by"] = current_user.id
      params[:job_list_report]["checked_at"] = DateTime.now() if params[:job_list_report]["checked"] 
      params.require(:job_list_report).permit(:name, :due_date, :note, :company_profile_id, :department_id, :user_id, :description, :time_required, :status, :created_by, :checked, :checked_at, :job_category_id)
    end
end
