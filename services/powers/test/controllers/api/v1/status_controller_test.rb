require "test_helper"

class Api::V1::StatusControllerTest < ActionDispatch::IntegrationTest
  test "reports service identity" do
    get "/api/v1"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "powers", body["service"]
    assert_equal "v1", body["version"]
    assert_equal "ok", body["status"]
  end
end
