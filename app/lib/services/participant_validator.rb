module Services
  class ParticipantValidator
    attr_reader :trn, :full_name, :date_of_birth, :national_insurance_number

    def initialize(trn:, full_name:, date_of_birth:, national_insurance_number: nil)
      @trn = trn
      @full_name = full_name
      @date_of_birth = date_of_birth
      @national_insurance_number = national_insurance_number
    end

    def call
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{config.bearer_token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?, read_timeout: 20) do |http|
        http.request(request)
      end

      if response.code == "404"
        nil
      else
        OpenStruct.new(JSON.parse(response.body)["data"]["attributes"])
      end
    end

  private

    def config
      @config ||= OpenStruct.new(
        bearer_token: ENV["ECF_APP_BEARER_TOKEN"],
        endpoint: "#{ENV['ECF_APP_BASE_URL']}/api/v1/participant-validation",
      )
    end

    def uri
      @uri ||= URI("#{config.endpoint}/#{trn}?full_name=#{full_name}&date_of_birth=#{dob_as_string}&nino=#{national_insurance_number}")
    end

    def use_ssl?
      case uri.scheme
      when "https"
        true
      else
        false
      end
    end

    def dob_as_string
      date_of_birth.iso8601
    end
  end
end
