require "net/http"

# Alien Service's own, independent client to World Service. NOT the same
# Ruby class as root's app/clients/worlds_client.rb — a different
# application means a genuinely separate implementation (ADR-004), even
# though the shape mirrors it. Only what Alien Service actually needs:
# confirming a planet_id exists before persisting an Alien that
# references it (see Api::V1::AliensController).
class WorldsClient
  class Error < StandardError; end
  class Unavailable < Error; end

  class << self
    # Returns true/false for a definitive answer, or raises Unavailable
    # if World Service couldn't be asked reliably (timeout, connection
    # refusal, or a 5xx) — callers must never treat "couldn't ask" the
    # same as "doesn't exist" (see the Phase 9 migration record).
    def planet_exists?(id, request_id: nil)
      uri = URI.join(base_url, "/api/v1/planets/#{id}")
      response = perform_get(uri, request_id: request_id)

      case response.code.to_i
      when 200..299 then true
      when 404 then false
      else raise Unavailable, "World Service returned #{response.code} while checking Planet id=#{id}"
      end
    end

    private

    def perform_get(uri, request_id:)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["X-Request-Id"] = request_id if request_id
      execute_http_request(uri, request)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise Unavailable, "World Service request to #{uri} timed out"
    rescue SystemCallError, SocketError, EOFError => e
      raise Unavailable, "World Service unreachable at #{uri} (#{e.class}: #{e.message})"
    end

    def execute_http_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout
      http.request(request)
    end

    def base_url
      Rails.application.config.x.world_service_url
    end

    def open_timeout
      Rails.application.config.x.world_service_open_timeout
    end

    def read_timeout
      Rails.application.config.x.world_service_read_timeout
    end
  end
end
