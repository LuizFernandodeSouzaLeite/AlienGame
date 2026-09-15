namespace :powers do
  desc "Import Power data from root's neutral JSON migration artifact (SOA Phase 7)"
  task import: :environment do
    default_path = Rails.root.join("..", "..", "tmp", "migration", "powers_export.json").to_s
    path = ENV.fetch("INPUT", default_path)

    unless File.exist?(path)
      abort "No migration artifact found at #{path}. Run `bin/rails powers:export` in the root app first " \
            "(or pass INPUT=/path/to/powers_export.json)."
    end

    result = PowerImporter.import(File.read(path))
    puts "Imported #{result.imported} power(s), skipped #{result.skipped_identical} identical " \
         "already-migrated power(s)."
  end
end
