# Alien Service's own outbound HTTP configuration for validating external
# references at create/update time (ADR-004). Independent of root's
# equivalent config — this is a different application's own settings.
Rails.application.config.x.world_service_url = ENV.fetch("WORLD_SERVICE_URL", "http://127.0.0.1:3001")
Rails.application.config.x.world_service_open_timeout = ENV.fetch("WORLD_SERVICE_OPEN_TIMEOUT", "1").to_f
Rails.application.config.x.world_service_read_timeout = ENV.fetch("WORLD_SERVICE_READ_TIMEOUT", "2").to_f

Rails.application.config.x.power_service_url = ENV.fetch("POWER_SERVICE_URL", "http://127.0.0.1:3002")
Rails.application.config.x.power_service_open_timeout = ENV.fetch("POWER_SERVICE_OPEN_TIMEOUT", "1").to_f
Rails.application.config.x.power_service_read_timeout = ENV.fetch("POWER_SERVICE_READ_TIMEOUT", "2").to_f
