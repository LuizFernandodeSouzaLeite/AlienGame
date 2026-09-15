module Api
  module V1
    # JSON-only. Reproduces exactly the current root Power domain: a
    # `name` string with no presence validation (root's Power model has
    # none — see docs/architecture/MIGRATION_PLAN.md's compatibility
    # table). Deliberately does NOT own alien_powers — that relationship
    # belongs to Alien Service (ADR-002). No Alien model exists here.
    class PowersController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      before_action :set_power, only: %i[ show update destroy ]

      def index
        render json: { data: Power.all.map { |power| PowerSerializer.call(power) } }
      end

      def show
        render json: PowerSerializer.call(@power)
      end

      def create
        power = Power.new(power_params)
        if power.save
          render json: PowerSerializer.call(power), status: :created
        else
          render_validation_error(power)
        end
      end

      def update
        if @power.update(power_params)
          render json: PowerSerializer.call(@power)
        else
          render_validation_error(@power)
        end
      end

      def destroy
        # No dependent: :destroy here — Power Service has no AlienPower
        # model and must never reach into Alien Service's database
        # (ADR-002/ADR-003). Deleting a Power here only ever affects Power
        # Service's own database; the distributed alien_powers cleanup
        # this would trigger in root today is deferred to Alien Service
        # extraction — see the Phase 7 migration record for the proven
        # current semantic and why full parity isn't claimed yet.
        @power.destroy!
        head :no_content
      end

      private
        def set_power
          @power = Power.find(params[:id])
        end

        def power_params
          params.expect(power: [ :name ])
        end

        def render_not_found
          render json: { error: { code: "POWER_NOT_FOUND", message: "Power could not be found." } }, status: :not_found
        end

        def render_validation_error(record)
          render json: {
            error: {
              code: "VALIDATION_ERROR",
              message: "Power could not be saved.",
              details: record.errors.to_hash
            }
          }, status: :unprocessable_content
        end
    end
  end
end
