module Api
  module V1
    # Service identity/metadata only — not a domain endpoint.
    class StatusController < ApplicationController
      def show
        render json: { service: "aliens", version: "v1", status: "ok" }
      end
    end
  end
end
