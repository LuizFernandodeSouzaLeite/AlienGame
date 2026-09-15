require "test_helper"
require "rake"

class PlanetMigrationRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("planets:import")
    Rake::Task["planets:import"].reenable
    Rake::Task["planets:restore_from_canonical"].reenable
  end

  def write_artifact(planets)
    path = Rails.root.join("tmp/test_restore_artifact_#{SecureRandom.hex(4)}.json")
    File.write(path, { exported_at: Time.current.iso8601, source: "root", planets: planets }.to_json)
    path
  end

  test "restore_from_canonical wipes this service's Planet table and reimports the snapshot exactly" do
    # Simulate exactly the Phase 6 scenario: World has drifted data (a
    # different updated_at) that must be replaced with the canonical copy.
    Planet.delete_all
    Planet.record_timestamps = false
    Planet.create!(id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.580Z", updated_at: "2026-09-15T13:42:06.824Z")
    Planet.record_timestamps = true

    path = write_artifact([
      { id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.580Z", updated_at: "2026-09-11T17:23:28.580Z" }
    ])

    begin
      ENV["INPUT"] = path.to_s
      Rake::Task["planets:restore_from_canonical"].invoke
    ensure
      ENV.delete("INPUT")
      File.delete(path) if File.exist?(path)
    end

    planet = Planet.find(1)
    assert_equal "2026-09-11T17:23:28.580Z", planet.updated_at.iso8601(3),
      "the drifted updated_at must be replaced by the canonical snapshot's value"
    assert_equal 1, Planet.count
  end
end
