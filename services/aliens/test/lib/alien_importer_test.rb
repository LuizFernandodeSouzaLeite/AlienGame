require "test_helper"

class AlienImporterTest < ActiveSupport::TestCase
  setup do
    AlienPower.delete_all
    Alien.delete_all
  end

  def export_json(aliens, alien_powers = [])
    { exported_at: Time.current.iso8601, source: "root", aliens: aliens, alien_powers: alien_powers }.to_json
  end

  def alien_row(id:, name: "Zorg", age: 5, planet_id: 1, created_at: "2026-09-14T12:05:16.371Z", updated_at: "2026-09-14T12:05:16.371Z")
    { id: id, name: name, age: age, planet_id: planet_id, created_at: created_at, updated_at: updated_at }
  end

  test "preserves alien ids, fields, and timestamps exactly" do
    json = export_json([ alien_row(id: 1, name: "Testao", age: 100, planet_id: 1) ])

    result = AlienImporter.import(json)

    assert_equal 1, result.aliens_imported
    assert_equal 0, result.aliens_skipped

    alien = Alien.find(1)
    assert_equal "Testao", alien.name
    assert_equal 100, alien.age
    assert_equal 1, alien.planet_id
    assert_equal "2026-09-14T12:05:16.371Z", alien.created_at.iso8601(3)
  end

  test "imports alien_powers rows referencing the migrated alien ids" do
    json = export_json(
      [ alien_row(id: 1) ],
      [ { alien_id: 1, power_id: 1 }, { alien_id: 1, power_id: 2 } ]
    )

    result = AlienImporter.import(json)

    assert_equal 2, result.alien_powers_imported
    assert_equal [ 1, 2 ], AlienPower.where(alien_id: 1).pluck(:power_id).sort
  end

  test "handles an empty export without error" do
    result = AlienImporter.import(export_json([], []))

    assert_equal 0, result.aliens_imported
    assert_equal 0, result.alien_powers_imported
    assert_equal 0, Alien.count
  end

  test "running the same import twice is idempotent for both aliens and alien_powers" do
    json = export_json([ alien_row(id: 1) ], [ { alien_id: 1, power_id: 1 } ])

    first = AlienImporter.import(json)
    second = AlienImporter.import(json)

    assert_equal 1, first.aliens_imported
    assert_equal 1, second.aliens_skipped
    assert_equal 0, second.aliens_imported
    assert_equal 1, second.alien_powers_skipped
    assert_equal 0, second.alien_powers_imported
    assert_equal 1, Alien.count
    assert_equal 1, AlienPower.count
  end

  test "rejects an alien id that already exists with different data" do
    AlienImporter.import(export_json([ alien_row(id: 1, name: "Testao") ]))

    conflicting = export_json([ alien_row(id: 1, name: "a different name") ])

    assert_raises(AlienImporter::ConflictError) { AlienImporter.import(conflicting) }
    assert_equal "Testao", Alien.find(1).name
  end

  test "rejects malformed JSON" do
    assert_raises(AlienImporter::MalformedInputError) { AlienImporter.import("not json{{{") }
  end

  test "rejects an export missing the aliens or alien_powers array" do
    assert_raises(AlienImporter::MalformedInputError) { AlienImporter.import({ source: "root", alien_powers: [] }.to_json) }
    assert_raises(AlienImporter::MalformedInputError) { AlienImporter.import({ source: "root", aliens: [] }.to_json) }
  end

  test "rejects an alien row missing required fields" do
    assert_raises(AlienImporter::MalformedInputError) do
      AlienImporter.import(export_json([ { id: 1, name: "no timestamps" } ]))
    end
  end

  test "rolls back the entire import (aliens and alien_powers) when one alien row is invalid" do
    json = export_json(
      [ alien_row(id: 1), { id: 2, name: "missing timestamps" } ],
      [ { alien_id: 1, power_id: 1 } ]
    )

    assert_raises(AlienImporter::MalformedInputError) { AlienImporter.import(json) }
    assert_equal 0, Alien.count
    assert_equal 0, AlienPower.count
  end

  test "rolls back the entire import when a later alien conflicts" do
    AlienImporter.import(export_json([ alien_row(id: 5, name: "existing") ]))

    json = export_json([ alien_row(id: 1, name: "new"), alien_row(id: 5, name: "conflicting rename") ])

    assert_raises(AlienImporter::ConflictError) { AlienImporter.import(json) }
    assert_nil Alien.find_by(id: 1), "the valid record before the conflict must not have been left committed"
    assert_equal "existing", Alien.find(5).name
  end

  test "autoincrement allocates ids above the highest migrated alien id after import" do
    AlienImporter.import(export_json([ alien_row(id: 1) ]))

    new_alien = Alien.create!(name: "QA-autoincrement-check", planet_id: 1)
    assert_operator new_alien.id, :>, 1

    new_alien.destroy!
  end
end
