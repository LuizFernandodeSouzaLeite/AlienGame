require "test_helper"

class PowerExporterTest < ActiveSupport::TestCase
  test "export includes every Power with id, name, and timestamps" do
    data = PowerExporter.export

    assert_equal "root", data[:source]
    assert_equal Power.count, data[:powers].size

    row = data[:powers].find { |p| p[:id] == powers(:one).id }
    assert_equal powers(:one).name, row[:name]
    assert_equal powers(:one).created_at.iso8601(3), row[:created_at]
    assert_equal powers(:one).updated_at.iso8601(3), row[:updated_at]
  end

  test "export_to_file writes valid JSON containing the export" do
    path = Rails.root.join("tmp/test_power_export_#{SecureRandom.hex(4)}.json")

    begin
      PowerExporter.export_to_file(path)
      parsed = JSON.parse(File.read(path))

      assert_equal "root", parsed["source"]
      assert_equal Power.count, parsed["powers"].size
    ensure
      File.delete(path) if File.exist?(path)
    end
  end
end
