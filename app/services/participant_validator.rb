class ParticipantValidator
  attr_reader :trn, :full_name, :date_of_birth, :national_insurance_number

  def initialize(trn:, full_name:, date_of_birth:, national_insurance_number: nil)
    @trn = trn
    @full_name = full_name
    @date_of_birth = date_of_birth
    @national_insurance_number = national_insurance_number
  end

  def call
    return if Rails.application.config.npq_separation[:ecf_api_disabled]

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{config.bearer_token}"
    request.set_form_data(payload)

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
    @uri ||= URI(config.endpoint)
  end

  def payload
    { trn:, full_name:, date_of_birth: dob_as_string, nino: national_insurance_number }
  end

  def use_ssl?
    uri.scheme == "https"
  end

  def dob_as_string
    date_of_birth.iso8601
  end
end
