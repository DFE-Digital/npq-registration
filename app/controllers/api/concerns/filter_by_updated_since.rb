module API
  module Concerns
    module FilterByUpdatedSince
      extend ActiveSupport::Concern

    protected

      def updated_since
        params.dig(:filter, :updated_since)
      end

      def validate_updated_since
        return if updated_since.blank?

        Time.iso8601(URI.decode_www_form_component(updated_since))
      rescue ArgumentError
        raise ActionController::BadRequest, I18n.t(:invalid_updated_since_filter)
      end
    end
  end
end
