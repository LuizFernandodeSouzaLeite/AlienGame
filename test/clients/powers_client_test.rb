require "test_helper"

class PowersClientTest < ActiveSupport::TestCase
  # Every test stubs the client's sole network entry point (see
  # stub_powers_client_perform_get in test_helper.rb) so this suite never
  # opens a real socket (Phase 8 rule, same as Phase 5's WorldsClient:
  # root's unit tests must not require the Power Service process).
  test "find_power returns a PowerRecord for a documented v1 show response" do
    response = PowersClient::Response.new(200, { id: 1, name: "Fire", created_at: "2026-09-14T11:50:01.407Z", updated_at: "2026-09-14T11:50:01.407Z" }.to_json)

    stub_powers_client_perform_get(response) do
      record = PowersClient.find_power(1)
      assert_instance_of Powers::PowerRecord, record
      assert_equal 1, record.id
      assert_equal "Fire", record.name
    end
  end

  test "list_powers returns an array of PowerRecord for a documented v1 index response" do
    response = PowersClient::Response.new(200, { data: [ { id: 1, name: "Fire" }, { id: 2, name: "Eletric" } ] }.to_json)

    stub_powers_client_perform_get(response) do
      records = PowersClient.list_powers
      assert_equal 2, records.size
      assert_instance_of Powers::PowerRecord, records.first
      assert_equal %w[ Fire Eletric ], records.map(&:name)
    end
  end

  test "find_power raises NotFound on a 404" do
    response = PowersClient::Response.new(404, { error: { code: "POWER_NOT_FOUND", message: "Power could not be found." } }.to_json)

    stub_powers_client_perform_get(response) do
      assert_raises(PowersClient::NotFound) { PowersClient.find_power(999) }
    end
  end

  test "find_power raises ServiceError on a 5xx, distinct from NotFound" do
    response = PowersClient::Response.new(500, "")

    stub_powers_client_perform_get(response) do
      assert_raises(PowersClient::ServiceError) { PowersClient.find_power(1) }
    end
  end

  test "find_power raises InvalidResponse on malformed JSON" do
    response = PowersClient::Response.new(200, "not json{{{")

    stub_powers_client_perform_get(response) do
      assert_raises(PowersClient::InvalidResponse) { PowersClient.find_power(1) }
    end
  end

  test "find_power raises ContractError when the response doesn't match the documented shape" do
    response = PowersClient::Response.new(200, { power_name: "X" }.to_json)

    stub_powers_client_perform_get(response) do
      assert_raises(PowersClient::ContractError) { PowersClient.find_power(1) }
    end
  end

  test "list_powers raises ContractError when 'data' is missing" do
    response = PowersClient::Response.new(200, { powers: [] }.to_json)

    stub_powers_client_perform_get(response) do
      assert_raises(PowersClient::ContractError) { PowersClient.list_powers }
    end
  end

  test "a connection refusal raises Unavailable, not a bare Errno" do
    stub_powers_client_execute_http_request(->(*) { raise Errno::ECONNREFUSED }) do
      assert_raises(PowersClient::Unavailable) { PowersClient.find_power(1) }
    end
  end

  test "an open timeout raises TimeoutError" do
    stub_powers_client_execute_http_request(->(*) { raise Net::OpenTimeout }) do
      assert_raises(PowersClient::TimeoutError) { PowersClient.find_power(1) }
    end
  end

  test "propagates an explicit request_id through to perform_get" do
    seen_request_id = nil
    fake = ->(path, request_id:) {
      seen_request_id = request_id
      PowersClient::Response.new(200, { id: 1, name: "Fire" }.to_json)
    }

    stub_powers_client_perform_get(fake) do
      PowersClient.find_power(1, request_id: "req-abc")
    end

    assert_equal "req-abc", seen_request_id
  end
end
