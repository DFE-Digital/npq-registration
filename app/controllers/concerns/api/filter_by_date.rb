module API
  module FilterByDate
    extend ActiveSupport::Concern

  protected

    def updated_since
      date_filter(filter_name: :updated_since)
    end

    def created_since
      date_filter(filter_name: :created_since)
    end

    def date_filter(filter_name:)
      date_param = params.dig(:filter, filter_name)

      return if date_param.blank?

      Time.iso8601(URI.decode_www_form_component(date_param))
    rescue ArgumentError
      raise ActionController::BadRequest, I18n.t(:invalid_date_filter, attribute: filter_name)
    end
  end
end
