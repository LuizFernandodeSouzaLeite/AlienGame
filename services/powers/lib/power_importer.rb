# Phase 7 SOA migration: imports the neutral JSON artifact produced by
# root's PowerExporter into this service's own Power table, preserving
# ids and timestamps exactly. Migration tooling only — temporary
# infrastructure for a one-time (repeatable) data migration, not a runtime
# code path and not the /api/v1 contract. Does NOT import alien_powers —
# that relationship belongs to Alien Service (ADR-002).
class PowerImporter
  Result = Struct.new(:imported, :skipped_identical, keyword_init: true)

  class MalformedInputError < StandardError; end
  class ConflictError < StandardError; end

  def self.import(json_string)
    data = parse(json_string)
    powers = data["powers"]
    raise MalformedInputError, "missing or invalid 'powers' array" unless powers.is_a?(Array)

    imported = 0
    skipped = 0
    original_record_timestamps = Power.record_timestamps

    Power.transaction do
      Power.record_timestamps = false
      begin
        powers.each do |row|
          id, name, created_at, updated_at = extract(row)

          existing = Power.find_by(id: id)
          if existing
            if identical?(existing, name, created_at, updated_at)
              skipped += 1
              next
            else
              raise ConflictError, "Power id=#{id} already exists in Power Service with different data " \
                "(existing: name=#{existing.name.inspect} created_at=#{existing.created_at.iso8601(3)} " \
                "updated_at=#{existing.updated_at.iso8601(3)}; incoming: name=#{name.inspect} " \
                "created_at=#{created_at} updated_at=#{updated_at})"
            end
          end

          power = Power.new(id: id, name: name)
          power.created_at = created_at
          power.updated_at = updated_at
          power.save!
          imported += 1
        end
      ensure
        Power.record_timestamps = original_record_timestamps
      end
    end

    Result.new(imported: imported, skipped_identical: skipped)
  end

  def self.parse(json_string)
    JSON.parse(json_string)
  rescue JSON::ParserError => e
    raise MalformedInputError, "invalid JSON: #{e.message}"
  end
  private_class_method :parse

  def self.extract(row)
    raise MalformedInputError, "power row is not an object: #{row.inspect}" unless row.is_a?(Hash)

    id = row["id"]
    raise MalformedInputError, "power row missing 'id': #{row.inspect}" if id.nil?

    created_at = row["created_at"]
    updated_at = row["updated_at"]
    raise MalformedInputError, "power id=#{id} missing 'created_at'" if created_at.nil?
    raise MalformedInputError, "power id=#{id} missing 'updated_at'" if updated_at.nil?

    [ id, row["name"], created_at, updated_at ]
  end
  private_class_method :extract

  def self.identical?(existing, name, created_at, updated_at)
    existing.name == name &&
      existing.created_at.iso8601(3) == Time.iso8601(created_at).iso8601(3) &&
      existing.updated_at.iso8601(3) == Time.iso8601(updated_at).iso8601(3)
  end
  private_class_method :identical?
end
