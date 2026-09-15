require "test_helper"

class Aliens::ShadowAlienVerifierTest < ActiveSupport::TestCase
  test "match when local and remote agree, power_ids compared as a set" do
    local = aliens(:one)
    remote = Aliens::AlienRecord.new(id: local.id, name: local.name, age: local.age, planet_id: local.planet_id, power_ids: local.power_ids.reverse)

    stub_aliens_client_perform_get(show_response(remote)) do
      result = Aliens::ShadowAlienVerifier.call(local)
      assert_equal :match, result.status
    end
  end

  test "mismatch when the name differs, reporting which fields" do
    local = aliens(:one)
    remote = Aliens::AlienRecord.new(id: local.id, name: "a different name", age: local.age, planet_id: local.planet_id, power_ids: local.power_ids)

    stub_aliens_client_perform_get(show_response(remote)) do
      result = Aliens::ShadowAlienVerifier.call(local)
      assert_equal :mismatch, result.status
      assert_equal [ :name ], result.details
    end
  end

  test "mismatch when power_ids differ" do
    local = aliens(:one)
    remote = Aliens::AlienRecord.new(id: local.id, name: local.name, age: local.age, planet_id: local.planet_id, power_ids: [ 999 ])

    stub_aliens_client_perform_get(show_response(remote)) do
      result = Aliens::ShadowAlienVerifier.call(local)
      assert_equal :mismatch, result.status
      assert_equal [ :power_ids ], result.details
    end
  end

  test "remote_not_found when Alien Service returns 404" do
    local = aliens(:one)

    stub_aliens_client_perform_get(AliensClient::Response.new(404, { error: { code: "ALIEN_NOT_FOUND", message: "x" } }.to_json)) do
      result = Aliens::ShadowAlienVerifier.call(local)
      assert_equal :remote_not_found, result.status
    end
  end

  test "remote_unavailable when Alien Service is unreachable" do
    local = aliens(:one)

    stub_aliens_client_execute_http_request(->(*) { raise Errno::ECONNREFUSED }) do
      result = Aliens::ShadowAlienVerifier.call(local)
      assert_equal :remote_unavailable, result.status
    end
  end

  test "invalid_contract when the response doesn't match the documented shape" do
    local = aliens(:one)

    stub_aliens_client_perform_get(AliensClient::Response.new(200, { unexpected: true }.to_json)) do
      result = Aliens::ShadowAlienVerifier.call(local)
      assert_equal :invalid_contract, result.status
    end
  end

  def show_response(record)
    AliensClient::Response.new(200, { id: record.id, name: record.name, age: record.age, planet_id: record.planet_id, power_ids: record.power_ids }.to_json)
  end
end
