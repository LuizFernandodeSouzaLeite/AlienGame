require "net/http"

# The only place in this application allowed to speak HTTP to Power
# Service (ADR-004). Consumes contracts/powers/v1 exclusively — never an
# unversioned endpoint. Read-only in Phase 8: no create/update/delete
# methods exist here on purpose (see docs/architecture/MIGRATION_PLAN.md's
# Phase 8 record — root does not perform distributed writes yet).
#
# This client only ever speaks about Power *definitions* (id/name). It has
# no concept of which Alien has which Power — that relationship
# (alien_powers) belongs to Alien Service, not Power Service, and nothing
# here queries or represents it. See Worlds::PlanetRecord/WorldsClient for
# the sibling implementation this deliberately mirrors — kept as a
# separate, small, domain-explicit class rather than a shared base client,
# since two clients isn't enough evidence to justify one (see the Phase 8
# migration record).
class PowersClient
  Response = Struct.new(:status, :body)

  class Error < StandardError; end
  class Unavailable < Error; end
  class TimeoutError < Error; end
  class NotFound < Error; end
  class ServiceError < Error; end
  class InvalidResponse < Error; end
  class ContractError < Error; end

  class << self
    def find_power(id, request_id: nil)
      response = perform_get("/api/v1/powers/#{id}", request_id: request_id)

      case response.status
      when 200..299
        power_from(parse_json(response.body))
      when 404
        raise NotFound, "Power id=#{id} not found in Power Service"
      when 500..599
        raise ServiceError, "Power Service returned #{response.status} for Power id=#{id}"
      else
        raise ServiceError, "Power Service returned unexpected status #{response.status} for Power id=#{id}"
      end
    end

    def list_powers(request_id: nil)
      response = perform_get("/api/v1/powers", request_id: request_id)

      case response.status
      when 200..299
        body = parse_json(response.body)
        data = body["data"]
        raise ContractError, "expected a 'data' array in the index response, got: #{body.inspect}" unless data.is_a?(Array)

        data.map { |row| power_from(row) }
      when 500..599
        raise ServiceError, "Power Service returned #{response.status} for the power index"
      else
        raise ServiceError, "Power Service returned unexpected status #{response.status} for the power index"
      end
    end

    private

    # perform_get is the seam tests stub for status/body-level behavior;
    # execute_http_request is the seam tests stub for connection-level
    # failure mapping (timeout, refusal).
    def perform_get(path, request_id:)
      uri = URI.join(base_url, path)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["X-Request-Id"] = request_id if request_id

      http_response = execute_http_request(uri, request)
      Response.new(http_response.code.to_i, http_response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError, "Power Service request to #{uri} timed out"
    rescue SystemCallError, SocketError, EOFError => e
      raise Unavailable, "Power Service unreachable at #{uri} (#{e.class}: #{e.message})"
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
      raise InvalidResponse, "Power Service returned invalid JSON: #{e.message}"
    end

    def power_from(row)
      unless row.is_a?(Hash) && row.key?("id") && row.key?("name")
        raise ContractError, "expected an object with 'id' and 'name', got: #{row.inspect}"
      end

      Powers::PowerRecord.new(id: row["id"], name: row["name"])
    end

    def base_url
      Rails.application.config.x.power_service_url
    end

    def open_timeout
      Rails.application.config.x.power_service_open_timeout
    end

    def read_timeout
      Rails.application.config.x.power_service_read_timeout
    end
  end
end
