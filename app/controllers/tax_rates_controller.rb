class TaxRatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax_rate, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /tax_rates
  # GET /tax_rates.json
  def index
    tax_rates = TaxRate.all
    # filter select - begin
      @option_filters = [['Currency', 'currency_id']] 
      @option_filter_records = tax_rates
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        end

        tax_rates = tax_rates.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    @tax_rates = tax_rates
  end

  # GET /tax_rates/1
  # GET /tax_rates/1.json
  def show
  end

  # GET /tax_rates/new
  def new
    @tax_rate = TaxRate.new
  end

  # GET /tax_rates/1/edit
  def edit
  end

  # POST /tax_rates
  # POST /tax_rates.json
  def create
    params[:tax_rate]["created_by"] = current_user.id
    params[:tax_rate]["created_at"] = DateTime.now()
    @tax_rate = TaxRate.new(tax_rate_params)

    respond_to do |format|
      if @tax_rate.save
        format.html { redirect_to @tax_rate, notice: 'Tax rate was successfully created.' }
        format.json { render :show, status: :created, location: @tax_rate }
      else
        format.html { render :new }
        format.json { render json: @tax_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tax_rates/1
  # PATCH/PUT /tax_rates/1.json
  def update
    respond_to do |format|
      params[:tax_rate]["updated_by"] = current_user.id
      params[:tax_rate]["updated_at"] = DateTime.now()
      if @tax_rate.update(tax_rate_params)
        format.html { redirect_to @tax_rate, notice: 'Tax rate was successfully updated.' }
        format.json { render :show, status: :ok, location: @tax_rate }
      else
        format.html { render :edit }
        format.json { render json: @tax_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  def export
    template_report(controller_name, current_user.id, nil)
  end

  # DELETE /tax_rates/1
  # DELETE /tax_rates/1.json
  def destroy
    # @tax_rate.destroy
    respond_to do |format|
      format.html { redirect_to tax_rates_url, notice: 'Not Available' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tax_rate
      @tax_rate = TaxRate.find(params[:id])
    end

    def set_instance_variable
      @currencies = Currency.all
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def tax_rate_params
      params.require(:tax_rate).permit(:currency_id, :currency_value, :begin_date, :end_date, :created_at, :created_by, :updated_at, :updated_by)
    end
end
