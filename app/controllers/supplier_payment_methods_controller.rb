class SupplierPaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier_payment_method, only: [:show, :edit, :update, :destroy]

  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /supplier_payment_methods
  # GET /supplier_payment_methods.json
  def index
    @supplier_payment_methods = SupplierPaymentMethod.all
  end

  # GET /supplier_payment_methods/1
  # GET /supplier_payment_methods/1.json
  def show
  end

  # GET /supplier_payment_methods/new
  def new
    @supplier_payment_method = SupplierPaymentMethod.new
  end

  # GET /supplier_payment_methods/1/edit
  def edit
  end

  # POST /supplier_payment_methods
  # POST /supplier_payment_methods.json
  def create
    @supplier_payment_method = SupplierPaymentMethod.new(supplier_payment_method_params)

    respond_to do |format|
      if @supplier_payment_method.save
        format.html { redirect_to @supplier_payment_method, notice: 'SupplierPaymentMethod was successfully created.' }
        format.json { render :show, status: :created, location: @supplier_payment_method }
      else
        format.html { render :new }
        format.json { render json: @supplier_payment_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /supplier_payment_methods/1
  # PATCH/PUT /supplier_payment_methods/1.json
  def update
    respond_to do |format|
      if @supplier_payment_method.update(supplier_payment_method_params)
        format.html { redirect_to @supplier_payment_method, notice: 'SupplierPaymentMethod was successfully updated.' }
        format.json { render :show, status: :ok, location: @supplier_payment_method }
      else
        format.html { render :edit }
        format.json { render json: @supplier_payment_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /supplier_payment_methods/1
  # DELETE /supplier_payment_methods/1.json
  def destroy
    @supplier_payment_method.destroy
    respond_to do |format|
      format.html { redirect_to supplier_payment_methods_url, notice: 'SupplierPaymentMethod was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_supplier_payment_method
      @supplier_payment_method = SupplierPaymentMethod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def supplier_payment_method_params
      params.require(:supplier_payment_method).permit(:name)
    end
end
