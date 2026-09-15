class PowersController < ApplicationController
  before_action :set_power, only: %i[ show edit update destroy ]

  # GET /powers or /powers.json
  def index
    @powers = Power.all
  end

  # GET /powers/1 or /powers/1.json
  def show
  end

  # GET /powers/new
  def new
    @power = Power.new
  end

  # GET /powers/1/edit
  def edit
  end

  # POST /powers or /powers.json
  def create
    @power = Power.new(power_params)

    respond_to do |format|
      if @power.save
        format.html { redirect_to @power, notice: "Power was successfully created." }
        format.json { render :show, status: :created, location: @power }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @power.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /powers/1 or /powers/1.json
  def update
    respond_to do |format|
      if @power.update(power_params)
        format.html { redirect_to @power, notice: "Power was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @power }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @power.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /powers/1 or /powers/1.json
  def destroy
    @power.destroy!

    respond_to do |format|
      format.html { redirect_to powers_path, notice: "Power was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_power
      @power = Power.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def power_params
      params.expect(power: [ :name ])
    end
end
