module Helpers
  module JourneyHelper
    APPLICATION_COMPARISON_IGNORED_ATTRIBUTES = %i[id created_at updated_at significantly_updated_at user_id DEPRECATED_school_urn DEPRECATED_private_childcare_provider_urn DEPRECATED_itt_provider].freeze

    def latest_application
      Application.order(created_at: :asc, id: :asc).last
    end

    def latest_application_user
      latest_application&.user
    end

    def retrieve_latest_application_user_data
      latest_application_user&.as_json(except: %i[id feature_flag_id created_at updated_at significantly_updated_at updated_from_tra_at email_updates_status email_updates_unsubscribe_key])
    end

    def retrieve_latest_application_data
      latest_application&.as_json(except: APPLICATION_COMPARISON_IGNORED_ATTRIBUTES)
    end

    def default_application_data
      Application.column_defaults.without(APPLICATION_COMPARISON_IGNORED_ATTRIBUTES.map(&:to_s))
    end

    def deep_compare_application_data(expected_data)
      latest_application_data = retrieve_latest_application_data

      # Doing these separately lets us get proper diffs on raw_application_data
      expect(latest_application_data.except("raw_application_data")).to match(default_application_data.merge(expected_data).except("raw_application_data"))
      expect(latest_application_data["raw_application_data"]).to match(expected_data["raw_application_data"])
    end

    def stub_participant_validation_request(trn: "1234567", date_of_birth: "1980-12-13", nino: "AB123456C", response: {})
      stub_request(:get, "https://dqt-api.example.com/v1/teachers/#{trn}?birthdate=#{date_of_birth}&nino=#{nino}")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer test-apikey",
            "User-Agent" => "Ruby",
          },
        )
        .to_return(status: 200, body: dqt_response_body(**response), headers: {})
    end

    def stub_inactive_participant_validation_request(trn: "1234567", date_of_birth: "1980-12-13", nino: "AB123456C")
      stub_request(:get, "https://dqt-api.example.com/v1/teachers/#{trn}?birthdate=#{date_of_birth}&nino=#{nino}")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer test-apikey",
            "User-Agent" => "Ruby",
          },
        )
        .to_return(status: 200, body: dqt_inactive_response_body, headers: {})
    end
  end
end
