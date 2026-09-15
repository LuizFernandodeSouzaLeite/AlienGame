module Aliens
  # Compares a local (authoritative) Alien against Alien Service's copy,
  # for verification only — the result never changes what the user sees
  # in Phase 9. Compares ONLY durable domain fields (id, name, age,
  # planet_id, power_ids) — never transient browser/session state (tank
  # position, behavioral state, scanner animation phase, camera position),
  # which is never persisted anywhere and has no business being compared
  # (see the Phase 9 migration record's ownership inventory).
  # `power_ids` is compared as a set — order doesn't carry meaning.
  class ShadowAlienVerifier
    Result = Data.define(:status, :details)

    def self.call(local_alien, request_id: nil)
      remote = AliensClient.find_alien(local_alien.id, request_id: request_id)
      compare(local_alien, remote)
    rescue AliensClient::NotFound
      Result.new(status: :remote_not_found, details: nil)
    rescue AliensClient::Unavailable, AliensClient::TimeoutError, AliensClient::ServiceError => e
      Result.new(status: :remote_unavailable, details: e.message)
    rescue AliensClient::InvalidResponse, AliensClient::ContractError => e
      Result.new(status: :invalid_contract, details: e.message)
    end

    def self.compare(local_alien, remote)
      mismatched_fields = []
      mismatched_fields << :id if local_alien.id != remote.id
      mismatched_fields << :name if local_alien.name != remote.name
      mismatched_fields << :age if local_alien.age != remote.age
      mismatched_fields << :planet_id if local_alien.planet_id != remote.planet_id
      mismatched_fields << :power_ids if local_alien.power_ids.to_a.sort != remote.power_ids.to_a.sort

      if mismatched_fields.empty?
        Result.new(status: :match, details: nil)
      else
        Result.new(status: :mismatch, details: mismatched_fields)
      end
    end
  end
end
