require "net/http"

# Alien Service's own, independent client to Power Service. NOT the same
# Ruby class as root's app/clients/powers_client.rb (separate
# application, separate implementation — ADR-004). Only what Alien
# Service actually needs: confirming a set of power_ids exist before
# persisting alien_powers rows that reference them.
class PowersClient
  class Error < StandardError; end
  class Unavailable < Error; end

  class << self
    # Given any number of requested power ids, returns the subset that
    # actually exist in Power Service — using exactly ONE HTTP request
    # (GET /api/v1/powers, then an in-memory set intersection), never one
    # request per id. This is the N+1-over-HTTP prevention required for
    # Alien create/update carrying several power_ids (see the Phase 9
    # migration record's network-composition section).
    def existing_power_ids(ids, request_id: nil)
      return [] if ids.blank?

      uri = URI.join(base_url, "/api/v1/powers")
      response = perform_get(uri, request_id: request_id)

      case response.code.to_i
      when 200..299
        body = JSON.parse(response.body)
        available = (body["data"] || []).map { |row| row["id"] }
        ids.map(&:to_i).uniq & available
      else
        raise Unavailable, "Power Service returned #{response.code} while checking power ids"
      end
    rescue JSON::ParserError => e
      raise Unavailable, "Power Service returned invalid JSON: #{e.message}"
    end

    private

    def perform_get(uri, request_id:)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["X-Request-Id"] = request_id if request_id
      execute_http_request(uri, request)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise Unavailable, "Power Service request to #{uri} timed out"
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
