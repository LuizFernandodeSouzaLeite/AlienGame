ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Stubs WorldsClient.planet_exists? for the duration of the block,
    # then restores the original exactly (Minitest 6 dropped
    # Minitest::Mock's Object#stub — see root's test_helper.rb for the
    # same technique applied there).
    def stub_worlds_client_planet_exists(handler)
      metaclass = WorldsClient.singleton_class
      original = metaclass.instance_method(:planet_exists?)

      metaclass.send(:define_method, :planet_exists?) do |id, request_id: nil|
        handler.respond_to?(:call) ? handler.call(id, request_id: request_id) : handler
      end

      yield
    ensure
      metaclass.send(:define_method, :planet_exists?, original)
    end

    # As above, for PowersClient.existing_power_ids.
    def stub_powers_client_existing_power_ids(handler)
      metaclass = PowersClient.singleton_class
      original = metaclass.instance_method(:existing_power_ids)

      metaclass.send(:define_method, :existing_power_ids) do |ids, request_id: nil|
        handler.respond_to?(:call) ? handler.call(ids, request_id: request_id) : handler
      end

      yield
    ensure
      metaclass.send(:define_method, :existing_power_ids, original)
    end
  end
end
