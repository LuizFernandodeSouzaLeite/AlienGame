namespace :aliens do
  desc "Import Alien + alien_powers data from root's neutral JSON migration artifact (SOA Phase 9)"
  task import: :environment do
    default_path = Rails.root.join("..", "..", "tmp", "migration", "aliens_export.json").to_s
    path = ENV.fetch("INPUT", default_path)

    unless File.exist?(path)
      abort "No migration artifact found at #{path}. Run `bin/rails aliens:export` in the root app first " \
            "(or pass INPUT=/path/to/aliens_export.json)."
    end

    result = AlienImporter.import(File.read(path))
    puts "Imported #{result.aliens_imported} alien(s), skipped #{result.aliens_skipped} identical " \
         "already-migrated alien(s)."
    puts "Imported #{result.alien_powers_imported} alien_powers row(s), skipped #{result.alien_powers_skipped} " \
         "already-migrated row(s)."
  end
end
