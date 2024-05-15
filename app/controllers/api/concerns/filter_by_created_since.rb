module API
  module Concerns
    module FilterByCreatedSince
      extend ActiveSupport::Concern

    protected

      def created_since
        created_since_param = params.dig(:filter, :created_since)

        return if created_since_param.blank?

        Time.iso8601(URI.decode_www_form_component(created_since_param))
      rescue ArgumentError
        raise ActionController::BadRequest, I18n.t(:invalid_created_since_filter)
      end
    end
  end
end
