module Worlds
  # Compares a local (authoritative) Planet against World Service's copy,
  # for verification only — the result never changes what the user sees in
  # Phase 5 (see docs/architecture/MIGRATION_PLAN.md's Phase 5 record).
  # Every WorldsClient failure mode is caught here and turned into a
  # result status rather than an exception, so a shadow check can never
  # break the page that triggered it.
  class ShadowPlanetVerifier
    Result = Data.define(:status, :details)

    def self.call(local_planet, request_id: nil)
      remote = WorldsClient.find_planet(local_planet.id, request_id: request_id)
      compare(local_planet, remote)
    rescue WorldsClient::NotFound
      Result.new(status: :remote_not_found, details: nil)
    rescue WorldsClient::Unavailable, WorldsClient::TimeoutError, WorldsClient::ServiceError => e
      Result.new(status: :remote_unavailable, details: e.message)
    rescue WorldsClient::InvalidResponse, WorldsClient::ContractError => e
      Result.new(status: :invalid_contract, details: e.message)
    end

    def self.compare(local_planet, remote)
      mismatched_fields = []
      mismatched_fields << :id if local_planet.id != remote.id
      mismatched_fields << :name if local_planet.name != remote.name

      if mismatched_fields.empty?
        Result.new(status: :match, details: nil)
      else
        Result.new(status: :mismatch, details: mismatched_fields)
      end
    end
    private_class_method :compare
  end
end
