class DeliveryDriversController < ApplicationController
  before_action :set_delivery_driver, only: [:show, :edit, :update, :destroy]

  # GET /delivery_drivers
  # GET /delivery_drivers.json
  def index
    @delivery_drivers = DeliveryDriver.all
  end

  # GET /delivery_drivers/1
  # GET /delivery_drivers/1.json
  def show
  end

  # GET /delivery_drivers/new
  def new
    @delivery_driver = DeliveryDriver.new
  end

  # GET /delivery_drivers/1/edit
  def edit
  end

  # POST /delivery_drivers
  # POST /delivery_drivers.json
  def create
    @delivery_driver = DeliveryDriver.new(delivery_driver_params)

    respond_to do |format|
      if @delivery_driver.save
        format.html { redirect_to @delivery_driver, notice: 'Delivery driver was successfully created.' }
        format.json { render :show, status: :created, location: @delivery_driver }
      else
        format.html { render :new }
        format.json { render json: @delivery_driver.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /delivery_drivers/1
  # PATCH/PUT /delivery_drivers/1.json
  def update
    respond_to do |format|
      if @delivery_driver.update(delivery_driver_params)
        format.html { redirect_to @delivery_driver, notice: 'Delivery driver was successfully updated.' }
        format.json { render :show, status: :ok, location: @delivery_driver }
      else
        format.html { render :edit }
        format.json { render json: @delivery_driver.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /delivery_drivers/1
  # DELETE /delivery_drivers/1.json
  def destroy
    @delivery_driver.destroy
    respond_to do |format|
      format.html { redirect_to delivery_drivers_url, notice: 'Delivery driver was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_delivery_driver
      @delivery_driver = DeliveryDriver.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def delivery_driver_params
      params.require(:delivery_driver).permit(:name)
    end
end
