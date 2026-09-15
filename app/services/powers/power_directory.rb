module Powers
  # The one place root SpaceRails goes through on its way to Power
  # *definition* data. Today it just returns/verifies the local,
  # authoritative ActiveRecord Power — untouched — and optionally fires a
  # shadow verification against Power Service as a side effect (logged
  # only, never changes what renders).
  #
  # Never resolves "which Aliens have this Power" — that's alien_powers,
  # Alien Service's domain (ADR-002). Callers pass in Power records (or
  # collections of them); this class never touches Alien or AlienPower.
  class PowerDirectory
    def self.shadow_verify(power, request_id: nil)
      return unless shadow_reads_enabled?

      result = ShadowPowerVerifier.call(power, request_id: request_id)
      log_one(power.id, result)
      result
    end

    # Verifies a whole collection of (possibly repeated) local Powers with
    # AT MOST ONE Power Service HTTP request, regardless of how many
    # Powers or how many times each appears — this is the N+1-over-HTTP
    # prevention the Phase 8 migration prompt specifically requires. With
    # today's tiny catalog, one GET /api/v1/powers is always cheaper than
    # N individual lookups deduplicated by id, so that's what this uses
    # (see the Phase 8 migration record for why list beats find here).
    def self.shadow_verify_unique(powers, request_id: nil)
      return unless shadow_reads_enabled?

      unique_powers = powers.compact.uniq(&:id)
      return if unique_powers.empty?

      remote_by_id =
        begin
          PowersClient.list_powers(request_id: request_id).index_by(&:id)
        rescue PowersClient::Unavailable, PowersClient::TimeoutError, PowersClient::ServiceError => e
          unique_powers.each { |power| log_one(power.id, ShadowPowerVerifier::Result.new(status: :remote_unavailable, details: e.message)) }
          return
        rescue PowersClient::InvalidResponse, PowersClient::ContractError => e
          unique_powers.each { |power| log_one(power.id, ShadowPowerVerifier::Result.new(status: :invalid_contract, details: e.message)) }
          return
        end

      unique_powers.each do |power|
        remote = remote_by_id[power.id]
        result =
          if remote.nil?
            ShadowPowerVerifier::Result.new(status: :remote_not_found, details: nil)
          else
            ShadowPowerVerifier.compare(power, remote)
          end
        log_one(power.id, result)
      end
    end

    def self.shadow_reads_enabled?
      Rails.application.config.x.power_shadow_reads_enabled
    end
    private_class_method :shadow_reads_enabled?

    def self.log_one(power_id, result)
      message = "service=powers operation=shadow_power_read power_id=#{power_id} result=#{result.status}"
      message += " fields=#{result.details.join(",")}" if result.status == :mismatch
      message += " detail=#{result.details.inspect}" if %i[remote_unavailable invalid_contract].include?(result.status)

      Rails.logger.info(message)
    end
    private_class_method :log_one
  end
end
