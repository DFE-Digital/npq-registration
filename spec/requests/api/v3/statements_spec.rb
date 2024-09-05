require "rails_helper"

RSpec.describe "Statements endpoint", type: "request" do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Statements::Query }
  let(:serializer) { API::StatementSerializer }

  describe "GET /api/v3/statements" do
    let(:path) { api_v3_statements_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:statement, **attrs)
    end

    def create_resource(created_since: nil, updated_since: nil, **attrs)
      statement = create(:statement, **attrs)
      statement.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
      statement.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations

      statement
    end

    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end
end
