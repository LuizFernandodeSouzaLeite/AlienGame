module Worlds
  # The one place root SpaceRails goes through on its way to Planet data.
  # Today it just returns the local, authoritative ActiveRecord Planet —
  # untouched — and optionally fires a shadow verification against World
  # Service as a side effect (logged only, never changes the return value).
  #
  # This exists so a later phase can swap the local read for a remote one
  # in exactly one place, per the migration plan's own "do not scatter"
  # rule (see docs/architecture/MIGRATION_PLAN.md's Phase 5 record) —
  # not as a premature repository-pattern abstraction.
  class PlanetDirectory
    def self.shadow_verify(planet, request_id: nil)
      return unless shadow_reads_enabled?

      result = ShadowPlanetVerifier.call(planet, request_id: request_id)
      log(planet.id, result)
      result
    end

    # Verifies each distinct Planet at most once, so N aliens sharing one
    # Planet produce one World Service request, not N (see the "no
    # service N+1" requirement in the Phase 5 migration prompt).
    def self.shadow_verify_unique(planets, request_id: nil)
      return unless shadow_reads_enabled?

      planets.compact.uniq(&:id).each { |planet| shadow_verify(planet, request_id: request_id) }
    end

    def self.shadow_reads_enabled?
      Rails.application.config.x.world_shadow_reads_enabled
    end
    private_class_method :shadow_reads_enabled?

    def self.log(planet_id, result)
      message = "service=worlds operation=shadow_planet_read planet_id=#{planet_id} result=#{result.status}"
      message += " fields=#{result.details.join(",")}" if result.status == :mismatch
      message += " detail=#{result.details.inspect}" if %i[remote_unavailable invalid_contract].include?(result.status)

      Rails.logger.info(message)
    end
    private_class_method :log
  end
end
