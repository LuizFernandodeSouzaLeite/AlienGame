require "test_helper"

class AlienExporterTest < ActiveSupport::TestCase
  test "export includes every Alien with durable fields and timestamps" do
    data = AlienExporter.export

    assert_equal "root", data[:source]
    assert_equal Alien.count, data[:aliens].size

    row = data[:aliens].find { |a| a[:id] == aliens(:one).id }
    assert_equal aliens(:one).name, row[:name]
    assert_equal aliens(:one).age, row[:age]
    assert_equal aliens(:one).planet_id, row[:planet_id]
    assert_equal aliens(:one).created_at.iso8601(3), row[:created_at]
  end

  test "export includes alien_powers as plain alien_id/power_id pairs, no Power definitions embedded" do
    data = AlienExporter.export

    pair = data[:alien_powers].find { |row| row[:alien_id] == aliens(:one).id }
    refute_nil pair
    assert_equal [ :alien_id, :power_id ], pair.keys
  end

  test "export_to_file writes valid JSON containing the export" do
    path = Rails.root.join("tmp/test_alien_export_#{SecureRandom.hex(4)}.json")

    begin
      AlienExporter.export_to_file(path)
      parsed = JSON.parse(File.read(path))

      assert_equal "root", parsed["source"]
      assert_equal Alien.count, parsed["aliens"].size
    ensure
      File.delete(path) if File.exist?(path)
    end
  end
end
