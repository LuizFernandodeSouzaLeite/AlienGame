class PlanetsController < ApplicationController
  before_action :set_planet, only: %i[ show edit update destroy ]

  # GET /planets or /planets.json
  def index
    @planets = Planet.all
    Worlds::PlanetDirectory.shadow_verify_unique(@planets, request_id: request.request_id)
  end

  # GET /planets/1 or /planets/1.json
  def show
    Worlds::PlanetDirectory.shadow_verify(@planet, request_id: request.request_id)
  end

  # GET /planets/new
  def new
    @planet = Planet.new
  end

  # GET /planets/1/edit
  def edit
  end

  # POST /planets or /planets.json
  def create
    @planet = Planet.new(planet_params)

    respond_to do |format|
      if @planet.save
        format.html { redirect_to @planet, notice: "Planet was successfully created." }
        format.json { render :show, status: :created, location: @planet }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @planet.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /planets/1 or /planets/1.json
  def update
    respond_to do |format|
      if @planet.update(planet_params)
        format.html { redirect_to @planet, notice: "Planet was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @planet }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @planet.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /planets/1 or /planets/1.json
  def destroy
    @planet.destroy!

    respond_to do |format|
      format.html { redirect_to planets_path, notice: "Planet was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_planet
      @planet = Planet.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def planet_params
      params.expect(planet: [ :name ])
    end
end
