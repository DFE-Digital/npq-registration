module API
  module LoggerPayload
    def append_info_to_payload(payload)
      super
      payload[:current_user_class] = current_lead_provider&.class&.name
      payload[:current_user_id] = current_lead_provider&.id
      payload[:current_user_name] = current_lead_provider&.name

      payload[:query_params] = request.query_parameters.to_json
      payload[:request_headers] = request.env.slice(
        "HTTP_VERSION",
        "HTTP_HOST",
        "HTTP_USER_AGENT",
        "HTTP_ACCEPT",
        "HTTP_ACCEPT_ENCODING",
        "HTTP_CONNECTION",
        "HTTP_CACHE_CONTROL",
        "QUERY_STRING",
      ).transform_values(&:to_s).to_json
      payload[:request_body] = request.raw_post

      payload[:response_headers] = response.headers.transform_values(&:to_s).to_json
      if response.status != 200
        payload[:response_body] = response.body
      end
    end
  end
end