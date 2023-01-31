class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  include CustomersHelper
  
  # GET /customers
  # GET /customers.json
  def index
    customers = Customer.where(:company_profile_id=> current_user.company_profile_id).order("number asc")
    # filter select - begin
      @option_filters = [['Customer Code','number'], ['Customer Name', 'name'], ['Currency','currency_id']] 
      @option_filter_records = customers
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        end

        customers = customers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @customers = pagy(customers, page: params[:page], items: pagy_items) 
  end

  # GET /customers/1
  # GET /customers/1.json
  def show
    @customer_address = CustomerAddress.find_by(:customer_id=> @customer.id)
    @customer_contact = CustomerContact.find_by(:customer_id=> @customer.id)
  end

  # GET /customers/new
  def new
    @customer = Customer.new
  end

  # GET /customers/1/edit
  def edit
    @customer_address = CustomerAddress.find_by(:customer_id=> @customer.id)
    @customer_contact = CustomerContact.find_by(:customer_id=> @customer.id)
  end

  # POST /customers
  # POST /customers.json
  def create
    params[:customer]["created_by"] = current_user.id
    params[:customer]["created_at"] = DateTime.now()
    params[:customer]["number"] = customer_code
    params[:customer]["company_profile_id"] = current_user.company_profile_id
    @customer = Customer.new(customer_params)

    respond_to do |format|
      if @customer.save
        @customer_address = CustomerAddress.new({
          :customer_id=> @customer.id,
          :office=> params[:customer_address]["office"],
          :tax_invoice=> params[:customer_address]["tax_invoice"],
          :delivery1=> params[:customer_address]["delivery1"],
          :delivery2=> params[:customer_address]["delivery2"],
          :created_at=> DateTime.now()
        })
        
        @customer_address.save

        @customer_contact = CustomerContact.new({
          :customer_id=> @customer.id,
          :name=> params[:customer_contact]["name"],
          :telephone=> params[:customer_contact]["telephone"],
          :fax=> params[:customer_contact]["fax"],
          :email=> params[:customer_contact]["email"],
          :website=> params[:customer_contact]["website"],
          :created_at=> DateTime.now()
        })
        
        @customer_contact.save
        format.html { redirect_to @customer, notice: 'Customer was successfully created.' }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    respond_to do |format|
      params[:customer]["updated_by"] = current_user.id
      params[:customer]["updated_at"] = DateTime.now()
      if @customer.update(customer_params)
        @customer_address = CustomerAddress.find_by(:customer_id=> @customer.id)
        if @customer_address.present?
          @customer_address.update({
            :customer_id=> @customer.id,
            :office=> params[:customer_address]["office"],
            :tax_invoice=> params[:customer_address]["tax_invoice"],
            :delivery1=> params[:customer_address]["delivery1"],
            :delivery2=> params[:customer_address]["delivery2"],
            :created_at=> DateTime.now()
          })
        else
          @customer_address = CustomerAddress.new({
            :customer_id=> @customer.id,
            :office=> params[:customer_address]["office"],
            :tax_invoice=> params[:customer_address]["tax_invoice"],
            :delivery1=> params[:customer_address]["delivery1"],
            :delivery2=> params[:customer_address]["delivery2"],
            :created_at=> DateTime.now()
          })
          
          @customer_address.save
        end

        @customer_contact = CustomerContact.find_by(:customer_id=> @customer.id)
        if @customer_contact.present?
          @customer_contact.update({
            :customer_id=> @customer.id,
            :name=> params[:customer_contact]["name"],
            :telephone=> params[:customer_contact]["telephone"],
            :fax=> params[:customer_contact]["fax"],
            :email=> params[:customer_contact]["email"],
            :website=> params[:customer_contact]["website"],
            :created_at=> DateTime.now()
          })
        else
          @customer_contact = CustomerContact.new({
            :customer_id=> @customer.id,
            :name=> params[:customer_contact]["name"],
            :telephone=> params[:customer_contact]["telephone"],
            :fax=> params[:customer_contact]["fax"],
            :email=> params[:customer_contact]["email"],
            :website=> params[:customer_contact]["website"],
            :created_at=> DateTime.now()
          })
          
          @customer_contact.save
        end
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to customers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end
  def export
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.find(params[:id])
    end

    def set_instance_variable  
      @currencies = Currency.all
      @term_of_payments = TermOfPayment.all
      @taxes = Tax.where(:status=> 'active')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      params.require(:customer).permit(:name, :number, :company_profile_id, :currency_id, :term_of_payment_id, :tax_id, :top_day, :invoice_numbering_period, :status, :created_at, :created_by, :updated_at, :updated_by)
    end


end
