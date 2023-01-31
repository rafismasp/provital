class SpreadsheetReportsController < ApplicationController
  before_action :set_spreadsheet_report, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /spreadsheet_reports
  # GET /spreadsheet_reports.json
  def index
    @spreadsheet_reports = SpreadsheetReport.all
    permission_base = PermissionBase.find_by(:id=> params[:permission_base_id])
    if permission_base.present?
      
      case permission_base.tbl_kind
      when "items"
        tbl_name = "#{permission_base.link}".singularize.gsub("/", "")+"_items"
      else
        tbl_name = "#{permission_base.link}".gsub("/", "")
      end
      puts tbl_name
      @column_lists = tbl_name.singularize.camelize.constantize.column_names
    end
  end

  # GET /spreadsheet_reports/1
  # GET /spreadsheet_reports/1.json
  def show
  end

  # GET /spreadsheet_reports/new
  def new
    @spreadsheet_report = SpreadsheetReport.new
  end

  # GET /spreadsheet_reports/1/edit
  def edit
  end

  # POST /spreadsheet_reports
  # POST /spreadsheet_reports.json
  def create
    params[:spreadsheet_report]["created_at"] = DateTime.now()
    params[:spreadsheet_report]["created_by"] = current_user.id
    @spreadsheet_report = SpreadsheetReport.new(spreadsheet_report_params)

    respond_to do |format|
      if @spreadsheet_report.save
        params[:new_record_item].each do |item|
          transfer_item = SpreadsheetContent.create({
            :sequence_number=> item["sequence_number"],
            :spreadsheet_report_id=> @spreadsheet_report.id,
            :status=> item["status"],
            :name=> item["name"],
            :created_at=> DateTime.now(), :created_by=> current_user.id
          })
        end if params[:new_record_item].present?

        format.html { redirect_to @spreadsheet_report, notice: 'SpreadsheetReport was successfully created.' }
        format.json { render :show, status: :created, location: @spreadsheet_report }
      else
        format.html { render :new }
        format.json { render json: @spreadsheet_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spreadsheet_reports/1
  # PATCH/PUT /spreadsheet_reports/1.json
  def update
    respond_to do |format|
      if @spreadsheet_report.update(spreadsheet_report_params)
        params[:spreadsheet_content].each do |item|
          transfer_item = SpreadsheetContent.find_by(:id=> item[:id]) 
          transfer_item.update_columns({
            :sequence_number=> item["sequence_number"],
            :status=> item["status"],
            :updated_at=> DateTime.now(), :updated_by=> current_user.id
          })
        end if params[:spreadsheet_content].present?
        format.html { redirect_to @spreadsheet_report, notice: 'SpreadsheetReport was successfully updated.' }
        format.json { render :show, status: :ok, location: @spreadsheet_report }
      else
        format.html { render :edit }
        format.json { render json: @spreadsheet_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spreadsheet_reports/1
  # DELETE /spreadsheet_reports/1.json
  def destroy
    @spreadsheet_report.destroy
    respond_to do |format|
      format.html { redirect_to spreadsheet_reports_url, notice: 'SpreadsheetReport was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spreadsheet_report
      @spreadsheet_report = SpreadsheetReport.find(params[:id])
      @spreadsheet_contents = SpreadsheetContent.where(:spreadsheet_report_id=> params[:id])
    end

    def set_instance_variable
      @feature_lists = PermissionBase.where(:status=> 'active', :spreadsheet_status=> 'Y')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def spreadsheet_report_params
      params.require(:spreadsheet_report).permit(:name, :permission_base_id, :created_at, :created_by, :updated_by, :updated_at)
    end
end
