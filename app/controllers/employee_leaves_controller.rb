class EmployeeLeavesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_remove, only: [:destroy]

  # GET /inventories
  # GET /inventories.json
  def index
    periode_yyyy = (params[:periode_yyyy].present? ? params[:periode_yyyy] : DateTime.now().strftime("%Y"))
    employee_leaves = @employee_leaves.where("period = #{periode_yyyy}") 
  
    
    #@rejected_materials = RejectedMaterial.all
    
    # filter select - begin
      @option_filters = [['Doc.Status','status'],['Nama Karyawan','employee_id']] 
      @option_filter_records = employee_leaves

      if params[:filter_column].present?
        case params[:filter_column] 
        when 'employee_id'
          @option_filter_records = Employee.where(:company_profile_id=> current_user.company_profile_id, :employee_status=> 'Aktif').order("name asc")
        end

       employee_leaves = employee_leaves.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end

    # filter select - end
  
    # @material_outgoing_items = MaterialOutgoingItem.where(:material_outgoing_id=> params[:material_outgoing_id]) if params[:material_outgoing_id].present?

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))
    @pagy, @employee_leaves = pagy(employee_leaves, page: params[:page], items: pagy_items)
  end

  def export
    periode_yyyy = (params[:periode_yyyy].present? ? params[:periode_yyyy] : DateTime.now().strftime("%Y"))
    template_report(controller_name, current_user.id, periode_yyyy)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instance_variable
      
      @employee_leaves = EmployeeLeave.where(:status=>'active') 
    end
end
