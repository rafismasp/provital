class SupplierApSummariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_remove, only: [:destroy]

  # GET /inventories
  # GET /inventories.json
  def index
    @invoice_supplier_receiving_items = @records
    @invoice_supplier_receiving_items = @records.where(:id=> params[:invoice_supplier_id]) if params[:invoice_supplier_id].present?
  end
  
  def new
  end

  # GET /inventories/1
  # GET /inventories/1.json
  def show
  end

  def create
    params[:invoice_supplier_receiving_item].each do |record|
      item = InvoiceSupplierReceivingItem.find_by(:id=> record[:id])
      if item.present?
        item.update_columns({
          :due_date_checked1=> record[:due_date_checked1], :date_checked1=> record[:date_checked1], :note_checked1=> record[:note_checked1],
          :date_receive_checked2=> record[:date_receive_checked2], :due_date_checked2=> record[:due_date_checked2], :date_checked2=> record[:date_checked2], :note_checked2=> record[:note_checked2],
          :date_receive_checked3=> record[:date_receive_checked3], :due_date_checked3=> record[:due_date_checked3], :date_checked3=> record[:date_checked3], :note_checked3=> record[:note_checked3],
          :date_receive_checked4=> record[:date_receive_checked4], :due_date_checked4=> record[:due_date_checked4], :date_checked4=> record[:date_checked4], :note_checked4=> record[:note_checked4],
          :date_receive_checked5=> record[:date_receive_checked5], :due_date_checked5=> record[:due_date_checked5], :date_checked5=> record[:date_checked5], :note_checked5=> record[:note_checked5],
          :date_payment=> record[:date_payment], :remarks=> record[:remarks], :amount_payment=> record[:amount_payment], :completeness_dc=> record[:completeness_dc]
        })
        amount_payment = record[:amount_payment]
        create_supplier_ap_recap(item.invoice_date.to_date.strftime("%Y%m"), item.invoice_supplier_receiving.supplier, amount_payment, item, item.supplier_tax_invoice_id, item.id)
        
      end
    end
    respond_to do |format|
      format.html { redirect_to "/supplier_ap_summaries", notice: "Successfull." }
      format.json { head :no_content }
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instance_variable

      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @records = InvoiceSupplierReceivingItem.where(:status=> 'active').includes(:invoice_supplier_receiving).where(:invoice_supplier_receivings => {:company_profile_id => current_user.company_profile_id }).where("invoice_supplier_receivings.date between ? and ?", session[:date_begin], session[:date_end]).order("invoice_supplier_receivings.number desc") 
    
    end
    def record_params
      params.permit(
        :due_date_checked1,
        :date_checked1,
        :note_checked1,
        :id, :date_receive_checked2, :due_date_checked2, :date_checked2, :note_checked2, 
        :date_receive_checked3, :due_date_checked3, :date_checked3, :note_checked3, 
        :date_receive_checked4, :due_date_checked4, :date_checked4, :note_checked4,
        :date_receive_checked5, :due_date_checked5, :date_checked5, :note_checked5, 
        :date_payment, :remarks, :amount_payment, :completeness_dc
      ).except(:utf8, :authenticity_token, :invoice_supplier_receiving_item, :commit)

    end
end
