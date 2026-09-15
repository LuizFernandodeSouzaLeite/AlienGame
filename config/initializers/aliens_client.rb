# Phase 9 SOA migration (ADR-004). Alien Service is not authoritative for
# reads yet — this only configures the boundary used for shadow reads
# (see app/clients/aliens_client.rb, app/services/aliens/).
#
# ALIEN_SERVICE_URL defaults to the local development Alien Service.
# ALIEN_SHADOW_READS_ENABLED defaults to OFF: shadow reads only happen when
# explicitly turned on, so root never depends on Alien Service being up
# unless a developer deliberately asks for the comparison.
Rails.application.config.x.alien_service_url = ENV.fetch("ALIEN_SERVICE_URL", "http://127.0.0.1:3003")
Rails.application.config.x.alien_service_open_timeout = ENV.fetch("ALIEN_SERVICE_OPEN_TIMEOUT", "1").to_f
Rails.application.config.x.alien_service_read_timeout = ENV.fetch("ALIEN_SERVICE_READ_TIMEOUT", "2").to_f
Rails.application.config.x.alien_shadow_reads_enabled = ENV["ALIEN_SHADOW_READS_ENABLED"] == "true"
