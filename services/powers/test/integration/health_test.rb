require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "boots and reports healthy" do
    get "/up"
    assert_response :success
  end
end
