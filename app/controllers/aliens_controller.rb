class AliensController < ApplicationController
  before_action :set_alien, only: %i[ show edit update destroy ]

  # GET /aliens or /aliens.json
  def index
    @aliens = Alien.includes(:planet, :powers).order(:id)
    Worlds::PlanetDirectory.shadow_verify_unique(@aliens.map(&:planet), request_id: request.request_id)
    Powers::PowerDirectory.shadow_verify_unique(@aliens.flat_map(&:powers), request_id: request.request_id)
    Aliens::AlienDirectory.shadow_verify_many(@aliens, request_id: request.request_id)
  end

  # GET /aliens/1 or /aliens/1.json
  def show
    @aliens = Alien.includes(:planet, :powers).order(:id)
    Worlds::PlanetDirectory.shadow_verify_unique(@aliens.map(&:planet), request_id: request.request_id)
    Powers::PowerDirectory.shadow_verify_unique(@aliens.flat_map(&:powers), request_id: request.request_id)
    Aliens::AlienDirectory.shadow_verify_many(@aliens, request_id: request.request_id)
  end

  # GET /aliens/new
  def new
    @alien = Alien.new
  end

  # GET /aliens/1/edit
  def edit
  end

  # POST /aliens or /aliens.json
  def create
    @alien = Alien.new(alien_params)

    respond_to do |format|
      if @alien.save
        flash[:new_specimen_transfer] = @alien.id
        format.html { redirect_to @alien, notice: "Alien was successfully created." }
        format.json { render :show, status: :created, location: @alien }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @alien.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /aliens/1 or /aliens/1.json
  def update
    respond_to do |format|
      if @alien.update(alien_params)
        format.html { redirect_to @alien, notice: "Alien was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @alien }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @alien.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /aliens/1 or /aliens/1.json
  def destroy
    @alien.destroy!

    respond_to do |format|
      format.html { redirect_to aliens_path, notice: "Alien was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_alien
      @alien = Alien.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def alien_params
      params.expect(alien: [ :name, :age, :planet_id, power_ids: [] ])
    end
end
