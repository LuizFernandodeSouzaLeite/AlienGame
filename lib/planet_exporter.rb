# Phase 4 SOA migration: exports root's Planet data into a neutral JSON
# artifact for World Service to import. Migration tooling only — not part
# of the app's runtime request path, and not the /api/v1 contract format
# (see contracts/worlds/v1/README.md).
class PlanetExporter
  def self.export
    {
      exported_at: Time.current.iso8601,
      source: "root",
      planets: Planet.order(:id).map do |planet|
        {
          id: planet.id,
          name: planet.name,
          created_at: planet.created_at.iso8601(3),
          updated_at: planet.updated_at.iso8601(3)
        }
      end
    }
  end

  def self.export_to_file(path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(export))
  end
end
