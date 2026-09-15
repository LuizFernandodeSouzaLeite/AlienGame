module Api
  module V1
    # JSON-only. Reproduces root's current local Alien validations (name
    # presence only). Owns alien_powers (ADR-002) — Alien Service is the
    # only service allowed to write that relationship. `planet_id` and
    # `power_ids` are external identifiers: validated explicitly over
    # HTTP at the controller layer before persisting, never via a hidden
    # ActiveRecord callback (see the Phase 9 migration record).
    class AliensController < ApplicationController
      class WorldNotFoundError < StandardError; end
      class PowerNotFoundError < StandardError
        attr_reader :missing_ids
        def initialize(missing_ids)
          @missing_ids = missing_ids
          super("power ids not found: #{missing_ids.join(', ')}")
        end
      end
      class DependencyUnavailableError < StandardError
        attr_reader :dependency
        def initialize(dependency)
          @dependency = dependency
          super("#{dependency} unavailable")
        end
      end

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from WorldNotFoundError, with: :render_world_not_found
      rescue_from PowerNotFoundError, with: :render_power_not_found
      rescue_from DependencyUnavailableError, with: :render_dependency_unavailable

      before_action :set_alien, only: %i[ show update destroy ]

      def index
        aliens = Alien.all.order(:id)
        power_ids_by_alien = power_ids_grouped_by_alien(aliens.map(&:id))
        render json: { data: aliens.map { |alien| AlienSerializer.call(alien, power_ids: power_ids_by_alien[alien.id] || []) } }
      end

      def show
        render json: AlienSerializer.call(@alien, power_ids: power_ids_for(@alien.id))
      end

      def create
        alien = Alien.new(alien_attributes)
        return render_validation_error(alien) unless alien.valid?

        validate_planet!(alien.planet_id)
        power_ids = validate_powers!(requested_power_ids)

        Alien.transaction do
          alien.save!
          replace_power_ids(alien, power_ids)
        end

        render json: AlienSerializer.call(alien, power_ids: power_ids), status: :created
      end

      def update
        @alien.assign_attributes(alien_attributes)
        return render_validation_error(@alien) unless @alien.valid?

        validate_planet!(@alien.planet_id)
        power_ids = params[:alien]&.key?(:power_ids) ? validate_powers!(requested_power_ids) : power_ids_for(@alien.id)

        Alien.transaction do
          @alien.save!
          replace_power_ids(@alien, power_ids) if params[:alien]&.key?(:power_ids)
        end

        render json: AlienSerializer.call(@alien, power_ids: power_ids)
      end

      def destroy
        # dependent: :destroy on Alien (local alien_powers) is enough —
        # this relationship is no longer distributed (ADR-002's target
        # state). No World/Power call needed to delete an Alien.
        @alien.destroy!
        head :no_content
      end

      private
        def set_alien
          @alien = Alien.find(params[:id])
        end

        def alien_attributes
          # .permit (not .expect) deliberately: a power_ids-only update
          # sends none of name/age/planet_id, and .expect raises
          # ParameterMissing when none of its listed keys are present.
          params.require(:alien).permit(:name, :age, :planet_id)
        end

        def requested_power_ids
          Array(params.dig(:alien, :power_ids)).map(&:to_i).uniq
        end

        def validate_planet!(planet_id)
          exists =
            begin
              WorldsClient.planet_exists?(planet_id, request_id: request.request_id)
            rescue WorldsClient::Unavailable
              raise DependencyUnavailableError, "world"
            end
          raise WorldNotFoundError unless exists
        end

        def validate_powers!(power_ids)
          return [] if power_ids.empty?

          found =
            begin
              PowersClient.existing_power_ids(power_ids, request_id: request.request_id)
            rescue PowersClient::Unavailable
              raise DependencyUnavailableError, "power"
            end

          missing = power_ids - found
          raise PowerNotFoundError, missing if missing.any?

          power_ids
        end

        def replace_power_ids(alien, power_ids)
          alien.alien_powers.destroy_all
          power_ids.each { |power_id| alien.alien_powers.create!(power_id: power_id) }
        end

        def power_ids_for(alien_id)
          AlienPower.where(alien_id: alien_id).pluck(:power_id)
        end

        def power_ids_grouped_by_alien(alien_ids)
          AlienPower.where(alien_id: alien_ids).pluck(:alien_id, :power_id).group_by(&:first).transform_values { |rows| rows.map(&:second) }
        end

        def render_not_found
          render json: { error: { code: "ALIEN_NOT_FOUND", message: "Alien could not be found." } }, status: :not_found
        end

        def render_validation_error(record)
          render json: {
            error: {
              code: "VALIDATION_ERROR",
              message: "Alien could not be saved.",
              details: record.errors.to_hash
            }
          }, status: :unprocessable_content
        end

        def render_world_not_found
          render json: { error: { code: "WORLD_NOT_FOUND", message: "Referenced Planet could not be found in World Service." } }, status: :unprocessable_content
        end

        def render_power_not_found(error)
          render json: {
            error: {
              code: "POWER_NOT_FOUND",
              message: "One or more referenced Powers could not be found in Power Service.",
              details: { power_ids: error.missing_ids }
            }
          }, status: :unprocessable_content
        end

        def render_dependency_unavailable(error)
          render json: {
            error: {
              code: "DEPENDENCY_UNAVAILABLE",
              message: "#{error.dependency.capitalize} Service is unavailable; could not validate the request."
            }
          }, status: :service_unavailable
        end
    end
  end
end
