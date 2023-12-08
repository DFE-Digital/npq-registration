module Helpers
  module JourneyHelper
    def latest_application
      Application.order(created_at: :asc).last
    end

    def latest_application_user
      latest_application&.user
    end

    def retrieve_latest_application_user_data
      latest_application_user&.as_json(except: %i[id feature_flag_id created_at updated_at updated_from_tra_at])
    end

    def retrieve_latest_application_data
      latest_application&.as_json(except: %i[id created_at updated_at user_id DEPRECATED_school_urn DEPRECATED_private_childcare_provider_urn])
    end

    def deep_compare_application_data(expected_data)
      latest_application_data = retrieve_latest_application_data

      # Doing these separately lets us get proper diffs on raw_application_data
      expect(latest_application_data.except("raw_application_data")).to match(expected_data.except("raw_application_data"))
      expect(latest_application_data["raw_application_data"]).to match(expected_data["raw_application_data"])
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

    def stub_env_variables_for_gai(stubbed_url: "https://tra-domain.com", stubbed_client_id: "register-for-npq")
      stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_DOMAIN" => stubbed_url))
      stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_CLIENT_ID" => stubbed_client_id))
    end
  end
end
