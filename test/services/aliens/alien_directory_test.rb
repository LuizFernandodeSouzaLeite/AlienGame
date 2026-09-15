require "test_helper"

class Aliens::AlienDirectoryTest < ActiveSupport::TestCase
  setup do
    @original_flag = Rails.application.config.x.alien_shadow_reads_enabled
  end

  teardown do
    Rails.application.config.x.alien_shadow_reads_enabled = @original_flag
  end

  test "shadow_verify does nothing (no network call) when shadow reads are disabled" do
    Rails.application.config.x.alien_shadow_reads_enabled = false
    local = aliens(:one)

    called = false
    stub_aliens_client_perform_get(->(*) { called = true }) do
      result = Aliens::AlienDirectory.shadow_verify(local)
      assert_nil result
    end

    refute called
  end

  test "shadow_verify_many performs exactly one Alien Service request for the whole collection" do
    Rails.application.config.x.alien_shadow_reads_enabled = true
    all_aliens = Alien.all.to_a
    assert_operator all_aliens.size, :>=, 2, "fixture setup assumption"

    call_count = 0
    handler = ->(*) {
      call_count += 1
      AliensClient::Response.new(200, { data: all_aliens.map { |a| { id: a.id, name: a.name, age: a.age, planet_id: a.planet_id, power_ids: a.power_ids } } }.to_json)
    }

    stub_aliens_client_perform_get(handler) do
      Aliens::AlienDirectory.shadow_verify_many(all_aliens)
    end

    assert_equal 1, call_count, "any number of Aliens must trigger exactly one shadow list request"
  end

  test "shadow_verify_many reports remote_not_found for a local Alien missing from the remote list" do
    Rails.application.config.x.alien_shadow_reads_enabled = true
    local = aliens(:one)

    handler = ->(*) { AliensClient::Response.new(200, { data: [] }.to_json) }

    recording_logger = Object.new
    def recording_logger.info(msg) = (@messages ||= []) << msg
    def recording_logger.messages = @messages || []

    original_logger = Rails.logger
    Rails.logger = recording_logger
    begin
      stub_aliens_client_perform_get(handler) do
        Aliens::AlienDirectory.shadow_verify_many([ local ])
      end
    ensure
      Rails.logger = original_logger
    end

    assert recording_logger.messages.any? { |line| line.include?("result=remote_not_found") }
  end

  test "shadow_verify_many does nothing when shadow reads are disabled" do
    Rails.application.config.x.alien_shadow_reads_enabled = false
    local = aliens(:one)

    called = false
    stub_aliens_client_perform_get(->(*) { called = true }) do
      Aliens::AlienDirectory.shadow_verify_many([ local ])
    end

    refute called
  end
end
