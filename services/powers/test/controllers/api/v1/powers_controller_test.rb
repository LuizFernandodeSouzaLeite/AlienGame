require "test_helper"

class Api::V1::PowersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @power = powers(:one)
  end

  test "index returns a data collection" do
    get api_v1_powers_url
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("data")
    assert_equal Power.count, body["data"].size
  end

  test "show returns the v1 contract shape" do
    get api_v1_power_url(@power)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @power.id, body["id"]
    assert_equal @power.name, body["name"]
    assert body.key?("created_at")
    assert body.key?("updated_at")
  end

  test "show on a missing power returns the 404 error envelope" do
    get api_v1_power_url(id: 0)
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "POWER_NOT_FOUND", body.dig("error", "code")
  end

  test "create with a name persists and returns 201" do
    assert_difference("Power.count") do
      post api_v1_powers_url, params: { power: { name: "Telekinesis" } }
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Telekinesis", body["name"]
  end

  test "create reproduces current root behavior: a blank name is allowed" do
    # Root Power has no presence validation on name — Phase 7 reproduces
    # the domain as it exists today, not an improved version of it.
    assert_difference("Power.count") do
      post api_v1_powers_url, params: { power: { name: "" } }
    end
    assert_response :created
  end

  test "create ignores unknown attributes" do
    post api_v1_powers_url, params: { power: { name: "Levitation", not_a_real_field: "nope" } }
    assert_response :created
  end

  test "update changes the name and returns 200" do
    patch api_v1_power_url(@power), params: { power: { name: "Renamed" } }
    assert_response :success
    assert_equal "Renamed", @power.reload.name
  end

  test "destroy removes only the Power-owned row" do
    assert_difference("Power.count", -1) do
      delete api_v1_power_url(@power)
    end
    assert_response :no_content
  end
end
