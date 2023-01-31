class DepartmentHierarchiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_department_hierarchy, only: [:show, :edit, :update, :destroy, :approve, :print]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]

  def index
    session[:date_begin] = (params[:date_begin].present? ? params[:date_begin] : DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d"))
    session[:date_end]   = (params[:date_end].present? ? params[:date_end] : DateTime.now().at_end_of_month().strftime("%Y-%m-%d"))
    department_hierarchies = DepartmentHierarchy.where(:company_profile_id=> current_user.company_profile_id).order('id desc')

    # filter select - begin
      @option_filters = [['Department','department_id']] 
      @option_filter_records = department_hierarchies

       if params[:filter_column].present?
        case params[:filter_column] 
        when 'department_id'
          @option_filter_records = @departments
        end

        department_hierarchies = department_hierarchies.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @department_hierarchies = pagy(department_hierarchies, page: params[:page], items: pagy_items)

    #------------------------------------------------------------------------------
  end

  def show
  end

  def new
    @department_hierarchy = DepartmentHierarchy.new
  end

  def edit
  end

  def create
    params[:department_hierarchy]["company_profile_id"] = current_user.company_profile_id
    params[:department_hierarchy]["created_by"] = current_user.id
    params[:department_hierarchy]["created_at"] = DateTime.now()
    @department_hierarchy = DepartmentHierarchy.new(department_hierarchy_params)

    respond_to do |format|
      if @department_hierarchy.save
        format.html { redirect_to @department_hierarchy, notice: 'Document was successfully created.' }
        format.json { render :show, status: :created, location: @department_hierarchy }
      else
        puts @department_hierarchy.errors.full_messages
        format.html { render :new }
        format.json { render json: @department_hierarchy.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    params[:department_hierarchy]["updated_by"] = current_user.id
    params[:department_hierarchy]["updated_at"] = DateTime.now()
    respond_to do |format|
      if @department_hierarchy.update(department_hierarchy_params)
        format.html { redirect_to @department_hierarchy, notice: 'Document was successfully updated.' }
        format.json { render :show, status: :ok, location: @department_hierarchy }
      else
        format.html { render :edit }
        format.json { render json: @department_hierarchy.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_department_hierarchy
      @department_hierarchy = DepartmentHierarchy.find_by(:id=> params[:id])
      if !@department_hierarchy.present?
        respond_to do |format|
          format.html { redirect_to department_hierarchies, alert: 'record not found!' }
          format.json { head :no_content }
        end
      end
    end

    def set_instance_variable
      @employees = Employee.where(:employee_status=>'Aktif').order("name asc").includes(:department, :position)
      @departments = Department.where(:status=>'active').order('name asc')
      @accounts = User.where(:status=>'active')
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def department_hierarchy_params
      params.require(:department_hierarchy).permit(:department_id, :approved1_by, :cancel1_by, :approved2_by, :cancel2_by, :approved3_by, :cancel3_by, :void_by, :created_by, :created_at, :updated_by, :updated_at)
    end
end
