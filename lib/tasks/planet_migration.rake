namespace :planets do
  desc "Export Planet data to a neutral JSON migration artifact (SOA Phase 4)"
  task export: :environment do
    path = ENV.fetch("OUTPUT", Rails.root.join("tmp/migration/planets_export.json").to_s)
    data = PlanetExporter.export
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(data))
    puts "Exported #{data[:planets].size} planet(s) to #{path}"
  end
end
