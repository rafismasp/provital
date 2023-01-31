class RoutineCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_routine_cost, only: [:show, :edit, :update, :destroy, :approve]
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

  # GET /routine_costs
  # GET /routine_costs.json
  def index
    if params[:date_begin].present? and params[:date_end].present?
      session[:date_begin]  = params[:date_begin]
      session[:date_end]    = params[:date_end]
    elsif session[:date_begin].blank? and session[:date_end].blank?
      session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
      session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
    end

    routine_costs = RoutineCost.where("date between ? and ?", session[:date_begin], session[:date_end]).order_as_specified(status: ['new','canceled1','canceled2','canceled3','approved1','approved2','approved3','deleted','void']).order("approved3_at desc")
    
    # filter select - begin
      @option_filters = [['Doc.Number','number'],['Doc.Status','status']] 
      @option_filter_records = routine_costs

      if params[:filter_column].present?
       routine_costs = routine_costs.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    # filter select - end


    logger.info "==========================="
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @routine_costs = pagy(routine_costs, page: params[:page], items: pagy_items)
  end

  # GET /routine_costs/1
  # GET /routine_costs/1.json
  def show
    @record_files = RoutineCostFile.where(:routine_cost_id=>params[:id],:status=>"active")
  end

  # GET /routine_costs/new
  def new
    @routine_cost = RoutineCost.new

  end

  # GET /routine_costs/1/edit
  def edit
    @record_files = RoutineCostFile.where(:routine_cost_id=>params[:id],:status=>"active")
  end

  # POST /routine_costs
  # POST /routine_costs.json
  def create
    params[:routine_cost]["company_profile_id"] = current_user.company_profile_id
    params[:routine_cost]["created_by"] = current_user.id
    params[:routine_cost]["created_at"] = DateTime.now()
    params[:routine_cost]["number"] = document_number(controller_name, DateTime.now(), params[:routine_cost]["department_id"], nil, nil)
    logger.info params[:routine_cost]
    @routine_cost = RoutineCost.new(routine_cost_params)

    respond_to do |format|
      if @routine_cost.save

        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = RoutineCostFile.where(:routine_cost_id=>@routine_cost.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/routine_cost/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                RoutineCostFile.create({
                  :routine_cost_id=> @routine_cost.id,
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

        format.html { redirect_to @routine_cost, notice: 'Routine Cost was successfully created.' }
        format.json { render :show, status: :created, location: @routine_cost }
      else
        format.html { render :new }
        format.json { render json: @routine_cost.errors, status: :unprocessable_entity }
      end
      logger.info @routine_cost.errors
    end
  end
  def update
    params[:routine_cost]["updated_by"] = current_user.id
    params[:routine_cost]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @routine_cost.update(routine_cost_params)   
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            hash = Digest::MD5.hexdigest(content)
            fid = RoutineCostFile.where(:routine_cost_id=>@routine_cost.id)
            pf = fid.find_by(:file_hash=>hash)
            if pf.blank?
              filename_original = DateTime.now().strftime("%Y-%m-%d %H:%M:%S")+" "+many_files[:attachment].original_filename
              ext=File.extname(filename_original)
              filename=DateTime.now.strftime("%Y-%m-%d_%H-%M-%S_") + hash + ext
              dir = "public/uploads/routine_cost/"
              FileUtils.mkdir_p(dir) unless File.directory?(dir) # cek directory, buat baru jika tidak ada
              path = File.join(dir, "#{hash}#{ext}")
              tmp_path_filename=File.join('/tmp', filename)
              File.open(path, 'wb') do |file|
                file.write(content)
                RoutineCostFile.create({
                  :routine_cost_id=> @routine_cost.id,
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
          file = RoutineCostFile.find_by(:id=> item["id"].to_s)
          case item["status"]
          when 'deleted'
            file.update_columns({
              :status=> item["status"],
              :deleted_at=> DateTime.now(), :deleted_by=> current_user.id
            })
          end
        end if params["record_file"].present?

        format.html { redirect_to routine_cost_path(:id=> @routine_cost.id), notice: "#{@routine_cost.number} was successfully Updated" }
        format.json { render :show, status: :created, location: @routine_cost }     
      else
        format.html { render :edit }
        format.json { render json: @routine_cost.errors, status: :unprocessable_entity }
      end
    end
  end

  def approve
   # pdm = RoutineCost.where(:company_profile_id=> current_user.company_profile_id, :routine_cost_id=> @routine_cost.id)
    
    case params[:status]
    when 'void'
      @routine_cost.update({:status=> 'void', :voided_by=> current_user.id, :voided_at=> DateTime.now()}) 
    when 'cancel_void'
      @routine_cost.update({:status=> 'new'}) 
    when 'approve1'
      @routine_cost.update({:status=> 'approved1', :approved1_by=> current_user.id, :approved1_at=> DateTime.now()}) 
    when 'cancel_approve1'
      @routine_cost.update({:status=> 'canceled1', :canceled1_by=> current_user.id, :canceled1_at=> DateTime.now()}) 
    when 'approve2'
      @routine_cost.update({:status=> 'approved2', :approved2_by=> current_user.id, :approved2_at=> DateTime.now()}) 
    when 'cancel_approve2'
      @routine_cost.update({:status=> 'canceled2', :canceled2_by=> current_user.id, :canceled2_at=> DateTime.now()})
    when 'approve3'
      cari = RoutineCost.where(:id=>(params[:multi_id].present? ? params[:multi_id] : params[:id]))
      cari.each do |record|
        case record.interval.to_s
        when 'annual'
          tahun = Time.now().strftime("%Y")
          bulan = record.payment_time
          hari = "01"
          tanggal = ("#{tahun}-#{bulan}-#{hari}").to_date
          puts tanggal
          interval_date = tanggal
        when 'monthly'
          tahun = Time.now().strftime("%Y")
          bulan = Time.now().strftime("%m")
          hari = record.payment_time
          end_of_month = Time.now().at_end_of_month().strftime("%d")
          if hari.to_i > end_of_month.to_i
            hari = end_of_month
          end

          logger.info "tanggal: #{tahun}-#{bulan}-#{hari}"
          tanggal = ("#{tahun}-#{bulan}-#{hari}").to_date
          puts tanggal
          interval_date = tanggal
        when 'weekly'
          tanggal  = Date.parse(record.payment_time)
          puts tanggal
          interval_date = tanggal
        end

        case record.interval.to_s
        when 'weekly'
          4.times.each do |r|
            RoutineCostInterval.create({
              :routine_cost_id=>record.id,
              :company_profile_id => record.company_profile_id,
              :date=> interval_date,
              :status=> "open",
              :created_at=> DateTime.now(),
              :updated_at=> DateTime.now()
            }) if interval_date <= record.end_contract
            interval_date +=7.days
          end
        else
          RoutineCostInterval.create({
            :routine_cost_id=>record.id,
            :company_profile_id => record.company_profile_id,
            :date=> interval_date,
            :status=> "open",
            :created_at=> DateTime.now(),
            :updated_at=> DateTime.now()
          })
        end
      end
      
      @routine_cost.update({:status=> 'approved3', :approved3_by=> current_user.id, :approved3_at=> DateTime.now()}) 
    when 'cancel_approve3'
      @routine_cost.update({:status=> 'canceled3', :canceled3_by=> current_user.id, :canceled3_at=> DateTime.now()})
      RoutineCostInterval.where(:routine_cost_id=> @routine_cost.id, :status=> 'open').each do |item|
        item.update({:status=> 'closed'})
      end
    end
    if params[:multi_id].present?
      respond_to do |format|
        format.html { redirect_to routine_costs_url, notice: 'Successfully App3' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to routine_cost_path(:id=> @routine_cost.id), notice: "Routine Cost was successfully #{@routine_cost.status}." }
        format.json { head :no_content }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end
  
  # DELETE /routine_costs/1
  # DELETE /routine_costs/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to routine_costs_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def check_status
    if @routine_cost.status == 'approved3'
      respond_to do |format|
        format.html { redirect_to @routine_cost, notice: 'Cannot be edited because it has been approved' }
        format.json { render :show, status: :created, location: @routine_cost }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_routine_cost
      if params[:multi_id].present?
        @routine_cost = RoutineCost.where(:id=> params[:multi_id].split(','))
      else
        @routine_cost = RoutineCost.find_by(:id=> params[:id])
      end

      if @routine_cost.present?
        # @delivery_order_items = DeliveryOrderItem.where(:status=> 'active').includes(:routine_cost).where(:routine_costs => {:id=> params[:id], :company_profile_id => current_user.company_profile_id }).order("routine_costs.number desc")
      else
        respond_to do |format|
          format.html { redirect_to routine_costs_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @routine_costs = RoutineCost.where(:company_profile_id=> current_user.company_profile_id)
      @routine_cost_interval = RoutineCostInterval.where(:company_profile_id=> current_user.company_profile_id)
      @work_statuses = WorkStatus.all
      @departments = Department.all
      @positions = Position.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def routine_cost_params
      params.require(:routine_cost).permit(:number, :company_profile_id, :department_id, :date, :remarks, :cost_name, :interval,:nominal_type, :amount, :payment_time, :end_contract, :created_by, :created_at, :updated_by, :updated_at, :img_created_signature)
    end
end
