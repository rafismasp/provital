class MasterFilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable
  before_action :set_master_file, only: [:show, :edit, :update, :destroy, :approve, :print]

  include UserPermissionsHelper

  before_action :require_permission_view, only: [:index], unless: -> { params[:myaccount].present? }
  before_action :require_permission_edit, only: [:edit]
  before_action :require_permission_create, only: [:create]
  include InvoiceToolsHelper

  # GET /master_files
  # GET /master_files.json
  def index    
    master_files = MasterFile.where(:company_profile_id=> current_user.company_profile_id, :status=>"active")

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @master_files = pagy(master_files, page: params[:page], items: pagy_items) 
  end


  def new
    @master_file = MasterFile.new
  end

  def show
    # @master_file = MasterFile.find(params[:id])
    @record_files = CdnSysFile.where(:controller=>params[:controller], :provital_id=>params[:id]).order("status asc, id desc")
  end

  def edit
    # @master_file = MasterFile.find(params[:id])
    @record_files = CdnSysFile.where(:controller=>params[:controller], :provital_id=>params[:id]).order("status asc, id desc")

  end

  def create
    params[:master_file]["company_profile_id"] = current_user.company_profile_id
    params[:master_file]["created_by"] = current_user.id
    params[:master_file]["created_at"] = DateTime.now()

    logger.info params[:master_file]
    @master_file = MasterFile.new(master_file_params)

    respond_to do |format|
      if @master_file.save
        if params[:file].present?
          params["file"].each do |many_files|
            content =  many_files[:attachment].read
            my_hash = Digest::MD5.hexdigest(content)
            filename_original =many_files[:attachment].original_filename.downcase
            ext = File.extname(filename_original)  
            filename = "#{@master_file.id}_#{my_hash}#{ext}" 
            mime_type = Rack::Mime.mime_type(ext)
            base64 = Base64.strict_encode64(content)
            base64_full = "data:#{mime_type};base64,#{Base64.encode64(content)}"
            
            cdn_file = CdnSysFile.create({
              :provital_id=> @master_file.id,
              :controller=>params[:controller],
              :tbl=>nil,
              :filename_original=> filename_original,
              :filename=> filename,
              :path=> nil,
              :ext=> ext,
              :base64_full=> base64_full,
              :status=> 'active',
              :created_by=> current_user.id, :created_at=> DateTime.now(),
              :updated_by=> current_user.id, :updated_at=> DateTime.now()
            })
            @master_file.update({:cdn_sys_file_id=>cdn_file.id})

            logger.info(cdn_file.errors)
          end  
        else
         flash[:error]='Berhasil Tersimpan Tanpa Lampiran!'
        end

        format.html { redirect_to @master_file, notice: 'Master File was successfully created.' }
        format.json { render :show, status: :created, location: @master_file }
      else
        format.html { render :new }
        format.json { render json: @master_file.errors, status: :unprocessable_entity }
      end
      logger.info @master_file.errors
    end
  end

  def update
    params[:master_file]["company_profile_id"] = current_user.company_profile_id
    params[:master_file]["updated_by"] = current_user.id
    params[:master_file]["updated_at"] = DateTime.now()

    logger.info params[:master_file]

    respond_to do |format|
      if @master_file.update(master_file_params)
        if params[:file].present?
          params["file"].each do |many_files|
            old_file = CdnSysFile.where(:provital_id=> @master_file.id, :controller=>params[:controller])
            old_file.update_all({:status=> 'suspend', :note=> 'Suspend'}) if old_file.present?

            content =  many_files[:attachment].read
            my_hash = Digest::MD5.hexdigest(content)
            filename_original =many_files[:attachment].original_filename.downcase
            ext = File.extname(filename_original)  
            filename = "#{@master_file.id}_#{my_hash}#{ext}" 
            mime_type = Rack::Mime.mime_type(ext)
            base64 = Base64.strict_encode64(content)
            base64_full = "data:#{mime_type};base64,#{Base64.encode64(content)}"
            
            cdn_file = CdnSysFile.create({
              :provital_id=> @master_file.id,
              :controller=>params[:controller],
              :tbl=>nil,
              :filename_original=> filename_original,
              :filename=> filename,
              :path=> nil,
              :ext=> ext,
              :base64_full=> base64_full,
              :status=> 'active',
              :created_by=> current_user.id, :created_at=> DateTime.now(),
              :updated_by=> current_user.id, :updated_at=> DateTime.now()
            })
            @master_file.update({:cdn_sys_file_id=>cdn_file.id})

            logger.info(cdn_file.errors)
          end  
        else
         flash[:error]='Berhasil Tersimpan Tanpa Lampiran!'
        end

        format.html { redirect_to @master_file, notice: 'Master File was successfully created.' }
        format.json { render :show, status: :created, location: @master_file }
      else
        format.html { render :new }
        format.json { render json: @master_file.errors, status: :unprocessable_entity }
      end
      logger.info @master_file.errors
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_master_file
      @master_file = MasterFile.find(params[:id])

      if @master_file.present?
         
      else
        respond_to do |format|
          format.html { redirect_to master_files_url, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def master_file_params
      params.require(:master_file).permit(:name, :file, :created_at, :created_by, :updated_at, :updated_by)
    end
end
