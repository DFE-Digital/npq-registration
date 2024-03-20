require "api/version"

module API
  class DocumentationController < ApplicationController
    layout "api_docs"

    def index
      @version = params[:version]

      raise ActionController::RoutingError, "Not found" unless API::Version.exists?(@version)
    end
  end
end
