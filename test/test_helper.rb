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

    # Stubs a service client's sole network entry point for the duration of
    # the block, then restores the original method exactly (installed
    # Minitest 6 dropped Minitest::Mock's Object#stub, so this is a small
    # hand-rolled equivalent scoped to this one private class method).
    # +client+ is the client class (WorldsClient, PowersClient, ...);
    # +handler+ is either a fixed <Client>::Response or a callable
    # (path, request_id:) -> <Client>::Response.
    def stub_service_client_perform_get(client, handler)
      metaclass = client.singleton_class
      original = metaclass.instance_method(:perform_get)

      metaclass.send(:define_method, :perform_get) do |path, request_id: nil|
        handler.respond_to?(:call) ? handler.call(path, request_id: request_id) : handler
      end
      metaclass.send(:private, :perform_get)

      yield
    ensure
      metaclass.send(:define_method, :perform_get, original)
      metaclass.send(:private, :perform_get)
    end

    # As above, but stubs the lower-level connection seam so perform_get's
    # own timeout/connection-refusal rescue mapping still runs for real —
    # for testing a client's failure-mapping behavior itself.
    def stub_service_client_execute_http_request(client, handler)
      metaclass = client.singleton_class
      original = metaclass.instance_method(:execute_http_request)

      metaclass.send(:define_method, :execute_http_request) do |uri, request|
        handler.call(uri, request)
      end
      metaclass.send(:private, :execute_http_request)

      yield
    ensure
      metaclass.send(:define_method, :execute_http_request, original)
      metaclass.send(:private, :execute_http_request)
    end

    # WorldsClient-specific convenience wrappers (Phase 5), kept so
    # existing tests read the same as before.
    def stub_worlds_client_perform_get(handler, &block)
      stub_service_client_perform_get(WorldsClient, handler, &block)
    end

    def stub_worlds_client_execute_http_request(handler, &block)
      stub_service_client_execute_http_request(WorldsClient, handler, &block)
    end

    # PowersClient-specific convenience wrappers (Phase 8).
    def stub_powers_client_perform_get(handler, &block)
      stub_service_client_perform_get(PowersClient, handler, &block)
    end

    def stub_powers_client_execute_http_request(handler, &block)
      stub_service_client_execute_http_request(PowersClient, handler, &block)
    end

    # AliensClient-specific convenience wrappers (Phase 9).
    def stub_aliens_client_perform_get(handler, &block)
      stub_service_client_perform_get(AliensClient, handler, &block)
    end

    def stub_aliens_client_execute_http_request(handler, &block)
      stub_service_client_execute_http_request(AliensClient, handler, &block)
    end
  end
end
