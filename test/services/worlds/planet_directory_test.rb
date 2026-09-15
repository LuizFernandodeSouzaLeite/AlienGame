require "test_helper"

class Worlds::PlanetDirectoryTest < ActiveSupport::TestCase
  setup do
    @original_flag = Rails.application.config.x.world_shadow_reads_enabled
  end

  teardown do
    Rails.application.config.x.world_shadow_reads_enabled = @original_flag
  end

  test "shadow_verify does nothing (no network call) when shadow reads are disabled" do
    Rails.application.config.x.world_shadow_reads_enabled = false
    local = planets(:one)

    called = false
    stub_worlds_client_perform_get(->(*) { called = true }) do
      result = Worlds::PlanetDirectory.shadow_verify(local)
      assert_nil result
    end

    refute called, "WorldsClient must not be called when shadow reads are disabled"
  end

  test "shadow_verify calls WorldsClient when shadow reads are enabled" do
    Rails.application.config.x.world_shadow_reads_enabled = true
    local = planets(:one)

    called = false
    handler = ->(*) {
      called = true
      WorldsClient::Response.new(200, { id: local.id, name: local.name }.to_json)
    }

    stub_worlds_client_perform_get(handler) do
      result = Worlds::PlanetDirectory.shadow_verify(local)
      assert_equal :match, result.status
    end

    assert called, "WorldsClient must be called when shadow reads are enabled"
  end

  test "shadow_verify_unique performs at most one World Service call per distinct Planet id" do
    Rails.application.config.x.world_shadow_reads_enabled = true
    local = planets(:one)
    eleven_aliens_worth_of_the_same_planet = Array.new(11) { local }

    call_count = 0
    handler = ->(*) {
      call_count += 1
      WorldsClient::Response.new(200, { id: local.id, name: local.name }.to_json)
    }

    stub_worlds_client_perform_get(handler) do
      Worlds::PlanetDirectory.shadow_verify_unique(eleven_aliens_worth_of_the_same_planet)
    end

    assert_equal 1, call_count, "11 aliens sharing one Planet must trigger exactly one shadow read, not 11"
  end

  test "shadow_verify_unique does nothing when shadow reads are disabled" do
    Rails.application.config.x.world_shadow_reads_enabled = false
    local = planets(:one)

    called = false
    stub_worlds_client_perform_get(->(*) { called = true }) do
      Worlds::PlanetDirectory.shadow_verify_unique([ local, local ])
    end

    refute called
  end
end
