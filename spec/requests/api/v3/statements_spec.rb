require "rails_helper"

RSpec.describe "Statements endpoint", type: "request" do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Statements::Query }
  let(:serializer) { API::StatementSerializer }

  describe "GET /api/v3/statements" do
    let(:path) { api_v3_statements_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(travel_to_time: Time.zone.now, **attrs)
      travel_to(travel_to_time) do
        create(:statement, **attrs)
      end
    end

    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end
end
