# Phase 5 SOA migration (ADR-004). World Service is not authoritative for
# reads yet — this only configures the boundary used for shadow reads
# (see app/clients/worlds_client.rb, app/services/worlds/).
#
# WORLD_SERVICE_URL defaults to the local development World Service.
# WORLD_SHADOW_READS_ENABLED defaults to OFF: shadow reads only happen when
# explicitly turned on, so root never depends on World Service being up
# unless a developer deliberately asks for the comparison.
Rails.application.config.x.world_service_url = ENV.fetch("WORLD_SERVICE_URL", "http://127.0.0.1:3001")
Rails.application.config.x.world_service_open_timeout = ENV.fetch("WORLD_SERVICE_OPEN_TIMEOUT", "1").to_f
Rails.application.config.x.world_service_read_timeout = ENV.fetch("WORLD_SERVICE_READ_TIMEOUT", "2").to_f
Rails.application.config.x.world_shadow_reads_enabled = ENV["WORLD_SHADOW_READS_ENABLED"] == "true"
