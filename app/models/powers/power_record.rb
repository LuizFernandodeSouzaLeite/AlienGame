module Powers
  # A read-only representation of a Power *definition* as returned by
  # Power Service's /api/v1/powers contract (see
  # contracts/powers/v1/README.md). This is NOT an ActiveRecord model: it
  # cannot be saved, updated, or destroyed, and it deliberately has no
  # `alien_ids`/relationship field — Power Service has no concept of which
  # Aliens have this Power (that's alien_powers, owned by Alien Service).
  PowerRecord = Data.define(:id, :name)
end
