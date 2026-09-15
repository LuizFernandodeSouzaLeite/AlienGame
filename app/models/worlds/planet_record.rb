module Worlds
  # A read-only representation of a Planet as returned by World Service's
  # /api/v1/planets contract (see contracts/worlds/v1/README.md). This is
  # NOT an ActiveRecord model: it cannot be saved, updated, or destroyed.
  # It exists so the rest of the app never depends on a raw JSON Hash
  # shape — see WorldsClient.
  PlanetRecord = Data.define(:id, :name)
end
