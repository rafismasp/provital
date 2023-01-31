class DeliveryCarsController < ApplicationController
  before_action :set_delivery_car, only: [:show, :edit, :update, :destroy]

  # GET /delivery_cars
  # GET /delivery_cars.json
  def index
    @delivery_cars = DeliveryCar.all
  end

  # GET /delivery_cars/1
  # GET /delivery_cars/1.json
  def show
  end

  # GET /delivery_cars/new
  def new
    @delivery_car = DeliveryCar.new
  end

  # GET /delivery_cars/1/edit
  def edit
  end

  # POST /delivery_cars
  # POST /delivery_cars.json
  def create
    @delivery_car = DeliveryCar.new(delivery_car_params)

    respond_to do |format|
      if @delivery_car.save
        format.html { redirect_to @delivery_car, notice: 'Delivery car was successfully created.' }
        format.json { render :show, status: :created, location: @delivery_car }
      else
        format.html { render :new }
        format.json { render json: @delivery_car.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /delivery_cars/1
  # PATCH/PUT /delivery_cars/1.json
  def update
    respond_to do |format|
      if @delivery_car.update(delivery_car_params)
        format.html { redirect_to @delivery_car, notice: 'Delivery car was successfully updated.' }
        format.json { render :show, status: :ok, location: @delivery_car }
      else
        format.html { render :edit }
        format.json { render json: @delivery_car.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /delivery_cars/1
  # DELETE /delivery_cars/1.json
  def destroy
    @delivery_car.destroy
    respond_to do |format|
      format.html { redirect_to delivery_cars_url, notice: 'Delivery car was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_delivery_car
      @delivery_car = DeliveryCar.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def delivery_car_params
      params.require(:delivery_car).permit(:name)
    end
end
