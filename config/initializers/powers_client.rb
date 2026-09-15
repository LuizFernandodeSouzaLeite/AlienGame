# Phase 8 SOA migration (ADR-004). Power Service is not authoritative for
# reads yet — this only configures the boundary used for shadow reads
# (see app/clients/powers_client.rb, app/services/powers/).
#
# POWER_SERVICE_URL defaults to the local development Power Service.
# POWER_SHADOW_READS_ENABLED defaults to OFF: shadow reads only happen when
# explicitly turned on, so root never depends on Power Service being up
# unless a developer deliberately asks for the comparison.
Rails.application.config.x.power_service_url = ENV.fetch("POWER_SERVICE_URL", "http://127.0.0.1:3002")
Rails.application.config.x.power_service_open_timeout = ENV.fetch("POWER_SERVICE_OPEN_TIMEOUT", "1").to_f
Rails.application.config.x.power_service_read_timeout = ENV.fetch("POWER_SERVICE_READ_TIMEOUT", "2").to_f
Rails.application.config.x.power_shadow_reads_enabled = ENV["POWER_SHADOW_READS_ENABLED"] == "true"
