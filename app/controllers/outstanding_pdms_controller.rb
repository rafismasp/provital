class OutstandingPdmsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_instance_variable
  before_action :set_outstanding_pdm, only: [:show]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /outstanding_pdms
  # GET /outstanding_pdms.json
  def index
    pdm_items = @pdm_items

    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @records = pagy(pdm_items, page: params[:page], items: pagy_items)
  end

  # GET /outstanding_pdms/1
  # GET /outstanding_pdms/1.json
  def show
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end
  def print
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_outstanding_pdm
    end

    def set_instance_variable
      if params[:date_begin].present? and params[:date_end].present?
        session[:date_begin]  = params[:date_begin]
        session[:date_end]    = params[:date_end]
      elsif session[:date_begin].blank? and session[:date_end].blank?
        session[:date_begin]  = DateTime.now().at_beginning_of_month().strftime("%Y-%m-%d")
        session[:date_end]    = DateTime.now().at_end_of_month().strftime("%Y-%m-%d")
      end
      @pdm_items = PdmItem.where(:status=> 'active').where("pdm_items.outstanding > 0")
      .includes(material: [:unit])
      .includes(pdm: [:created, :updated, :approved1, :approved2, :approved3, :canceled1, :canceled2, :canceled3])
      .includes(purchase_order_supplier_items: [:purchase_order_supplier])
      .where(:pdms => {:company_profile_id=> current_user.company_profile_id, :status=> 'approved3', :date=> session[:date_begin].. session[:date_end]})
      .order("pdms.date desc")      
    end
end
