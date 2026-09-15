namespace :planets do
  desc "Import Planet data from root's neutral JSON migration artifact (SOA Phase 4)"
  task import: :environment do
    default_path = Rails.root.join("..", "..", "tmp", "migration", "planets_export.json").to_s
    path = ENV.fetch("INPUT", default_path)

    unless File.exist?(path)
      abort "No migration artifact found at #{path}. Run `bin/rails planets:export` in the root app first " \
            "(or pass INPUT=/path/to/planets_export.json)."
    end

    result = PlanetImporter.import(File.read(path))
    puts "Imported #{result.imported} planet(s), skipped #{result.skipped_identical} identical " \
         "already-migrated planet(s)."
  end

  desc "DESTRUCTIVE (World Service only): wipes this service's own Planet table and reimports the " \
       "canonical snapshot from root. Only safe while World Service is non-authoritative (Phase 6 " \
       "parity restoration) — does not touch root's database."
  task restore_from_canonical: :environment do
    default_path = Rails.root.join("..", "..", "tmp", "migration", "planets_export.json").to_s
    path = ENV.fetch("INPUT", default_path)

    unless File.exist?(path)
      abort "No migration artifact found at #{path}. Run `bin/rails planets:export` in the root app first " \
            "(or pass INPUT=/path/to/planets_export.json)."
    end

    before = Planet.count
    Planet.delete_all
    result = PlanetImporter.import(File.read(path))
    puts "Wiped #{before} existing (non-authoritative) Planet row(s). Imported #{result.imported}, " \
         "skipped #{result.skipped_identical} identical planet(s)."
  end
end
