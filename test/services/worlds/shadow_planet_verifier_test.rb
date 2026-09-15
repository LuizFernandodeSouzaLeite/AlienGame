require "test_helper"

class Worlds::ShadowPlanetVerifierTest < ActiveSupport::TestCase
  test "match when local and remote agree" do
    local = planets(:one)
    remote = Worlds::PlanetRecord.new(id: local.id, name: local.name)

    stub_worlds_client_perform_get(show_response(remote)) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :match, result.status
    end
  end

  test "mismatch when the name differs, reporting which fields" do
    local = planets(:one)
    remote = Worlds::PlanetRecord.new(id: local.id, name: "a different name")

    stub_worlds_client_perform_get(show_response(remote)) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :mismatch, result.status
      assert_equal [ :name ], result.details
    end
  end

  test "remote_not_found when World Service returns 404" do
    local = planets(:one)

    stub_worlds_client_perform_get(WorldsClient::Response.new(404, { error: { code: "PLANET_NOT_FOUND", message: "x" } }.to_json)) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :remote_not_found, result.status
    end
  end

  test "remote_unavailable when World Service is unreachable" do
    local = planets(:one)

    stub_worlds_client_execute_http_request(->(*) { raise Errno::ECONNREFUSED }) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :remote_unavailable, result.status
    end
  end

  test "remote_unavailable when World Service times out" do
    local = planets(:one)

    stub_worlds_client_execute_http_request(->(*) { raise Net::OpenTimeout }) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :remote_unavailable, result.status
    end
  end

  test "remote_unavailable when World Service 5xx errors" do
    local = planets(:one)

    stub_worlds_client_perform_get(WorldsClient::Response.new(500, "")) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :remote_unavailable, result.status
    end
  end

  test "invalid_contract when the response doesn't match the documented shape" do
    local = planets(:one)

    stub_worlds_client_perform_get(WorldsClient::Response.new(200, { unexpected: true }.to_json)) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :invalid_contract, result.status
    end
  end

  test "invalid_contract when the response body isn't JSON" do
    local = planets(:one)

    stub_worlds_client_perform_get(WorldsClient::Response.new(200, "not json{{{")) do
      result = Worlds::ShadowPlanetVerifier.call(local)
      assert_equal :invalid_contract, result.status
    end
  end

  def show_response(planet_record)
    WorldsClient::Response.new(200, { id: planet_record.id, name: planet_record.name }.to_json)
  end
end
