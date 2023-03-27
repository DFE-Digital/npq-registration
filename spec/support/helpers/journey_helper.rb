module Helpers
  module JourneyHelper
    def latest_application
      Application.order(created_at: :asc).last
    end

    def latest_application_user
      latest_application&.user
    end

    def retrieve_latest_application_user_data
      latest_application_user&.as_json(except: %i[id feature_flag_id created_at updated_at])
    end

    def retrieve_latest_application_data
      latest_application&.as_json(except: %i[id created_at updated_at user_id])
    end

    def stub_participant_validation_request(trn: "1234567", date_of_birth: "1980-12-13", full_name: "John Doe", nino: "AB123456C", response: {})
      stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
          body: { trn:, date_of_birth:, full_name:, nino: },
        )
        .to_return(status: 200, body: participant_validator_response(**response), headers: {})
    end

    def stub_previously_funded_request(get_an_identity_id:, npq_course_identifier:, trn: "1234567")
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq/previous_funding?get_an_identity_id=#{get_an_identity_id}&npq_course_identifier=#{npq_course_identifier}&trn=#{trn}")
        .with(
          headers: {
            "Accept" => "application/vnd.api+json",
            "Accept-Encoding" => "gzip,deflate",
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            "Content-Type" => "application/vnd.api+json",
            "User-Agent" => "Faraday v1.10.0",
          },
        )
        .to_return(status: 200, body: "", headers: {})
    end
  end
end
