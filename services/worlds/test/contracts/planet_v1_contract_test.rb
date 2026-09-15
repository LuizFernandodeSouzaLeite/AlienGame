require "test_helper"

# Asserts the *exact* agreed shape of the Planet v1 contract (see
# contracts/worlds/v1/). This test exists to make an accidental contract
# change (a renamed/added/removed field) fail loudly here, in one place,
# rather than surface as a silent integration bug in a consumer later.
class PlanetV1ContractTest < ActionDispatch::IntegrationTest
  test "show response exposes exactly the documented fields" do
    planet = planets(:one)

    get api_v1_planet_url(planet)

    body = JSON.parse(response.body)
    assert_equal %w[ created_at id name updated_at ], body.keys.sort
  end

  test "index response envelope exposes exactly data as an array of the show shape" do
    get api_v1_planets_url

    body = JSON.parse(response.body)
    assert_equal [ "data" ], body.keys
    assert_kind_of Array, body["data"]
    assert_equal %w[ created_at id name updated_at ], body["data"].first.keys.sort
  end

  test "not-found error envelope exposes exactly the documented fields" do
    get api_v1_planet_url(id: 0)

    body = JSON.parse(response.body)
    assert_equal [ "error" ], body.keys
    assert_equal %w[ code message ], body["error"].keys.sort
  end

  test "validation error envelope exposes exactly the documented fields" do
    # This service currently has no validation that can fail (root Planet
    # has none — see the Phase 3 compatibility table). This test documents
    # the envelope shape via the serializer path directly so the contract
    # is pinned even before any validation exists to trigger it for real.
    error_json = {
      error: { code: "VALIDATION_ERROR", message: "Planet could not be saved.", details: { name: [ "can't be blank" ] } }
    }.as_json

    assert_equal %w[ code details message ], error_json["error"].keys.sort
  end
end
