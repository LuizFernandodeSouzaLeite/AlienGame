require "test_helper"

class PowerImporterTest < ActiveSupport::TestCase
  setup do
    # Deterministic starting state for migration-identity assertions,
    # independent of the Phase 7 API fixtures.
    Power.delete_all
  end

  def export_json(powers)
    { exported_at: Time.current.iso8601, source: "root", powers: powers }.to_json
  end

  test "preserves ids, names, and timestamps exactly" do
    json = export_json([
      { id: 1, name: "Fire", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ])

    result = PowerImporter.import(json)

    assert_equal 1, result.imported
    assert_equal 0, result.skipped_identical

    power = Power.find(1)
    assert_equal "Fire", power.name
    assert_equal "2026-09-14T11:50:01.407Z", power.created_at.iso8601(3)
    assert_equal "2026-09-14T11:50:01.407Z", power.updated_at.iso8601(3)
  end

  test "handles an empty export without error" do
    result = PowerImporter.import(export_json([]))

    assert_equal 0, result.imported
    assert_equal 0, result.skipped_identical
    assert_equal 0, Power.count
  end

  test "running the same import twice is idempotent, not duplicating records" do
    json = export_json([
      { id: 1, name: "Fire", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ])

    first = PowerImporter.import(json)
    second = PowerImporter.import(json)

    assert_equal 1, first.imported
    assert_equal 1, second.skipped_identical
    assert_equal 0, second.imported
    assert_equal 1, Power.count
  end

  test "rejects an id that already exists with different data" do
    PowerImporter.import(export_json([
      { id: 1, name: "Fire", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ]))

    conflicting = export_json([
      { id: 1, name: "a different name", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ])

    assert_raises(PowerImporter::ConflictError) { PowerImporter.import(conflicting) }
    assert_equal "Fire", Power.find(1).name
  end

  test "rejects malformed JSON" do
    assert_raises(PowerImporter::MalformedInputError) { PowerImporter.import("not json{{{") }
  end

  test "rejects an export missing the powers array" do
    assert_raises(PowerImporter::MalformedInputError) { PowerImporter.import({ source: "root" }.to_json) }
  end

  test "rejects a power row missing required fields" do
    assert_raises(PowerImporter::MalformedInputError) do
      PowerImporter.import(export_json([ { id: 1, name: "no timestamps" } ]))
    end
  end

  test "rolls back the entire import when one record in the batch is invalid" do
    json = export_json([
      { id: 1, name: "valid", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" },
      { id: 2, name: "also missing timestamps" }
    ])

    assert_raises(PowerImporter::MalformedInputError) { PowerImporter.import(json) }
    assert_equal 0, Power.count
  end

  test "rolls back the entire import when a later record conflicts" do
    PowerImporter.import(export_json([
      { id: 5, name: "existing", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ]))

    json = export_json([
      { id: 1, name: "new", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" },
      { id: 5, name: "conflicting rename", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ])

    assert_raises(PowerImporter::ConflictError) { PowerImporter.import(json) }
    assert_nil Power.find_by(id: 1), "the valid record before the conflict must not have been left committed"
    assert_equal "existing", Power.find(5).name
  end

  test "autoincrement allocates ids above the highest migrated id after import" do
    PowerImporter.import(export_json([
      { id: 1, name: "Fire", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }
    ]))

    new_power = Power.create!(name: "QA-autoincrement-check")
    assert_operator new_power.id, :>, 1

    new_power.destroy!
  end
end
