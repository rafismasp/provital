class CompanyProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company_profile, only: [:show, :edit, :update, :destroy]
  before_action :set_instance_variable

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /company_profiles
  # GET /company_profiles.json
  def index
    @company_profiles = CompanyProfile.all
  end

  # GET /company_profiles/1
  # GET /company_profiles/1.json
  def show
  end

  # GET /company_profiles/new
  def new
    @company_profile = CompanyProfile.new
  end

  # GET /company_profiles/1/edit
  def edit
  end

  # POST /company_profiles
  # POST /company_profiles.json
  def create
    @company_profile = CompanyProfile.new(company_profile_params)

    respond_to do |format|
      if @company_profile.save
        params[:bank].each do |item|
          company_payment_receiving = CompanyPaymentReceiving.find_by(:company_profile_id=> @company_profile.id, :currency_id=> item["currency_id"])
          if company_payment_receiving.present?
            company_payment_receiving.update_columns({
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            company_payment_receiving = CompanyPaymentReceiving.create({
              :company_profile_id=> @company_profile.id,
              :currency_id=> item["currency_id"],
              :bank_name=> item["bank_name"],
              :bank_account=> item["bank_account"],
              :signature=> item["signature"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if params[:bank].present?
        format.html { redirect_to @company_profile, notice: 'CompanyProfile was successfully created.' }
        format.json { render :show, status: :created, location: @company_profile }
      else
        format.html { render :new }
        format.json { render json: @company_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /company_profiles/1
  # PATCH/PUT /company_profiles/1.json
  def update
    respond_to do |format|
      if @company_profile.update(company_profile_params)
        params[:bank].each do |item|
          company_payment_receiving = CompanyPaymentReceiving.find_by(:company_profile_id=> @company_profile.id, :currency_id=> item["currency_id"])
          if company_payment_receiving.present?
            company_payment_receiving.update_columns({
              :bank_name=> item["bank_name"],
              :bank_account=> item["bank_account"],
              :signature=> item["signature"],
              :status=> item["status"],
              :updated_at=> DateTime.now(), :updated_by=> current_user.id
            })
          else
            company_payment_receiving = CompanyPaymentReceiving.create({
              :company_profile_id=> @company_profile.id,
              :currency_id=> item["currency_id"],
              :bank_name=> item["bank_name"],
              :bank_account=> item["bank_account"],
              :signature=> item["signature"],
              :status=> 'active',
              :created_at=> DateTime.now(), :created_by=> current_user.id
            })
          end
        end if params[:bank].present?

        format.html { redirect_to @company_profile, notice: 'CompanyProfile was successfully updated.' }
        format.json { render :show, status: :ok, location: @company_profile }
      else
        format.html { render :edit }
        format.json { render json: @company_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /company_profiles/1
  # DELETE /company_profiles/1.json
  def destroy
    respond_to do |format|
      format.html { redirect_to company_profiles_url, alert: 'We Cannot Remove This Record!' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_profile
      @company_profile = CompanyProfile.find(params[:id])
      @company_payment_receivings = CompanyPaymentReceiving.where(:company_profile_id=> @company_profile.id) if @company_profile.present?
    end
    def set_instance_variable  
      @currencies = Currency.all
      @term_of_payments = TermOfPayment.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def company_profile_params
      params.require(:company_profile).permit(:name, :address_row1, :address_row2, :address_row3)
    end
end
