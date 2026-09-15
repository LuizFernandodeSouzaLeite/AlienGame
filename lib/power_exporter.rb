# Phase 7 SOA migration: exports root's Power data into a neutral JSON
# artifact for Power Service to import. Migration tooling only — not part
# of the app's runtime request path, and not the /api/v1 contract format
# (see contracts/powers/v1/README.md). Does NOT export alien_powers —
# that relationship belongs to Alien Service, not Power Service (ADR-002).
class PowerExporter
  def self.export
    {
      exported_at: Time.current.iso8601,
      source: "root",
      powers: Power.order(:id).map do |power|
        {
          id: power.id,
          name: power.name,
          created_at: power.created_at.iso8601(3),
          updated_at: power.updated_at.iso8601(3)
        }
      end
    }
  end

  def self.export_to_file(path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(export))
  end
end
