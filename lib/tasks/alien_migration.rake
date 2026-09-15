namespace :aliens do
  desc "Export Alien + alien_powers data to a neutral JSON migration artifact (SOA Phase 9)"
  task export: :environment do
    path = ENV.fetch("OUTPUT", Rails.root.join("tmp/migration/aliens_export.json").to_s)
    data = AlienExporter.export
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(data))
    puts "Exported #{data[:aliens].size} alien(s) and #{data[:alien_powers].size} alien_powers row(s) to #{path}"
  end
end
