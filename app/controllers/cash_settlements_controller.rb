class CashSettlementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cash_settlement, only: [:show, :edit, :update, :destroy, :approve]
  before_action :check_status, only: [:edit]
  before_action :set_instance_variable
  before_action :get_open_cash_submissions, only: [:index, :new]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  before_action only: [:approve] do
    require_permission_approve(params[:status])
  end

  # GET /cash_settlements
  # GET /cash_settlements.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    cash_settlements = CashSettlement.where("date between ? and ?", session[:date_begin], session[:date_end]).order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("approved3_at desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']] 
      @option_filter_records = cash_settlements

      if params[:filter_column].present?
       cash_settlements = cash_settlements.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

      cash_settlements = cash_settlements.order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void'])
    # filter select - end

    logger.info "==========================="
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @cash_settlements = pagy(cash_settlements, page: params[:page], items: pagy_items)
  end

  # GET /cash_settlements/1
  # GET /cash_settlements/1.json
  def show
  end

  # GET /cash_settlements/new
  def new
    @cash_settlement = CashSettlement.new
  end

  # GET /cash_settlements/1/edit
  def edit
  end

  # POST /cash_settlements
  # POST /cash_settlements.json
  def create
    params[:cash_settlement]["company_profile_id"] = current_user.company_profile_id
    params[:cash_settlement]["created_by"] = current_user.id
    params[:cash_settlement]["created_at"] = DateTime.now()
    if params[:cash_settlement]["advantage"].to_f > 0 
      inout = "IN"
    elsif params[:cash_settlement]["advantage"].to_f < 0
      inout = "OUT"
    else
      inout = "PAS"
    end
    params[:cash_settlement]["number"] = document_number(controller_name, DateTime.now(), params[:cash_settlement]["department_id"], inout, nil)
    logger.info params[:cash_settlement]
    @cash_settlement = CashSettlement.new(cash_settlement_params)

    respond_to do |format|
      if @cash_settlement.save
        @cash_settlement.cash_submission.update_columns({:status_bon=>"close"})

        params["cash_settlement_item"].each do |item|
          wawa = CashSettlementItem.new({
            :bon_count=> item["bon_count"],
            :payment_type=> item["payment_type"],
            :cash_settlement_id=> @cash_settlement.id,
            :coa_name=> item["coa_name"],
            :payment_name=> item["payment_name"],
            :description=> item["description"],
            :amount=> item["amount"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          wawa.save
        end if params["cash_settlement_item"].present?

        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = CashSettlementFile.where(:cash_settlement_id => @cash_settlement.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/cash_settlement/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                CashSettlementFile.create({
                  :transfer_proof=>1,
                  :cash_settlement_id=> @cash_settlement.id,
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

        if params[:cash_settlement_file].present?
          params["cash_settlement_file"].each do |bon_files|
            require 'base64'
            if bon_files[:attachment].present?
              images = bon_files[:attachment]
              ext = images.split("/")[1].split(";")[0]
              mime_type = Rack::Mime.mime_type(".#{ext}")
              filename = ( "BON-#{@cash_settlement.id}-#{bon_files[:bon_count]}-#{DateTime.now()}.#{ext}")
              metadata = "data:#{mime_type};base64,"
              base64_string = images[metadata.size..-1]
              blob = Base64.decode64(base64_string)

              
              path_file = ("public/uploads/cash_settlement/#{filename}")
                    
              File.open(path_file, 'wb') do |file|
                file.write(blob)
                hash = Digest::MD5.hexdigest(blob)
              end
              CashSettlementFile.create({
                  :transfer_proof=>0,
                  :bon_count=>bon_files[:bon_count],
                  :cash_settlement_id=> @cash_settlement.id,
                  :filename_original=>filename,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path_file,
                  :ext=> ".#{ext}",
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })
            end
          end
        end

        format.html { redirect_to @cash_settlement, notice: 'Routine Cost Payment was successfully created.' }
        format.json { render :show, status: :created, location: @cash_settlement }
      else
        format.html { render :new }
        format.json { render json: @cash_settlement.errors, status: :unprocessable_entity }
      end
      logger.info @cash_settlement.errors
    end
  end

  def update
    params[:cash_settlement]["updated_by"] = current_user.id
    params[:cash_settlement]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @cash_settlement.update(cash_settlement_params)   
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = CashSettlementFile.where(:cash_settlement_id=>@cash_settlement.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/cash_settlement/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                CashSettlementFile.create({
                  :transfer_proof=>1,
                  :cash_settlement_id=> @cash_settlement.id,
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

        if params[:cash_settlement_file].present?
          params["cash_settlement_file"].each do |bon_files|
            require 'base64'
            if bon_files[:attachment].present?
              images = bon_files[:attachment]
              ext = images.split("/")[1].split(";")[0]
              mime_type = Rack::Mime.mime_type(".#{ext}")
              filename = ( "BON-#{@cash_settlement.id}-#{bon_files[:bon_count]}-#{DateTime.now()}.#{ext}")
              metadata = "data:#{mime_type};base64,"
              base64_string = images[metadata.size..-1]
              blob = Base64.decode64(base64_string)

              
              path_file = ("public/uploads/cash_settlement/#{filename}")
                    
              File.open(path_file, 'wb') do |file|
                file.write(blob)
                hash = Digest::MD5.hexdigest(blob)
              end
              CashSettlementFile.create({
                  :transfer_proof=>0,
                  :bon_count=>bon_files[:bon_count],
                  :cash_settlement_id=> @cash_settlement.id,
                  :filename_original=>filename,
                  :file_hash=> hash ,
                  :filename=> filename,
                  :path=> path_file,
                  :ext=> ".#{ext}",
                  :created_at=> DateTime.now,
                  :created_by=> session[:id]
                })
            end
          end
        end

        params["record_file"].each do |item|
          file = CashSettlementFile.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            file.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          end
        end if params["record_file"].present?

        params["cash_settlement_item"].each do |item|
          wawa = CashSettlementItem.new({
            :bon_count=> item["bon_count"],
            :payment_type=> item["payment_type"],
            :cash_settlement_id=> @cash_settlement.id,
            :coa_name=> item["coa_name"],
            :payment_name=> item["payment_name"],
            :description=> item["description"],
            :amount=> item["amount"],
            :status=> 'active',
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
          wawa.save
        end if params["cash_settlement_item"].present?
        

        params["record_item"].each do |item|
          payment_item = CashSettlementItem.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            payment_item = CashSettlementItem.where(:bon_count=> item["bon_count"].to_s)
            payment_item.update({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          else
            payment_item.update_columns({
              :payment_type=> item["payment_type"],
              :cash_settlement_id=> @cash_settlement.id,
              :coa_name=> item["coa_name"],
              :payment_name=> item["payment_name"],
              :description=> item["description"],
              :amount=> item["amount"]
            })

          end if payment_item.present?
        end if params["record_item"].present?

        format.html { redirect_to cash_settlement_path(:id=> @cash_settlement.id), notice: "#{@cash_settlement.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @cash_settlement }     
      else
        format.html { render :edit }
        format.json { render json: @cash_settlement.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve    
    case params[:status]
    when 'void'
      @cash_settlement.update_columns({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()}) 
    when 'cancel_void'
      @cash_settlement.update_columns({:status=> 'new'}) 
    when 'approve1'
      @cash_settlement.update_columns({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @cash_settlement.update_columns({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @cash_settlement.update_columns({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @cash_settlement.update_columns({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      @cash_settlement.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @cash_settlement.update_columns({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
    end
    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to cash_settlements_url, alert: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to cash_settlement_path(:id=> @cash_settlement.id), notice: "Routine Cost was successfully #{@cash_settlement.status}." }
        format.json { head :no_content }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  # DELETE /cash_settlements/1
  # DELETE /cash_settlements/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to cash_settlements_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status
    if @cash_settlement.status == 'approved3'
      respond_to do |format|
        format.html { redirect_to @cash_settlement, notice: 'Cannot be edited because it has been approved' }
        format.json { render :show, status: :created, location: @cash_settlement }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cash_settlement
      if params[:multi_id].present?
        @cash_settlement = CashSettlement.where(:id=> params[:multi_id].split(','))
        if @cash_settlement.present?
          # nothing
        else
          respond_to do |format|
            format.html { redirect_to cash_settlements_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      else
        @cash_settlement = CashSettlement.find_by(:id=> params[:id])
        if @cash_settlement.present?
          @cash_submissions = CashSubmission.where(:company_profile_id=> current_user.company_profile_id, :department_id=> @cash_settlement.department_id, :status=>'approved3')
          @record_files = CashSettlementFile.where(:cash_settlement_id=>params[:id],:status=>"active").where(:transfer_proof=>1)
          @cash_settlement_items = CashSettlementItem.where(:status=> 'active').includes(:cash_settlement).where(:cash_settlements => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("cash_settlements.number desc")
        else
          respond_to do |format|
            format.html { redirect_to cash_settlements_url, alert: 'record not found!' }
            format.json { head :no_content }
          end
        end
      end
    end

    def set_instance_variable
      @cash_settlements = CashSettlement.where(:company_profile_id=> current_user.company_profile_id)

      @bank_transfers = BankTransfer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active')

      @work_statuses = WorkStatus.all
      @departments = Department.all
      @positions = Position.all

      get_cash_submissions(nil)
    end

    def get_open_cash_submissions
      get_cash_submissions("open")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cash_settlement_params
      params.require(:cash_settlement).permit(
        :cash_submission_id,
        :number, 
        :company_profile_id, 
        :department_id, 
        :date, 
        :remarks, 
        :grand_total, 
        :voucher_number, 
        :settlement_total,
        :expenditure_total,
        :advantage,
        :bank_transfer_id,
        :date_return,
        :remarks,
        :description,
        :created_by, 
        :created_at, 
        :updated_by, 
        :updated_at, 
        :img_created_signature)
    end

    def get_cash_submissions(status_bon)
      @cash_submission = CashSubmission.find_by(:id=> params[:cash_submission_id])

      @cash_submissions = CashSubmission.where(:company_profile_id=> current_user.company_profile_id,:status=>'approved3').includes(:currency)

      if status_bon == 'open'
        @cash_submissions = @cash_submissions.where(:status_bon=>"open")
      end
      
      if @cash_submission.present?
        @cash_submissions = @cash_submissions.where(:department_id=> @cash_submission.department_id)
        if @cash_submission.status_bon == 'close'
          flash[:alert] = "#{@cash_submission.number} is close"
          @cash_submission = nil
        end
      else
        @cash_submissions = @cash_submissions.where(:department_id=>params[:select_department_id]) if params[:select_department_id].present?
      end
    end
end
