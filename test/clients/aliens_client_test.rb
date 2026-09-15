require "test_helper"

class AliensClientTest < ActiveSupport::TestCase
  def sample_row(overrides = {})
    { id: 1, name: "Testao", age: 100, planet_id: 1, power_ids: [ 1 ], created_at: "2026-09-14T12:05:16.371Z", updated_at: "2026-09-14T12:05:16.371Z" }.merge(overrides)
  end

  test "find_alien returns an AlienRecord for a documented v1 show response" do
    response = AliensClient::Response.new(200, sample_row.to_json)

    stub_aliens_client_perform_get(response) do
      record = AliensClient.find_alien(1)
      assert_instance_of Aliens::AlienRecord, record
      assert_equal 1, record.id
      assert_equal "Testao", record.name
      assert_equal 1, record.planet_id
      assert_equal [ 1 ], record.power_ids
    end
  end

  test "list_aliens returns an array of AlienRecord for a documented v1 index response" do
    response = AliensClient::Response.new(200, { data: [ sample_row ] }.to_json)

    stub_aliens_client_perform_get(response) do
      records = AliensClient.list_aliens
      assert_equal 1, records.size
      assert_instance_of Aliens::AlienRecord, records.first
    end
  end

  test "find_alien raises NotFound on a 404" do
    response = AliensClient::Response.new(404, { error: { code: "ALIEN_NOT_FOUND", message: "x" } }.to_json)

    stub_aliens_client_perform_get(response) do
      assert_raises(AliensClient::NotFound) { AliensClient.find_alien(999) }
    end
  end

  test "find_alien raises ServiceError on a 5xx, distinct from NotFound" do
    response = AliensClient::Response.new(500, "")

    stub_aliens_client_perform_get(response) do
      assert_raises(AliensClient::ServiceError) { AliensClient.find_alien(1) }
    end
  end

  test "find_alien raises InvalidResponse on malformed JSON" do
    response = AliensClient::Response.new(200, "not json{{{")

    stub_aliens_client_perform_get(response) do
      assert_raises(AliensClient::InvalidResponse) { AliensClient.find_alien(1) }
    end
  end

  test "find_alien raises ContractError when the response doesn't match the documented shape" do
    response = AliensClient::Response.new(200, { alien_name: "X" }.to_json)

    stub_aliens_client_perform_get(response) do
      assert_raises(AliensClient::ContractError) { AliensClient.find_alien(1) }
    end
  end

  test "list_aliens raises ContractError when 'data' is missing" do
    response = AliensClient::Response.new(200, { aliens: [] }.to_json)

    stub_aliens_client_perform_get(response) do
      assert_raises(AliensClient::ContractError) { AliensClient.list_aliens }
    end
  end

  test "a connection refusal raises Unavailable, not a bare Errno" do
    stub_aliens_client_execute_http_request(->(*) { raise Errno::ECONNREFUSED }) do
      assert_raises(AliensClient::Unavailable) { AliensClient.find_alien(1) }
    end
  end

  test "an open timeout raises TimeoutError" do
    stub_aliens_client_execute_http_request(->(*) { raise Net::OpenTimeout }) do
      assert_raises(AliensClient::TimeoutError) { AliensClient.find_alien(1) }
    end
  end

  test "propagates an explicit request_id through to perform_get" do
    seen_request_id = nil
    fake = ->(path, request_id:) {
      seen_request_id = request_id
      AliensClient::Response.new(200, sample_row.to_json)
    }

    stub_aliens_client_perform_get(fake) do
      AliensClient.find_alien(1, request_id: "req-abc")
    end

    assert_equal "req-abc", seen_request_id
  end
end
