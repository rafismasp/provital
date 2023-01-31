class QuotationSuppliersController < ApplicationController
  before_action :set_quotation_supplier, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  
  include UserPermissionsHelper
  before_action :require_permission_view, only: [:index, :show]
  before_action :require_permission_edit, only: [:edit, :update]
  before_action :require_permission_create, only: [:create]
  before_action :require_permission_remove, only: [:destroy]

  # GET /quotation_suppliers
  # GET /quotation_suppliers.json
  def index
    @quotation_suppliers = QuotationSupplier.all
  end

  # GET /quotation_suppliers/1
  # GET /quotation_suppliers/1.json
  def show
  end

  # GET /quotation_suppliers/new
  def new
    @quotation_supplier = QuotationSupplier.new
  end

  # GET /quotation_suppliers/1/edit
  def edit
  end

  # POST /quotation_suppliers
  # POST /quotation_suppliers.json
  def create
    @quotation_supplier = QuotationSupplier.new(quotation_supplier_params)

    respond_to do |format|
      if @quotation_supplier.save
        format.html { redirect_to @quotation_supplier, notice: 'Quotation supplier was successfully created.' }
        format.json { render :show, status: :created, location: @quotation_supplier }
      else
        format.html { render :new }
        format.json { render json: @quotation_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /quotation_suppliers/1
  # PATCH/PUT /quotation_suppliers/1.json
  def update
    respond_to do |format|
      if @quotation_supplier.update(quotation_supplier_params)
        format.html { redirect_to @quotation_supplier, notice: 'Quotation supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @quotation_supplier }
      else
        format.html { render :edit }
        format.json { render json: @quotation_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quotation_suppliers/1
  # DELETE /quotation_suppliers/1.json
  def destroy
    @quotation_supplier.destroy
    respond_to do |format|
      format.html { redirect_to quotation_suppliers_url, notice: 'Quotation supplier was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_quotation_supplier
      @quotation_supplier = QuotationSupplier.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def quotation_supplier_params
      params.require(:quotation_supplier).permit(:number)
    end
end
