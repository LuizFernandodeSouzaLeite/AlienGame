# Phase 9 SOA migration: exports root's Alien + alien_powers data into a
# neutral JSON artifact for Alien Service to import. Migration tooling
# only — not part of the app's runtime request path, and not the
# /api/v1 contract format (see contracts/aliens/v1/README.md). Does NOT
# embed Planet or Power definitions — only the external ids
# (planet_id/power_id) that Alien Service will itself validate against
# World/Power Service.
class AlienExporter
  def self.export
    {
      exported_at: Time.current.iso8601,
      source: "root",
      aliens: Alien.order(:id).map do |alien|
        {
          id: alien.id,
          name: alien.name,
          age: alien.age,
          planet_id: alien.planet_id,
          created_at: alien.created_at.iso8601(3),
          updated_at: alien.updated_at.iso8601(3)
        }
      end,
      alien_powers: ActiveRecord::Base.connection
        .select_rows("SELECT alien_id, power_id FROM alien_powers ORDER BY id")
        .map { |alien_id, power_id| { alien_id: alien_id, power_id: power_id } }
    }
  end

  def self.export_to_file(path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(export))
  end
end
