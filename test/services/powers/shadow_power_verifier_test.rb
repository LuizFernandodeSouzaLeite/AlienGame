require "test_helper"

class Powers::ShadowPowerVerifierTest < ActiveSupport::TestCase
  test "match when local and remote agree" do
    local = powers(:one)
    remote = Powers::PowerRecord.new(id: local.id, name: local.name)

    stub_powers_client_perform_get(show_response(remote)) do
      result = Powers::ShadowPowerVerifier.call(local)
      assert_equal :match, result.status
    end
  end

  test "mismatch when the name differs, reporting which fields" do
    local = powers(:one)
    remote = Powers::PowerRecord.new(id: local.id, name: "a different name")

    stub_powers_client_perform_get(show_response(remote)) do
      result = Powers::ShadowPowerVerifier.call(local)
      assert_equal :mismatch, result.status
      assert_equal [ :name ], result.details
    end
  end

  test "remote_not_found when Power Service returns 404" do
    local = powers(:one)

    stub_powers_client_perform_get(PowersClient::Response.new(404, { error: { code: "POWER_NOT_FOUND", message: "x" } }.to_json)) do
      result = Powers::ShadowPowerVerifier.call(local)
      assert_equal :remote_not_found, result.status
    end
  end

  test "remote_unavailable when Power Service is unreachable" do
    local = powers(:one)

    stub_powers_client_execute_http_request(->(*) { raise Errno::ECONNREFUSED }) do
      result = Powers::ShadowPowerVerifier.call(local)
      assert_equal :remote_unavailable, result.status
    end
  end

  test "remote_unavailable when Power Service 5xx errors" do
    local = powers(:one)

    stub_powers_client_perform_get(PowersClient::Response.new(500, "")) do
      result = Powers::ShadowPowerVerifier.call(local)
      assert_equal :remote_unavailable, result.status
    end
  end

  test "invalid_contract when the response doesn't match the documented shape" do
    local = powers(:one)

    stub_powers_client_perform_get(PowersClient::Response.new(200, { unexpected: true }.to_json)) do
      result = Powers::ShadowPowerVerifier.call(local)
      assert_equal :invalid_contract, result.status
    end
  end

  test "compare is a public, reusable comparison usable outside .call (PowerDirectory's batch path relies on this)" do
    local = powers(:one)
    remote = Powers::PowerRecord.new(id: local.id, name: local.name)

    result = Powers::ShadowPowerVerifier.compare(local, remote)
    assert_equal :match, result.status
  end

  def show_response(power_record)
    PowersClient::Response.new(200, { id: power_record.id, name: power_record.name }.to_json)
  end
end
