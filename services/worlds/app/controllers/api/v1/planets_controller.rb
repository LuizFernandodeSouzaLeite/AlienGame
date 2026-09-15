module Api
  module V1
    # JSON-only. Reproduces exactly the current root Planet domain: a
    # `name` string with no presence validation (root's Planet model has
    # none — see docs/architecture/MIGRATION_PLAN.md's compatibility
    # table). No Alien/Power association exists here on purpose — see
    # ADR-002.
    class PlanetsController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      before_action :set_planet, only: %i[ show update destroy ]

      def index
        render json: { data: Planet.all.map { |planet| PlanetSerializer.call(planet) } }
      end

      def show
        render json: PlanetSerializer.call(@planet)
      end

      def create
        planet = Planet.new(planet_params)
        if planet.save
          render json: PlanetSerializer.call(planet), status: :created
        else
          render_validation_error(planet)
        end
      end

      def update
        if @planet.update(planet_params)
          render json: PlanetSerializer.call(@planet)
        else
          render_validation_error(@planet)
        end
      end

      def destroy
        # No dependent: :destroy here — World Service has no Alien model.
        # The distributed cascade is deferred to Alien Service extraction
        # (ADR-002). Deleting a Planet here only ever affects World's own
        # database.
        @planet.destroy!
        head :no_content
      end

      private
        def set_planet
          @planet = Planet.find(params[:id])
        end

        def planet_params
          params.expect(planet: [ :name ])
        end

        def render_not_found
          render json: { error: { code: "PLANET_NOT_FOUND", message: "Planet could not be found." } }, status: :not_found
        end

        def render_validation_error(record)
          render json: {
            error: {
              code: "VALIDATION_ERROR",
              message: "Planet could not be saved.",
              details: record.errors.to_hash
            }
          }, status: :unprocessable_content
        end
    end
  end
end
