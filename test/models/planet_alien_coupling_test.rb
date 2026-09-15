require "test_helper"

# Phase 6 (SOA migration) cutover-readiness evidence. These tests document
# the actual, proven coupling between Alien and the local Planet table —
# not architecture theory — so a future phase can see exactly what World
# Service authority would have to satisfy before Alien could safely
# reference a Planet it doesn't have a local row for. See
# docs/architecture/MIGRATION_PLAN.md's Phase 6 record.
class PlanetAlienCouplingTest < ActiveSupport::TestCase
  test "aliens.planet_id has a real, enforced database foreign key to planets.id" do
    foreign_keys = ActiveRecord::Base.connection.foreign_keys("aliens")
    fk = foreign_keys.find { |k| k.column == "planet_id" }

    refute_nil fk, "expected a real FK on aliens.planet_id, found none"
    assert_equal "planets", fk.to_table
  end

  test "aliens.planet_id is NOT NULL and indexed" do
    column = Alien.columns_hash["planet_id"]
    assert_not column.null, "planet_id must be NOT NULL"

    assert ActiveRecord::Base.connection.index_exists?(:aliens, :planet_id),
      "expected an index on aliens.planet_id"
  end

  test "Rails' own connection enforces the foreign key (PRAGMA foreign_keys is ON)" do
    result = ActiveRecord::Base.connection.execute("PRAGMA foreign_keys").first
    assert_equal 1, result["foreign_keys"]
  end

  test "belongs_to :planet rejects a planet_id with no local Planet row (validation layer)" do
    alien = Alien.new(name: "QA-Ghost", age: 1, planet_id: 999_999)

    assert_not alien.valid?
    assert_includes alien.errors.full_messages, "Planet must exist"
  end

  test "the database foreign key also rejects a nonexistent planet_id, even bypassing validation" do
    alien = Alien.new(name: "QA-Ghost", age: 1, planet_id: 999_999)

    assert_raises(ActiveRecord::InvalidForeignKey) { alien.save!(validate: false) }
  end

  test "these two layers mean an Alien can never reference a Planet id that only exists in World Service" do
    # This is the concrete blocker for Strategy A (cut World over now):
    # if World Service creates a Planet with an id root doesn't have
    # locally, no root Alien can ever be assigned to it — not through the
    # form (which lists local Planet.all), not through a direct model
    # save (validation), and not even by bypassing validation (DB FK).
    world_only_planet_id = Planet.maximum(:id).to_i + 1
    assert_not Planet.exists?(world_only_planet_id), "test setup assumption broken"

    alien = Alien.new(name: "QA-Ghost", age: 1, planet_id: world_only_planet_id)
    assert_not alien.valid?
    assert_raises(ActiveRecord::InvalidForeignKey) { alien.save!(validate: false) }
  end

  test "Planet#destroy cascades to its Aliens today (dependent: :destroy), matching the UI's own delete warning" do
    planet = planets(:one)
    alien = aliens(:one)
    assert_equal planet.id, alien.planet_id

    assert_difference("Alien.count", -1) do
      planet.destroy!
    end

    assert_not Alien.exists?(alien.id)
  end
end
