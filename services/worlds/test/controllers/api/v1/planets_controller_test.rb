require "test_helper"

class Api::V1::PlanetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @planet = planets(:one)
  end

  test "index returns a data collection" do
    get api_v1_planets_url
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("data")
    assert_equal Planet.count, body["data"].size
  end

  test "show returns the v1 contract shape" do
    get api_v1_planet_url(@planet)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @planet.id, body["id"]
    assert_equal @planet.name, body["name"]
    assert body.key?("created_at")
    assert body.key?("updated_at")
  end

  test "show on a missing planet returns the 404 error envelope" do
    get api_v1_planet_url(id: 0)
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "PLANET_NOT_FOUND", body.dig("error", "code")
  end

  test "create with a name persists and returns 201" do
    assert_difference("Planet.count") do
      post api_v1_planets_url, params: { planet: { name: "Kepler-9c" } }
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Kepler-9c", body["name"]
  end

  test "create reproduces current root behavior: a blank name is allowed" do
    # Root Planet has no presence validation on name — Phase 3 reproduces
    # the domain as it exists today, not an improved version of it.
    assert_difference("Planet.count") do
      post api_v1_planets_url, params: { planet: { name: "" } }
    end
    assert_response :created
  end

  test "create ignores unknown attributes" do
    post api_v1_planets_url, params: { planet: { name: "Vantor", not_a_real_field: "nope" } }
    assert_response :created
  end

  test "update changes the name and returns 200" do
    patch api_v1_planet_url(@planet), params: { planet: { name: "Renamed" } }
    assert_response :success
    assert_equal "Renamed", @planet.reload.name
  end

  test "destroy removes only the World-owned row" do
    assert_difference("Planet.count", -1) do
      delete api_v1_planet_url(@planet)
    end
    assert_response :no_content
  end
end
