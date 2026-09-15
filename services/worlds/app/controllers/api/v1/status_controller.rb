module Api
  module V1
    # Service identity/metadata only — not a domain endpoint. No Planet data
    # is exposed here; that is Phase 3 (World API contract) work.
    class StatusController < ApplicationController
      def show
        render json: { service: "worlds", version: "v1", status: "ok" }
      end
    end
  end
end
