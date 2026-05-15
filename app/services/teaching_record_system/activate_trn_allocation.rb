module TeachingRecordSystem
  class ActivateTrnAllocation
    class << self
      def activate!(access_token)
        new(access_token).activate!
      end
    end

    def initialize(access_token)
      @access_token = access_token
    end

    def activate!
      return nil if response.nil?
      return nil unless response["status"] == "Completed"

      response.fetch("trn")
    end

  private

    def trs_api
      Faraday.new(url: ENV.fetch("TRS_API_URL")) do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.request :json
        conn.response :raise_error
        conn.response :json
      end
    end

    def activate_path
      "/v3/trn-request/activate"
    end

    def response
      @response ||= trs_api.put(activate_path).body
    end
  end
end
