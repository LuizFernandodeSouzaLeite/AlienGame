require "test_helper"

class Powers::PowerDirectoryTest < ActiveSupport::TestCase
  setup do
    @original_flag = Rails.application.config.x.power_shadow_reads_enabled
  end

  teardown do
    Rails.application.config.x.power_shadow_reads_enabled = @original_flag
  end

  test "shadow_verify does nothing (no network call) when shadow reads are disabled" do
    Rails.application.config.x.power_shadow_reads_enabled = false
    local = powers(:one)

    called = false
    stub_powers_client_perform_get(->(*) { called = true }) do
      result = Powers::PowerDirectory.shadow_verify(local)
      assert_nil result
    end

    refute called, "PowersClient must not be called when shadow reads are disabled"
  end

  test "shadow_verify calls PowersClient when shadow reads are enabled" do
    Rails.application.config.x.power_shadow_reads_enabled = true
    local = powers(:one)

    handler = ->(*) { PowersClient::Response.new(200, { id: local.id, name: local.name }.to_json) }

    stub_powers_client_perform_get(handler) do
      result = Powers::PowerDirectory.shadow_verify(local)
      assert_equal :match, result.status
    end
  end

  test "shadow_verify_unique performs exactly one Power Service request no matter how many (repeated) Powers are passed" do
    Rails.application.config.x.power_shadow_reads_enabled = true
    fire = powers(:one)
    eletric = powers(:two)
    # Simulate 11 Aliens sharing 2 Powers, some Aliens with both — exactly
    # the scenario the Phase 8 migration prompt requires bounded at 1 call.
    powers_from_eleven_aliens = ([ fire, eletric ] * 6).first(11)

    call_count = 0
    handler = ->(*) {
      call_count += 1
      PowersClient::Response.new(200, { data: [
        { id: fire.id, name: fire.name },
        { id: eletric.id, name: eletric.name }
      ] }.to_json)
    }

    stub_powers_client_perform_get(handler) do
      Powers::PowerDirectory.shadow_verify_unique(powers_from_eleven_aliens)
    end

    assert_equal 1, call_count, "any number of (repeated) Powers must trigger exactly one list request, never one per Power or per Alien"
  end

  test "shadow_verify_unique reports remote_not_found for a local Power missing from the remote list" do
    Rails.application.config.x.power_shadow_reads_enabled = true
    local = powers(:one)

    handler = ->(*) { PowersClient::Response.new(200, { data: [] }.to_json) }

    recording_logger = Object.new
    def recording_logger.info(msg) = (@messages ||= []) << msg
    def recording_logger.messages = @messages || []

    original_logger = Rails.logger
    Rails.logger = recording_logger
    begin
      stub_powers_client_perform_get(handler) do
        Powers::PowerDirectory.shadow_verify_unique([ local ])
      end
    ensure
      Rails.logger = original_logger
    end

    assert recording_logger.messages.any? { |line| line.include?("result=remote_not_found") }
  end

  test "shadow_verify_unique does nothing when shadow reads are disabled" do
    Rails.application.config.x.power_shadow_reads_enabled = false
    local = powers(:one)

    called = false
    stub_powers_client_perform_get(->(*) { called = true }) do
      Powers::PowerDirectory.shadow_verify_unique([ local, local ])
    end

    refute called
  end

  test "shadow_verify_unique does nothing (no network call) for an empty collection" do
    Rails.application.config.x.power_shadow_reads_enabled = true

    called = false
    stub_powers_client_perform_get(->(*) { called = true }) do
      Powers::PowerDirectory.shadow_verify_unique([])
    end

    refute called
  end
end
