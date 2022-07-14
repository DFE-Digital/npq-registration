module Helpers
  module JourneyHelper
    def latest_application
      Application.order(created_at: :asc).last
    end

    def latest_application_user
      latest_application&.user
    end

    def retrieve_latest_application_user_data
      latest_application_user&.as_json(except: %i[id created_at updated_at])
    end

    def retrieve_latest_application_data
      latest_application&.as_json(except: %i[id created_at updated_at user_id])
    end
  end
end
