class SupplierApRecapsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_remove, only: [:destroy]

  # GET /inventories
  # GET /inventories.json
  def index

  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instance_variable
      periode_yyyy = (params[:periode_yyyy].present? ? params[:periode_yyyy] : DateTime.now().strftime("%Y"))
      @records = SupplierApRecap.where("periode between ? and ?", "#{periode_yyyy}01", "#{periode_yyyy}12").includes(:supplier).order("suppliers.name asc, supplier_ap_recaps.periode asc")
      
      @records.each do |record|
        period_begin = "#{record.periode.to_s[0..3]}-#{record.periode.to_s[4..5]}-01".to_date.at_beginning_of_month()
        period_end   = "#{record.periode.to_s[0..3]}-#{record.periode.to_s[4..5]}-01".to_date.at_end_of_month()
        logger.info "period_begin: #{period_begin}"
        logger.info "period_end: #{period_end}"
        sum_payment = PaymentSupplier.where(:company_profile_id=> record.company_profile_id, :supplier_id=> record.supplier_id, :date=> period_begin .. period_end, :status=> 'approved3').sum(:grandtotal)
        logger.info "sum_payment: #{sum_payment}"
        record.update(:payment=> sum_payment)
        
      end
      
      @records = SupplierApRecap.where("periode between ? and ?", "#{periode_yyyy}01", "#{periode_yyyy}12").includes(:supplier).order("suppliers.name asc, supplier_ap_recaps.periode asc")
      
      
    end

end
