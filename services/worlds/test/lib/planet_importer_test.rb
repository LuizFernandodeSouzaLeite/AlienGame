require "test_helper"

class PlanetImporterTest < ActiveSupport::TestCase
  setup do
    # Deterministic starting state for migration-identity assertions,
    # independent of the Phase 3 API fixtures.
    Planet.delete_all
  end

  def export_json(planets)
    { exported_at: Time.current.iso8601, source: "root", planets: planets }.to_json
  end

  test "preserves ids, names, and timestamps exactly" do
    json = export_json([
      { id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ])

    result = PlanetImporter.import(json)

    assert_equal 1, result.imported
    assert_equal 0, result.skipped_identical

    planet = Planet.find(1)
    assert_equal "planeta B", planet.name
    assert_equal "2026-09-11T17:23:28.000Z", planet.created_at.iso8601(3)
    assert_equal "2026-09-11T17:23:28.000Z", planet.updated_at.iso8601(3)
  end

  test "handles an empty export without error" do
    result = PlanetImporter.import(export_json([]))

    assert_equal 0, result.imported
    assert_equal 0, result.skipped_identical
    assert_equal 0, Planet.count
  end

  test "running the same import twice is idempotent, not duplicating records" do
    json = export_json([
      { id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ])

    first = PlanetImporter.import(json)
    second = PlanetImporter.import(json)

    assert_equal 1, first.imported
    assert_equal 1, second.skipped_identical
    assert_equal 0, second.imported
    assert_equal 1, Planet.count
  end

  test "rejects an id that already exists with different data" do
    PlanetImporter.import(export_json([
      { id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ]))

    conflicting = export_json([
      { id: 1, name: "a different name", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ])

    assert_raises(PlanetImporter::ConflictError) { PlanetImporter.import(conflicting) }
    assert_equal "planeta B", Planet.find(1).name
  end

  test "rejects malformed JSON" do
    assert_raises(PlanetImporter::MalformedInputError) { PlanetImporter.import("not json{{{") }
  end

  test "rejects an export missing the planets array" do
    assert_raises(PlanetImporter::MalformedInputError) { PlanetImporter.import({ source: "root" }.to_json) }
  end

  test "rejects a planet row missing required fields" do
    assert_raises(PlanetImporter::MalformedInputError) do
      PlanetImporter.import(export_json([ { id: 1, name: "no timestamps" } ]))
    end
  end

  test "rolls back the entire import when one record in the batch is invalid" do
    json = export_json([
      { id: 1, name: "valid", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" },
      { id: 2, name: "also missing timestamps" }
    ])

    assert_raises(PlanetImporter::MalformedInputError) { PlanetImporter.import(json) }
    assert_equal 0, Planet.count
  end

  test "rolls back the entire import when a later record conflicts" do
    PlanetImporter.import(export_json([
      { id: 5, name: "existing", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ]))

    json = export_json([
      { id: 1, name: "new", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" },
      { id: 5, name: "conflicting rename", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ])

    assert_raises(PlanetImporter::ConflictError) { PlanetImporter.import(json) }
    assert_nil Planet.find_by(id: 1), "the valid record before the conflict must not have been left committed"
    assert_equal "existing", Planet.find(5).name
  end

  test "autoincrement allocates ids above the highest migrated id after import" do
    PlanetImporter.import(export_json([
      { id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.000Z", updated_at: "2026-09-11T17:23:28.000Z" }
    ]))

    new_planet = Planet.create!(name: "QA-autoincrement-check")
    assert_operator new_planet.id, :>, 1

    new_planet.destroy!
  end
end
