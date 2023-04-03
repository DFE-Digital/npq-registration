module Helpers
  module JourneyHelper
    def latest_application
      Application.order(created_at: :asc).last
    end

    def latest_application_user
      latest_application&.user
    end

    def retrieve_latest_application_user_data
      latest_application_user&.as_json(except: %i[id feature_flag_id created_at updated_at flipper_admin_access])
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
  end
end
