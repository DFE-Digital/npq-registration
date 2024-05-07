module API
  module Concerns
    module FilterByUpdatedSince
      extend ActiveSupport::Concern

    protected

      def updated_since
        updated_since_param = params.dig(:filter, :updated_since)

        return if updated_since_param.blank?

        Time.iso8601(URI.decode_www_form_component(updated_since_param))
      rescue ArgumentError
        raise ActionController::BadRequest, I18n.t(:invalid_updated_since_filter)
      end
    end
  end
end
