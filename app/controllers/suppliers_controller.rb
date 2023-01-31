class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_export, only: [:export]
  before_action :require_permission_remove, only: [:destroy]
  
  include SuppliersHelper

  # GET /suppliers
  # GET /suppliers.json
  def index
    suppliers = Supplier.where(:company_profile_id=> current_user.company_profile_id)
    # filter select - begin
      @option_filters = [['Supplier Name','name'],['BUSINESS DESC.','business_description'], ['Currency','currency_id'],['Term of Payment','term_of_payment_id'], ['PIC','pic'],['Telephone','telephone'],['E-Mail','email'],['Address','address'],['Remarks','remarks']]
      @option_filter_records = suppliers 
      
      if params[:filter_column].present?
        case params[:filter_column] 
        when 'currency_id'
          @option_filter_records = Currency.all
        when 'term_of_payment_id'
          @option_filter_records = TermOfPayment.all
        end
        suppliers = suppliers.where("#{params[:filter_column]}".to_sym=> params[:filter_value])
      end
    # filter select - end
    pagy_items = 10
    @c= (params[:page].to_i == 0 ? 0 : pagy_items * params[:page].to_i - (pagy_items))

    @pagy, @suppliers = pagy(suppliers.order("number asc"), page: params[:page], items: pagy_items) 
  end

  # GET /suppliers/1
  # GET /suppliers/1.json
  def show
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new
  end

  # GET /suppliers/1/edit
  def edit
  end

  # POST /suppliers
  # POST /suppliers.json
  def create    
    params[:supplier]["company_profile_id"] = current_user.company_profile_id
    params[:supplier]["created_by"] = current_user.id
    params[:supplier]["created_at"] = DateTime.now()
    params[:supplier]["number"] = supplier_code(params[:supplier]["registered_at"])
    @supplier = Supplier.new(supplier_params)

    respond_to do |format|
      if @supplier.save
        params[:new_bank].each do |item|
          bank_item = SupplierBank.find_by({
            :supplier_id=> @supplier.id,
            :dom_bank_id=> item["dom_bank_id"],
            :account_number=> item["account_number"]
          })
          if bank_item.present?
            bank_item.update({
              :account_holder=> item["account_holder"],
              :receiver_type=> item["receiver_type"],
              :residence_type=> item["residence_type"],
              :country_code_id=> item["country_code_id"],
              :currency_id=> item["currency_id"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            bank_item = SupplierBank.create({
              :supplier_id=> @supplier.id,
              :dom_bank_id=> item["dom_bank_id"],
              :account_number=> item["account_number"],
              :account_holder=> item["account_holder"],
              :receiver_type=> item["receiver_type"],
              :residence_type=> item["residence_type"],
              :country_code_id=> item["country_code_id"],
              :currency_id=> item["currency_id"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if params[:new_bank].present?
        format.html { redirect_to @supplier, notice: 'Supplier was successfully created.' }
        format.json { render :show, status: :created, location: @supplier }
      else
        format.html { render :new }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /suppliers/1
  # PATCH/PUT /suppliers/1.json
  def update
    respond_to do |format|
      params[:supplier]["updated_by"] = current_user.id
      params[:supplier]["updated_at"] = DateTime.now()
      if @supplier.update(supplier_params)

        params[:new_bank].each do |item|
          bank_item = SupplierBank.find_by({
            :supplier_id=> @supplier.id,
            :dom_bank_id=> item["dom_bank_id"],
            :account_number=> item["account_number"]
          })
          if bank_item.present?
            bank_item.update({
              :account_holder=> item["account_holder"],
              :receiver_type=> item["receiver_type"],
              :residence_type=> item["residence_type"],
              :email=> item["email"],
              :country_code_id=> item["country_code_id"],
              :currency_id=> item["currency_id"],
              :status=> 'active',
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            bank_item = SupplierBank.create({
              :supplier_id=> @supplier.id,
              :dom_bank_id=> item["dom_bank_id"],
              :account_number=> item["account_number"],
              :account_holder=> item["account_holder"],
              :email=> item["email"],
              :receiver_type=> item["receiver_type"],
              :residence_type=> item["residence_type"],
              :country_code_id=> item["country_code_id"],
              :currency_id=> item["currency_id"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if params[:new_bank].present?
        params[:bank].each do |item|
          bank_item = SupplierBank.find_by({
            :id=> item["id"]
          })
          if bank_item.present?
            bank_item.update({
              :dom_bank_id=> item["dom_bank_id"],
              :account_number=> item["account_number"],
              :account_holder=> item["account_holder"],
              :receiver_type=> item["receiver_type"],
              :residence_type=> item["residence_type"],
              :email=> item["email"],
              :country_code_id=> item["country_code_id"],
              :currency_id=> item["currency_id"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          end
        end if params[:bank].present?

        format.html { redirect_to @supplier, notice: 'Supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @supplier }
      else
        format.html { render :edit }
        format.json { render json: @supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /suppliers/1
  # DELETE /suppliers/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to suppliers_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  def export    
    template_report(controller_name, current_user.id, nil)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_supplier
      @supplier = Supplier.find(params[:id])
    end
    def set_instance_variable
      @taxes = Tax.where(:status=> "active")
      @term_of_payments = TermOfPayment.all
      @currencies = Currency.all
      @dom_banks  = DomBank.all
      @country_codes = CountryCode.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def supplier_params
      params.require(:supplier).permit(:company_profile_id, :name, :number, :registered_at, :tax_id, :term_of_payment_id, :top_day, :currency_id, :business_description, :pic, :telephone, :email, :remarks, :address, :status, :created_at, :created_by, :updated_at, :updated_by)
    end
end
