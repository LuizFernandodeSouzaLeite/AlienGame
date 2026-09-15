require "net/http"

# The only place in this application allowed to speak HTTP to Alien
# Service (ADR-004). Consumes contracts/aliens/v1 exclusively. Read-only
# in Phase 9: no create/update/delete methods exist here on purpose (see
# docs/architecture/MIGRATION_PLAN.md's Phase 9 record — root does not
# perform distributed writes yet, same as WorldsClient/PowersClient).
#
# Deliberately not merged into a shared base client with WorldsClient/
# PowersClient — three small, separately-readable classes with genuinely
# identical shape is still not proof that a BaseServiceClient is owed
# (same reasoning as Phase 8's migration record).
class AliensClient
  Response = Struct.new(:status, :body)

  class Error < StandardError; end
  class Unavailable < Error; end
  class TimeoutError < Error; end
  class NotFound < Error; end
  class ServiceError < Error; end
  class InvalidResponse < Error; end
  class ContractError < Error; end

  class << self
    def find_alien(id, request_id: nil)
      response = perform_get("/api/v1/aliens/#{id}", request_id: request_id)

      case response.status
      when 200..299
        alien_from(parse_json(response.body))
      when 404
        raise NotFound, "Alien id=#{id} not found in Alien Service"
      when 500..599
        raise ServiceError, "Alien Service returned #{response.status} for Alien id=#{id}"
      else
        raise ServiceError, "Alien Service returned unexpected status #{response.status} for Alien id=#{id}"
      end
    end

    def list_aliens(request_id: nil)
      response = perform_get("/api/v1/aliens", request_id: request_id)

      case response.status
      when 200..299
        body = parse_json(response.body)
        data = body["data"]
        raise ContractError, "expected a 'data' array in the index response, got: #{body.inspect}" unless data.is_a?(Array)

        data.map { |row| alien_from(row) }
      when 500..599
        raise ServiceError, "Alien Service returned #{response.status} for the alien index"
      else
        raise ServiceError, "Alien Service returned unexpected status #{response.status} for the alien index"
      end
    end

    private

    def perform_get(path, request_id:)
      uri = URI.join(base_url, path)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["X-Request-Id"] = request_id if request_id

      http_response = execute_http_request(uri, request)
      Response.new(http_response.code.to_i, http_response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError, "Alien Service request to #{uri} timed out"
    rescue SystemCallError, SocketError, EOFError => e
      raise Unavailable, "Alien Service unreachable at #{uri} (#{e.class}: #{e.message})"
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
      raise InvalidResponse, "Alien Service returned invalid JSON: #{e.message}"
    end

    def alien_from(row)
      unless row.is_a?(Hash) && row.key?("id") && row.key?("name") && row.key?("planet_id") && row.key?("power_ids")
        raise ContractError, "expected an Alien v1 object, got: #{row.inspect}"
      end

      Aliens::AlienRecord.new(
        id: row["id"], name: row["name"], age: row["age"],
        planet_id: row["planet_id"], power_ids: Array(row["power_ids"])
      )
    end

    def base_url
      Rails.application.config.x.alien_service_url
    end

    def open_timeout
      Rails.application.config.x.alien_service_open_timeout
    end

    def read_timeout
      Rails.application.config.x.alien_service_read_timeout
    end
  end
end
