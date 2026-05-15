module TeachingRecordSystem
  class ActivateTrnAllocation
    class NoTrnRequestToActivate < RuntimeError; end

    TRN_REQUEST_PATH = "/v3/trn-request".freeze
    ACTIVATE_PATH = "/v3/trn-request/activate".freeze

    class << self
      def activate!(access_token)
        new(access_token).activate!
      end
    end

    def initialize(access_token)
      @access_token = access_token
    end

    def trn_request
      @trn_request = trs_api.get(TRN_REQUEST_PATH).body
    rescue Faraday::ResourceNotFound
      raise NoTrnRequestToActivate
    end

    def activate!
      trn_request # check for trn_requests existance

      return nil if activation.nil?
      return nil unless activation["status"] == "Completed"

      activation.fetch("trn")
    end

  private

    def trs_api
      Faraday.new(url: ENV.fetch("TRS_API_URL")) do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.request :json
        conn.headers["X-Api-Version"] = "20260416"
        conn.response :raise_error
        conn.response :json
        conn.response :logger, Rails.logger if Rails.env.local?
      end
    end

    def activation
      @activation ||= trs_api.put(ACTIVATE_PATH).body
    end
  end
end
