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
      latest_application_user&.as_json(except: %i[id feature_flag_id created_at updated_at significantly_updated_at updated_from_tra_at email_updates_status email_updates_unsubscribe_key previous_names])
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
  end
end
