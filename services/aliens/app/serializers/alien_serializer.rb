# The explicit v1 Alien representation — see contracts/aliens/v1/.
# `planet_id` and `power_ids` are external identifiers (World Service,
# Power Service respectively) — never an embedded Planet object or
# embedded Power definitions. Composing full definitions is a Web/BFF
# concern, not this service's (see the Phase 9 migration record).
class AlienSerializer
  # +power_ids+: precomputed by the caller (one query for the whole
  # collection in #index, not one per Alien — see
  # Api::V1::AliensController) to avoid N+1 SQL against alien_powers.
  def self.call(alien, power_ids:)
    {
      id: alien.id,
      name: alien.name,
      age: alien.age,
      planet_id: alien.planet_id,
      power_ids: power_ids,
      created_at: alien.created_at,
      updated_at: alien.updated_at
    }
  end
end
