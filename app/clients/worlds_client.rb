require "net/http"

# The only place in this application allowed to speak HTTP to World Service
# (ADR-004). Consumes contracts/worlds/v1 exclusively — never an
# unversioned endpoint. Read-only in Phase 5: no create/update/delete
# methods exist here on purpose (see docs/architecture/MIGRATION_PLAN.md's
# Phase 5 record — root does not perform distributed writes yet).
#
# Every failure mode is a distinct, typed error so callers (currently only
# Worlds::ShadowPlanetVerifier) can react deliberately instead of treating
# every problem as "Planet not found".
class WorldsClient
  Response = Struct.new(:status, :body)

  class Error < StandardError; end
  class Unavailable < Error; end
  class TimeoutError < Error; end
  class NotFound < Error; end
  class ServiceError < Error; end
  class InvalidResponse < Error; end
  class ContractError < Error; end

  class << self
    def find_planet(id, request_id: nil)
      response = perform_get("/api/v1/planets/#{id}", request_id: request_id)

      case response.status
      when 200..299
        planet_from(parse_json(response.body))
      when 404
        raise NotFound, "Planet id=#{id} not found in World Service"
      when 500..599
        raise ServiceError, "World Service returned #{response.status} for Planet id=#{id}"
      else
        raise ServiceError, "World Service returned unexpected status #{response.status} for Planet id=#{id}"
      end
    end

    def list_planets(request_id: nil)
      response = perform_get("/api/v1/planets", request_id: request_id)

      case response.status
      when 200..299
        body = parse_json(response.body)
        data = body["data"]
        raise ContractError, "expected a 'data' array in the index response, got: #{body.inspect}" unless data.is_a?(Array)

        data.map { |row| planet_from(row) }
      when 500..599
        raise ServiceError, "World Service returned #{response.status} for the planet index"
      else
        raise ServiceError, "World Service returned unexpected status #{response.status} for the planet index"
      end
    end

    private

    # perform_get is the seam tests stub for status/body-level behavior;
    # execute_http_request is the seam tests stub for connection-level
    # failure mapping (timeout, refusal). Neither test needs to mock
    # Net::HTTP directly or hit a real socket (no HTTP library/gem
    # dependency is added merely because this is SOA; Ruby's standard
    # library is sufficient at this scale).
    def perform_get(path, request_id:)
      uri = URI.join(base_url, path)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["X-Request-Id"] = request_id if request_id

      http_response = execute_http_request(uri, request)
      Response.new(http_response.code.to_i, http_response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError, "World Service request to #{uri} timed out"
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

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise InvalidResponse, "World Service returned invalid JSON: #{e.message}"
    end

    def planet_from(row)
      unless row.is_a?(Hash) && row.key?("id") && row.key?("name")
        raise ContractError, "expected an object with 'id' and 'name', got: #{row.inspect}"
      end

      Worlds::PlanetRecord.new(id: row["id"], name: row["name"])
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
