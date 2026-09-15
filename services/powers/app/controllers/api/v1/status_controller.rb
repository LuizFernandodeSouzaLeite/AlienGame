module Api
  module V1
    # Service identity/metadata only — not a domain endpoint. No Power data
    # is exposed here; that is the /api/v1/powers resource below.
    class StatusController < ApplicationController
      def show
        render json: { service: "powers", version: "v1", status: "ok" }
      end
    end
  end
end
