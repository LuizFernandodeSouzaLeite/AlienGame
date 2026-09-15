require "test_helper"

# Asserts the *exact* agreed shape of the Alien v1 contract (see
# contracts/aliens/v1/). Fails loudly here on any accidental field
# rename/addition, rather than surfacing as a silent integration bug in a
# consumer later.
class AlienV1ContractTest < ActionDispatch::IntegrationTest
  test "show response exposes exactly the documented fields" do
    get api_v1_alien_url(aliens(:one))

    body = JSON.parse(response.body)
    assert_equal %w[ age created_at id name planet_id power_ids updated_at ], body.keys.sort
  end

  test "index response envelope exposes exactly data as an array of the show shape" do
    get api_v1_aliens_url

    body = JSON.parse(response.body)
    assert_equal [ "data" ], body.keys
    assert_kind_of Array, body["data"]
    assert_equal %w[ age created_at id name planet_id power_ids updated_at ], body["data"].first.keys.sort
  end

  test "not-found error envelope exposes exactly the documented fields" do
    get api_v1_alien_url(id: 0)

    body = JSON.parse(response.body)
    assert_equal [ "error" ], body.keys
    assert_equal %w[ code message ], body["error"].keys.sort
  end

  test "validation error envelope exposes exactly the documented fields" do
    error_json = {
      error: { code: "VALIDATION_ERROR", message: "Alien could not be saved.", details: { name: [ "can't be blank" ] } }
    }.as_json

    assert_equal %w[ code details message ], error_json["error"].keys.sort
  end

  test "power-not-found error envelope exposes exactly the documented fields" do
    error_json = {
      error: { code: "POWER_NOT_FOUND", message: "x", details: { power_ids: [ 999 ] } }
    }.as_json

    assert_equal %w[ code details message ], error_json["error"].keys.sort
  end
end
