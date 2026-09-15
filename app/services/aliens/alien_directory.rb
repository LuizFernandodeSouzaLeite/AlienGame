module Aliens
  # The one place root SpaceRails goes through on its way to Alien
  # Service verification. Local, authoritative ActiveRecord Aliens are
  # always what renders — this only optionally fires a shadow
  # verification against Alien Service as a side effect (logged only).
  class AlienDirectory
    def self.shadow_verify(alien, request_id: nil)
      return unless shadow_reads_enabled?

      result = ShadowAlienVerifier.call(alien, request_id: request_id)
      log_one(alien.id, result)
      result
    end

    # Verifies a whole collection of local Aliens with AT MOST ONE Alien
    # Service HTTP request (GET /api/v1/aliens, then an in-memory id
    # lookup) — the same N+1-over-HTTP prevention already proven for
    # Worlds::PlanetDirectory/Powers::PowerDirectory, applied here for a
    # collection where every element is normally distinct (dedup by id is
    # still applied defensively).
    def self.shadow_verify_many(aliens, request_id: nil)
      return unless shadow_reads_enabled?

      unique_aliens = aliens.compact.uniq(&:id)
      return if unique_aliens.empty?

      remote_by_id =
        begin
          AliensClient.list_aliens(request_id: request_id).index_by(&:id)
        rescue AliensClient::Unavailable, AliensClient::TimeoutError, AliensClient::ServiceError => e
          unique_aliens.each { |alien| log_one(alien.id, ShadowAlienVerifier::Result.new(status: :remote_unavailable, details: e.message)) }
          return
        rescue AliensClient::InvalidResponse, AliensClient::ContractError => e
          unique_aliens.each { |alien| log_one(alien.id, ShadowAlienVerifier::Result.new(status: :invalid_contract, details: e.message)) }
          return
        end

      unique_aliens.each do |alien|
        remote = remote_by_id[alien.id]
        result =
          if remote.nil?
            ShadowAlienVerifier::Result.new(status: :remote_not_found, details: nil)
          else
            ShadowAlienVerifier.compare(alien, remote)
          end
        log_one(alien.id, result)
      end
    end

    def self.shadow_reads_enabled?
      Rails.application.config.x.alien_shadow_reads_enabled
    end
    private_class_method :shadow_reads_enabled?

    def self.log_one(alien_id, result)
      message = "service=aliens operation=shadow_alien_read alien_id=#{alien_id} result=#{result.status}"
      message += " fields=#{result.details.join(",")}" if result.status == :mismatch
      message += " detail=#{result.details.inspect}" if %i[remote_unavailable invalid_contract].include?(result.status)

      Rails.logger.info(message)
    end
    private_class_method :log_one
  end
end
