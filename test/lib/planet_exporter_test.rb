require "test_helper"

class PlanetExporterTest < ActiveSupport::TestCase
  test "export includes every Planet with id, name, and timestamps" do
    data = PlanetExporter.export

    assert_equal "root", data[:source]
    assert_equal Planet.count, data[:planets].size

    row = data[:planets].find { |p| p[:id] == planets(:one).id }
    assert_equal planets(:one).name, row[:name]
    assert_equal planets(:one).created_at.iso8601(3), row[:created_at]
    assert_equal planets(:one).updated_at.iso8601(3), row[:updated_at]
  end

  test "export_to_file writes valid JSON containing the export" do
    path = Rails.root.join("tmp/test_planet_export_#{SecureRandom.hex(4)}.json")

    begin
      PlanetExporter.export_to_file(path)
      parsed = JSON.parse(File.read(path))

      assert_equal "root", parsed["source"]
      assert_equal Planet.count, parsed["planets"].size
    ensure
      File.delete(path) if File.exist?(path)
    end
  end
end
