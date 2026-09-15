require "test_helper"

class Api::V1::AliensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alien = aliens(:one)
  end

  test "index returns a data collection with power_ids, one query for the whole collection" do
    get api_v1_aliens_url
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("data")
    assert_equal Alien.count, body["data"].size

    row = body["data"].find { |r| r["id"] == @alien.id }
    assert_equal [ 1 ], row["power_ids"]
  end

  test "show returns the v1 contract shape including power_ids" do
    get api_v1_alien_url(@alien)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @alien.id, body["id"]
    assert_equal @alien.name, body["name"]
    assert_equal @alien.planet_id, body["planet_id"]
    assert_equal [ 1 ], body["power_ids"]
  end

  test "show on a missing alien returns the 404 error envelope" do
    get api_v1_alien_url(id: 0)
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "ALIEN_NOT_FOUND", body.dig("error", "code")
  end

  test "create validates the referenced planet exists in World Service, and persists on success" do
    stub_worlds_client_planet_exists(true) do
      assert_difference("Alien.count") do
        post api_v1_aliens_url, params: { alien: { name: "Zorg", age: 5, planet_id: 1 } }
      end
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Zorg", body["name"]
    assert_equal [], body["power_ids"]
  end

  test "create rejects a planet_id that does not exist in World Service" do
    stub_worlds_client_planet_exists(false) do
      assert_no_difference("Alien.count") do
        post api_v1_aliens_url, params: { alien: { name: "Zorg", age: 5, planet_id: 999 } }
      end
    end
    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_equal "WORLD_NOT_FOUND", body.dig("error", "code")
  end

  test "create returns DEPENDENCY_UNAVAILABLE when World Service can't be reached" do
    stub_worlds_client_planet_exists(->(*) { raise WorldsClient::Unavailable }) do
      assert_no_difference("Alien.count") do
        post api_v1_aliens_url, params: { alien: { name: "Zorg", age: 5, planet_id: 1 } }
      end
    end
    assert_response :service_unavailable
    body = JSON.parse(response.body)
    assert_equal "DEPENDENCY_UNAVAILABLE", body.dig("error", "code")
  end

  test "create with power_ids validates them against Power Service with exactly one lookup, and persists the relationship" do
    call_count = 0
    handler = ->(ids, request_id: nil) { call_count += 1; ids }

    stub_worlds_client_planet_exists(true) do
      stub_powers_client_existing_power_ids(handler) do
        assert_difference("Alien.count") do
          post api_v1_aliens_url, params: { alien: { name: "Zorg", age: 5, planet_id: 1, power_ids: [ 1, 2 ] } }
        end
      end
    end

    assert_response :created
    assert_equal 1, call_count, "power_id validation must be exactly one Power Service call regardless of how many ids"
    body = JSON.parse(response.body)
    assert_equal [ 1, 2 ], body["power_ids"]
  end

  test "create rejects a power_id that does not exist in Power Service" do
    stub_worlds_client_planet_exists(true) do
      stub_powers_client_existing_power_ids(->(ids, request_id: nil) { ids - [ 999 ] }) do
        assert_no_difference("Alien.count") do
          post api_v1_aliens_url, params: { alien: { name: "Zorg", age: 5, planet_id: 1, power_ids: [ 1, 999 ] } }
        end
      end
    end
    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_equal "POWER_NOT_FOUND", body.dig("error", "code")
    assert_equal [ 999 ], body.dig("error", "details", "power_ids")
  end

  test "create rejects a blank name, matching root's local validation" do
    stub_worlds_client_planet_exists(true) do
      assert_no_difference("Alien.count") do
        post api_v1_aliens_url, params: { alien: { name: "", age: 5, planet_id: 1 } }
      end
    end
    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_equal "VALIDATION_ERROR", body.dig("error", "code")
  end

  test "update replaces power_ids entirely when the key is present" do
    stub_worlds_client_planet_exists(true) do
      stub_powers_client_existing_power_ids(->(ids, request_id: nil) { ids }) do
        patch api_v1_alien_url(@alien), params: { alien: { power_ids: [ 2 ] } }
      end
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [ 2 ], body["power_ids"]
    assert_equal [ 2 ], AlienPower.where(alien_id: @alien.id).pluck(:power_id)
  end

  test "update leaves power_ids untouched when the key is absent" do
    stub_worlds_client_planet_exists(true) do
      patch api_v1_alien_url(@alien), params: { alien: { name: "Renamed" } }
    end
    assert_response :success
    assert_equal "Renamed", @alien.reload.name
    assert_equal [ 1 ], AlienPower.where(alien_id: @alien.id).pluck(:power_id)
  end

  test "destroy removes the Alien and its local alien_powers rows (no longer distributed)" do
    assert_difference("Alien.count", -1) do
      assert_difference("AlienPower.count", -1) do
        delete api_v1_alien_url(@alien)
      end
    end
    assert_response :no_content
  end
end
