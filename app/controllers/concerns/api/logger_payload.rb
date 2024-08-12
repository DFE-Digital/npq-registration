module API
  module LoggerPayload
    def append_info_to_payload(payload)
      super
      params = {}

      params[:current_user_class] = current_lead_provider&.class&.name
      params[:current_user_id] = current_lead_provider&.id
      params[:current_user_name] = current_lead_provider&.name

      params[:request_query_params] = request.query_parameters&.to_hash
      params[:request_headers] = request.env.slice(
        "HTTP_HOST",
        "HTTP_ACCEPT",
        "HTTP_ACCEPT_ENCODING",
        "HTTP_CONNECTION",
        "HTTP_CACHE_CONTROL",
      ).transform_values(&:to_s)
      params[:request_body] = request.raw_post

      params[:response_headers] = response.headers.transform_values(&:to_s)
      if response.status != 200
        params[:response_body] = response.body
      end

      params.transform_values! do |val|
        if val.is_a?(Hash)
          val = val.present? ? val.to_json : nil
        end

        val.presence
      end

      payload.merge!(params)
    end
  end
end
