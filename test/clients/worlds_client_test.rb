require "test_helper"

class WorldsClientTest < ActiveSupport::TestCase
  # Every test stubs the client's sole network entry point (see
  # stub_worlds_client_perform_get in test_helper.rb) so this suite never
  # opens a real socket (Phase 5 rule: root's unit tests must not require
  # the World Service process to be running).
  test "find_planet returns a PlanetRecord for a documented v1 show response" do
    response = WorldsClient::Response.new(200, { id: 1, name: "planeta B", created_at: "2026-09-11T17:23:28.580Z", updated_at: "2026-09-11T17:23:28.580Z" }.to_json)

    stub_worlds_client_perform_get(response) do
      record = WorldsClient.find_planet(1)
      assert_instance_of Worlds::PlanetRecord, record
      assert_equal 1, record.id
      assert_equal "planeta B", record.name
    end
  end

  test "list_planets returns an array of PlanetRecord for a documented v1 index response" do
    response = WorldsClient::Response.new(200, { data: [ { id: 1, name: "planeta B" } ] }.to_json)

    stub_worlds_client_perform_get(response) do
      records = WorldsClient.list_planets
      assert_equal 1, records.size
      assert_instance_of Worlds::PlanetRecord, records.first
      assert_equal "planeta B", records.first.name
    end
  end

  test "find_planet raises NotFound on a 404" do
    response = WorldsClient::Response.new(404, { error: { code: "PLANET_NOT_FOUND", message: "Planet could not be found." } }.to_json)

    stub_worlds_client_perform_get(response) do
      assert_raises(WorldsClient::NotFound) { WorldsClient.find_planet(999) }
    end
  end

  test "find_planet raises ServiceError on a 5xx, distinct from NotFound" do
    response = WorldsClient::Response.new(500, "")

    stub_worlds_client_perform_get(response) do
      assert_raises(WorldsClient::ServiceError) { WorldsClient.find_planet(1) }
    end
  end

  test "find_planet raises InvalidResponse on malformed JSON" do
    response = WorldsClient::Response.new(200, "not json{{{")

    stub_worlds_client_perform_get(response) do
      assert_raises(WorldsClient::InvalidResponse) { WorldsClient.find_planet(1) }
    end
  end

  test "find_planet raises ContractError when the response doesn't match the documented shape" do
    response = WorldsClient::Response.new(200, { planet_name: "X" }.to_json)

    stub_worlds_client_perform_get(response) do
      assert_raises(WorldsClient::ContractError) { WorldsClient.find_planet(1) }
    end
  end

  test "list_planets raises ContractError when 'data' is missing" do
    response = WorldsClient::Response.new(200, { planets: [] }.to_json)

    stub_worlds_client_perform_get(response) do
      assert_raises(WorldsClient::ContractError) { WorldsClient.list_planets }
    end
  end

  test "a connection refusal raises Unavailable, not a bare Errno" do
    stub_worlds_client_execute_http_request(->(*) { raise Errno::ECONNREFUSED }) do
      assert_raises(WorldsClient::Unavailable) { WorldsClient.find_planet(1) }
    end
  end

  test "an open timeout raises TimeoutError" do
    stub_worlds_client_execute_http_request(->(*) { raise Net::OpenTimeout }) do
      assert_raises(WorldsClient::TimeoutError) { WorldsClient.find_planet(1) }
    end
  end

  test "propagates an explicit request_id through to perform_get" do
    seen_request_id = nil
    fake = ->(path, request_id:) {
      seen_request_id = request_id
      WorldsClient::Response.new(200, { id: 1, name: "planeta B" }.to_json)
    }

    stub_worlds_client_perform_get(fake) do
      WorldsClient.find_planet(1, request_id: "req-abc")
    end

    assert_equal "req-abc", seen_request_id
  end
end
