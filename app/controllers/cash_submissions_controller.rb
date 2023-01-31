class CashSubmissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cash_submission, only: [:show, :edit, :update, :destroy, :approve]
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

  # GET /cash_submissions
  # GET /cash_submissions.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    cash_submissions = CashSubmission.where("date between ? and ?", session[:date_begin], session[:date_end]).order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("approved3_at desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status'],['Penyelesaian Status','status_bon']] 
      @option_filter_records = cash_submissions

      if params[:filter_column].present?
       cash_submissions = cash_submissions.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

      cash_submissions = cash_submissions.order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void'])
    # filter select - end


    logger.info "==========================="
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @cash_submissions = pagy(cash_submissions, page: params[:page], items: pagy_items)
  end

  # GET /cash_submissions/1
  # GET /cash_submissions/1.json
  def show

    @record_files = CashSubmissionFile.where(:cash_submission_id=>params[:id],:status=>"active")
  end

  # GET /cash_submissions/new
  def new
    @cash_submission = CashSubmission.new

  end

  # GET /cash_submissions/1/edit
  def edit
    @record_files = CashSubmissionFile.where(:cash_submission_id=>params[:id],:status=>"active")

  end

  # POST /cash_submissions
  # POST /cash_submissions.json
  def create
    params[:cash_submission]["company_profile_id"] = current_user.company_profile_id
    params[:cash_submission]["created_by"] = current_user.id
    params[:cash_submission]["created_at"] = DateTime.now()
    params[:cash_submission]["number"] = document_number(controller_name, DateTime.now(), params[:cash_submission]["department_id"], nil, nil)
    logger.info params[:cash_submission]
    @cash_submission = CashSubmission.new(cash_submission_params)

    respond_to do |format|
      if @cash_submission.save
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = CashSubmissionFile.where(:cash_submission_id=>@cash_submission.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/cash_submission/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                CashSubmissionFile.create({
                  :cash_submission_id=> @cash_submission.id,
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })             
              end
            end 
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end

        format.html { redirect_to @cash_submission, notice: 'Cash Submission Payment was successfully created.' }
        format.json { render :show, status: :created, location: @cash_submission }
      else
        format.html { render :new }
        format.json { render json: @cash_submission.errors, status: :unprocessable_entity }
      end
      logger.info @cash_submission.errors
    end
  end

  def update
    params[:cash_submission]["updated_by"] = current_user.id
    params[:cash_submission]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @cash_submission.update(cash_submission_params)   
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = CashSubmissionFile.where(:cash_submission_id=>@cash_submission.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/cash_submission/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                CashSubmissionFile.create({
                  :cash_submission_id=> @cash_submission.id,
                  :filename_original=>filename_original,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path,
                  :ext=> ext,
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })             
              end
            end 
          end  
        else
         flash[:error]='Berhasil Tersimapn Dengan Lampiran!'
        end

        params["record_file"].each do |item|
          file = CashSubmissionFile.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            file.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          end
        end if params["record_file"].present?

        format.html { redirect_to cash_submission_path(:id=> @cash_submission.id), notice: "#{@cash_submission.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @cash_submission }     
      else
        format.html { render :edit }
        format.json { render json: @cash_submission.errors, status: :unprocessable_entity }
      end
    end
  end


  def approve    
    case params[:status]
    when 'void'
      @cash_submission.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()}) 
    when 'cancel_void'
      @cash_submission.update({:status=> 'new'}) 
    when 'approve1'
      @cash_submission.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @cash_submission.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @cash_submission.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @cash_submission.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @cash_submission.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @cash_submission.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to cash_submissions_url, alert: 'Cash Submission was successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to cash_submission_path(:id=> @cash_submission.id), notice: "Cash Submission was successfully #{@cash_submission.status}." }
        format.json { head :no_content }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /cash_submissions/1
  # DELETE /cash_submissions/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to cash_submissions_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status
    if @cash_submission.status == 'approved3'
      respond_to do |format|
        format.html { redirect_to @cash_submission, notice: 'Cannot be edited because it has been approved' }
        format.json { render :show, status: :created, location: @cash_submission }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cash_submission
      if params[:multi_id].present?
        @cash_submission = CashSubmission.where(:id=> params[:multi_id].split(','))
        if @cash_submission.present?
          # @cash_submission_items = CashSubmissionItem.where(:status=> 'active').includes(:cash_submission).where(:cash_submissions => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("cash_submissions.number desc")
        else
          respond_to do |format|
            format.html { redirect_to cash_submissions_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      else
        @cash_submission = CashSubmission.find_by(:id=> params[:id])
        if @cash_submission.present?
          # @cash_submission_items = CashSubmissionItem.where(:status=> 'active').includes(:cash_submission).where(:cash_submissions => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("cash_submissions.number desc")
        else
          respond_to do |format|
            format.html { redirect_to cash_submissions_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      end
    end

    def set_instance_variable
      @cash_submissions = CashSubmission.where(:company_profile_id=> current_user.company_profile_id)

      # @bank_lists = [['Bank Syariah Indonesia','BSMDIDJA'], ['BANK CIMB NIAGA TBK - UNIT SYARIAH','SYNAIDJ1'],['BANK DANAMON INDONESIA - UNIT SYARIAH','SYBDIDJ1'],['BANK INDONESIA','INDOIDJA'],['BANK OF AMERICA , NA','BOFAID2X'],['BANK OF CHINA (HONG KONG) LIMITED','BKCHIDJA'],['Bank Pembangunan Daerah Jambi UUS','SYJMIDJ1'],['BANK PERMATA TBK - UNIT SYARIAH','SYBBIDJ1'],['BANK TABUNGAN NEGARA - UNIT SYARIAH','SYBTIDJ1'],['BPD JAMBI','PDJMIDJ1'],['BPD SUMATERA BARAT','PDSBIDJ1'],['BPD YOGYAKARTA','PDYKIDJ1'],['CITIBANK N.A.','CITIIDJX'],['DEUTSCHE BANK AG','DEUTIDJA'],['JPMORGAN CHASE BANK, NA','CHASIDJX'],['MUFG Bank, Ltd','BOTKIDJX'],['PT BANK BNI SYARIAH','SYNIIDJ1'],['PT BANK JABAR BANTEN SYARIAH','SYJBIDJ1'],['PT BANK MEGA, Tbk','MEGAIDJA'],['PT. Bank Aceh Syariah','SYACIDJ1'],['PT. BANK AMAR INDONESIA','LOMAIDJ1'],['PT. BANK ANZ INDONESIA','ANZBIDJX'],['PT. BANK ARTA GRAHA INTERNASIONAL, Tbk','ARTGIDJA'],['PT. BANK ARTOS INDONESIA','ATOSIDJ1'],['PT. BANK BCA SYARIAH','SYCAIDJ1'],['PT. BANK BISNIS INTERNASIONAL','BUSTIDJ1'],['PT. BANK BNP PARIBAS INDONESIA','BNPAIDJA'],['PT. BANK BUKOPIN','BBUKIDJA'],['PT. BANK BUMI ARTA','BBAIIDJA'],['PT. BANK CAPITAL INDONESIA','BCIAIDJA'],['PT. BANK CENTRAL ASIA, Tbk.','CENAIDJA'],['PT. Bank China Construction Bank Indonesia, Tbk','MCORIDJA'],['PT. BANK CIMB NIAGA TBK','BNIAIDJA'],['PT. BANK COMMONWEALTH','BICNIDJA'],['PT. BANK CTBC INDONESIA','CTCBIDJA'],['PT. BANK DANAMON INDONESIA, Tbk','BDINIDJA'],['PT. BANK DBS INDONESIA','DBSBIDJA'],['PT. BANK DKI','BDKIIDJ1'],['PT. BANK DKI UNIT USAHA SYARIAH','SYDKIDJ1'],['PT. BANK FAMA INTERNASIONAL','FAMAIDJ1'],['PT. BANK GANESHA','GNESIDJA'],['PT. BANK HARDA INTERNASIONAL','HRDAIDJ1'],['PT. Bank HSBC Indonesia','HSBCIDJA'],['PT. Bank IBK Indonesia Tbk','AGSSIDJA'],['PT. BANK ICBC INDONESIA','ICBKIDJA'],['PT. BANK INA PERDANA','IAPTIDJA'],['PT. BANK INDEX SELINDO','BIDXIDJA'],['PT. BANK JASA JAKARTA','JSABIDJ1'],['PT. BANK JTRUST INDONESIA, TBK','CICTIDJA'],['PT. BANK KEB HANA INDONESIA','HNBNIDJA'],['PT. BANK KESEJAHTERAAN EKONOMI','KSEBIDJ1'],['PT. BANK LAMPUNG','PDLPIDJ1'],['PT. BANK MANDIRI (PERSERO), Tbk','BMRIIDJA'],['PT. BANK MANDIRI TASPEN','SIHBIDJ1'],['PT. BANK MASPION INDONESIA','MASDIDJ1'],['PT. BANK MAYAPADA INTERNASIONAL TBK','MAYAIDJA'],['PT. BANK MAYBANK INDONESIA TBK','IBBKIDJA'],['PT. BANK MAYBANK INDONESIA Tbk. UNIT USAHA SYARIAH','SYBKIDJ1'],['PT. BANK MAYORA','MAYOIDJA'],['PT. BANK MEGA SYARIAH','BUTGIDJ1'],['PT. BANK MESTIKA DHARMA','MEDHIDS1'],['PT. BANK MIZUHO INDONESIA','MHCCIDJA'],['PT. BANK MNC INTERNATIONAL, TBK','BUMIIDJA'],['PT. BANK MUAMALAT INDONESIA','MUABIDJA'],['PT. BANK MULTI ARTA SENTOSA','BMSEIDJA'],['PT. BANK NAGARI - UNIT USAHA SYARIAH','SYSBIDJ1'],['PT. BANK NATIONALNOBU','LFIBIDJ1'],['PT. BANK NEGARA INDONESIA (PERSERO),Tbk','BNINIDJA'],['PT. BANK NET INDONESIA SYARIAH','NETBIDJA'],['PT. BANK OCBC NISP, Tbk.','NISPIDJA'],['PT. BANK OF INDIA INDONESIA, TBK','SWBAIDJ1'],['PT. BANK OKE INDONESIA','LMANIDJ1'],['PT. Bank Panin Dubai Syariah, Tbk','ARFAIDJ1'],['PT. BANK PEMBANGUNAN DAERAH BANTEN','PDBBIDJ1'],['PT. BANK PEMBANGUNAN DAERAH DIY UNIT USAHA SYARIAH','SYYKIDJ1'],['PT. BANK PEMBANGUNAN DAERAH JATENG UNIT USAHA SYARIAH','SYJGIDJ1'],['PT. BANK PEMBANGUNAN DAERAH KALSEL - UNIT USAHA SYARIAH','SYKSIDJ1'],['PT. BANK PEMBANGUNAN DAERAH SUMUT UUS','SYSUIDJ1'],['PT. BANK PERMATA, TBK','BBBAIDJA'],['PT. BANK PRIMA MASTER','PMASIDJ1'],['PT. BANK QNB INDONESIA, Tbk','AWANIDJA'],['PT. BANK RABOBANK INTERNATIONAL INDONESIA','RABOIDJA'],['PT. BANK RAKYAT INDONESIA (PERSERO), Tbk','BRINIDJA'],['PT. BANK RAKYAT INDONESIA AGRONIAGA, TBK','AGTBIDJA'],['PT. BANK ROYAL INDONESIA','ROYBIDJ1'],['PT. BANK SAHABAT SAMPOERNA','BDIPIDJ1'],['PT. BANK SBI INDONESIA','IDMOIDJ1'],['PT. Bank Shinhan Indonesia','MEEKIDJ1'],['PT. BANK SINARMAS','SBJKIDJA'],['PT. BANK SINARMAS UNIT USAHA SYARIAH','SYTBIDJ1'],['PT. BANK SULSELBAR UNIT USAHA SYARIAH','SYWSIDJ1'],['PT. BANK SYARIAH BRI','DJARIDJ1'],['PT. BANK SYARIAH BUKOPIN','SDOBIDJ1'],['PT. BANK SYARIAH MANDIRI, Tbk','BSMDIDJA'],['PT. BANK TABUNGAN NEGARA (PERSERO)','BTANIDJA'],['PT. BANK TABUNGAN PENSIUNAN NASIONAL SYARIAH','PUBAIDJ1'],['PT. BANK TABUNGAN PENSIUNAN NASIONAL TBK','SUNIIDJA'],['PT. BANK UOB INDONESIA TBK','BBIJIDJA'],['PT. BANK VICTORIA INTERNATIONAL','VICTIDJ1'],['PT. BANK VICTORIA SYARIAH','SWAGIDJ1'],['PT. BANK WOORI SAUDARA INDONESIA 1906, TBK','BSDRIDJA'],['PT. BANK YUDHA BHAKTI','YUDBIDJ1'],['PT. BPD BALI','ABALIDBS'],['PT. BPD BANK KALIMANTAN TENGAH','PDKGIDJ1'],['PT. BPD BENGKULU','PDBKIDJ1'],['PT. BPD JAWA BARAT DAN BANTEN','PDJBIDJA'],['PT. BPD JAWA TENGAH','PDJGIDJ1'],['PT. BPD JAWA TIMUR','PDJTIDJ1'],['PT. BPD KALIMANTAN BARAT','PDKBIDJ1'],['PT. BPD KALIMANTAN SELATAN','PDKSIDJ1'],['PT. BPD MALUKU DAN MALUKU UTARA','PDMLIDJ1'],['PT. BPD NUSA TENGGARA BARAT SYARIAH','PDNBIDJ1'],['PT. BPD NUSA TENGGARA TIMUR','PDNTIDJ1'],['PT. BPD PAPUA','PDIJIDJ1'],['PT. BPD RIAU KEPRI','PDRIIDJA'],['PT. BPD SULAWESI SELATAN DAN SULAWESI BARAT','PDWSIDJA'],['PT. BPD SULAWESI TENGAH','PDWGIDJ1'],['PT. BPD SULAWESI TENGGARA','PDWRIDJ1'],['PT. BPD SULAWESI UTARA','PDWUIDJ1'],['PT. BPD SUMATERA SELATAN DAN BANGKA BELITUNG','BSSPIDSP'],['PT. BPD SUMATERA UTARA','PDSUIDJ1'],['PT. BPD SUMSEL DAN BABEL UNIT USAHA SYARIAH','SYSSIDJ1'],['PT. PANIN BANK Tbk.','PINBIDJA'],['PT.BANK OCBC NISP TBK - UNIT USAHA SYARIAH','SYONIDJ1'],['PT.BANK PEMBANGUNAN DAERAH JATIM - UNIT USAHA SYARIAH','SYJTIDJ1'],['PT.BANK PEMBANGUNAN DAERAH KALBAR UUS','SYKBIDJ1'],['PT.BANK PEMBANGUNAN DAERAH KALTIM - UNIT USAHA SYARIAH','SYKTIDJ1'],['PT.BPD KALTIM DAN KALTARA','PDKTIDJ1'],['STANDARD CHARTERED BANK','SCBLIDJX'],['THE BANGKOK BANK COMP, LTD','BKKBIDJA'],['PT. BANK RESONA PERDANIA','BPIAIDJA']]
      @bank_lists = DomBank.where(:status=>'active').order("bank_name asc").map { |e|  e.bank_name }

      @work_statuses = WorkStatus.all
      @departments = Department.all
      @currencies = Currency.all
      @positions = Position.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cash_submission_params
      params.require(:cash_submission).permit(
        :number, 
        :company_profile_id, 
        :department_id, 
        :currency_id,
        :date,
        :date_needed,
        :description,
        :amount,
        :receiver_name,
        :payment_method,
        :bank_name,
        :bank_number,
        :email_notification,
        :voucher_number,
        :transfer_date,
        :closing_date,
        :closing_number,
        :remarks, 
        :created_by, 
        :created_at, 
        :updated_by, 
        :updated_at, 
        :img_created_signature)
    end
end
