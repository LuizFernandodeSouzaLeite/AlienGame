namespace :powers do
  desc "Export Power data to a neutral JSON migration artifact (SOA Phase 7)"
  task export: :environment do
    path = ENV.fetch("OUTPUT", Rails.root.join("tmp/migration/powers_export.json").to_s)
    data = PowerExporter.export
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate(data))
    puts "Exported #{data[:powers].size} power(s) to #{path}"
  end
end
