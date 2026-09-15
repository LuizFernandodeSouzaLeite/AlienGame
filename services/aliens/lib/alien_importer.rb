# Phase 9 SOA migration: imports the neutral JSON artifact produced by
# root's AlienExporter into this service's own aliens + alien_powers
# tables, preserving ids and timestamps exactly. Migration tooling only —
# temporary infrastructure for a one-time (repeatable) data migration,
# not a runtime code path and not the /api/v1 contract. Aliens and their
# alien_powers rows import together, transactionally — a batch either
# fully lands or fully rolls back (see the Phase 9 migration record).
class AlienImporter
  Result = Struct.new(:aliens_imported, :aliens_skipped, :alien_powers_imported, :alien_powers_skipped, keyword_init: true)

  class MalformedInputError < StandardError; end
  class ConflictError < StandardError; end

  def self.import(json_string)
    data = parse(json_string)
    aliens = data["aliens"]
    alien_powers = data["alien_powers"]
    raise MalformedInputError, "missing or invalid 'aliens' array" unless aliens.is_a?(Array)
    raise MalformedInputError, "missing or invalid 'alien_powers' array" unless alien_powers.is_a?(Array)

    aliens_imported = 0
    aliens_skipped = 0
    powers_imported = 0
    powers_skipped = 0
    original_record_timestamps = Alien.record_timestamps

    Alien.transaction do
      Alien.record_timestamps = false
      begin
        aliens.each do |row|
          id, name, age, planet_id, created_at, updated_at = extract_alien(row)

          existing = Alien.find_by(id: id)
          if existing
            if identical_alien?(existing, name, age, planet_id, created_at, updated_at)
              aliens_skipped += 1
              next
            else
              raise ConflictError, "Alien id=#{id} already exists in Alien Service with different data " \
                "(existing: name=#{existing.name.inspect} age=#{existing.age.inspect} planet_id=#{existing.planet_id} " \
                "created_at=#{existing.created_at.iso8601(3)} updated_at=#{existing.updated_at.iso8601(3)}; " \
                "incoming: name=#{name.inspect} age=#{age.inspect} planet_id=#{planet_id} " \
                "created_at=#{created_at} updated_at=#{updated_at})"
            end
          end

          alien = Alien.new(id: id, name: name, age: age, planet_id: planet_id)
          alien.created_at = created_at
          alien.updated_at = updated_at
          alien.save!
          aliens_imported += 1
        end

        alien_powers.each do |row|
          alien_id, power_id = extract_alien_power(row)

          if AlienPower.exists?(alien_id: alien_id, power_id: power_id)
            powers_skipped += 1
            next
          end

          AlienPower.create!(alien_id: alien_id, power_id: power_id)
          powers_imported += 1
        end
      ensure
        Alien.record_timestamps = original_record_timestamps
      end
    end

    Result.new(
      aliens_imported: aliens_imported, aliens_skipped: aliens_skipped,
      alien_powers_imported: powers_imported, alien_powers_skipped: powers_skipped
    )
  end

  def self.parse(json_string)
    JSON.parse(json_string)
  rescue JSON::ParserError => e
    raise MalformedInputError, "invalid JSON: #{e.message}"
  end
  private_class_method :parse

  def self.extract_alien(row)
    raise MalformedInputError, "alien row is not an object: #{row.inspect}" unless row.is_a?(Hash)

    id = row["id"]
    raise MalformedInputError, "alien row missing 'id': #{row.inspect}" if id.nil?

    planet_id = row["planet_id"]
    created_at = row["created_at"]
    updated_at = row["updated_at"]
    raise MalformedInputError, "alien id=#{id} missing 'planet_id'" if planet_id.nil?
    raise MalformedInputError, "alien id=#{id} missing 'created_at'" if created_at.nil?
    raise MalformedInputError, "alien id=#{id} missing 'updated_at'" if updated_at.nil?

    [ id, row["name"], row["age"], planet_id, created_at, updated_at ]
  end
  private_class_method :extract_alien

  def self.extract_alien_power(row)
    raise MalformedInputError, "alien_powers row is not an object: #{row.inspect}" unless row.is_a?(Hash)

    alien_id = row["alien_id"]
    power_id = row["power_id"]
    raise MalformedInputError, "alien_powers row missing 'alien_id' or 'power_id': #{row.inspect}" if alien_id.nil? || power_id.nil?

    [ alien_id, power_id ]
  end
  private_class_method :extract_alien_power

  def self.identical_alien?(existing, name, age, planet_id, created_at, updated_at)
    existing.name == name &&
      existing.age == age &&
      existing.planet_id == planet_id &&
      existing.created_at.iso8601(3) == Time.iso8601(created_at).iso8601(3) &&
      existing.updated_at.iso8601(3) == Time.iso8601(updated_at).iso8601(3)
  end
  private_class_method :identical_alien?
end
