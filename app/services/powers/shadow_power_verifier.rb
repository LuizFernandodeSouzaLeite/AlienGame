module Powers
  # Compares a local (authoritative) Power *definition* against Power
  # Service's copy, for verification only — the result never changes what
  # the user sees in Phase 8. Compares only `id`/`name`: it never asks
  # about, and Power Service could never answer, "which Aliens have this
  # Power" — that's alien_powers, owned by Alien Service (ADR-002).
  # Every PowersClient failure mode is caught here and turned into a
  # result status rather than an exception, so a shadow check can never
  # break the page that triggered it.
  class ShadowPowerVerifier
    Result = Data.define(:status, :details)

    def self.call(local_power, request_id: nil)
      remote = PowersClient.find_power(local_power.id, request_id: request_id)
      compare(local_power, remote)
    rescue PowersClient::NotFound
      Result.new(status: :remote_not_found, details: nil)
    rescue PowersClient::Unavailable, PowersClient::TimeoutError, PowersClient::ServiceError => e
      Result.new(status: :remote_unavailable, details: e.message)
    rescue PowersClient::InvalidResponse, PowersClient::ContractError => e
      Result.new(status: :invalid_contract, details: e.message)
    end

    def self.compare(local_power, remote)
      mismatched_fields = []
      mismatched_fields << :id if local_power.id != remote.id
      mismatched_fields << :name if local_power.name != remote.name

      if mismatched_fields.empty?
        Result.new(status: :match, details: nil)
      else
        Result.new(status: :mismatch, details: mismatched_fields)
      end
    end
  end
end
