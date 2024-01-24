require "swagger_helper"

RSpec.describe "api/applications", type: :request do
  path "/applications/{id}" do
    get "Retrieves an application" do
      tags "Applications"
      produces "application/json", "application/xml"
      parameter name: :id, in: :path, type: :string

      response "200", "application found" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 lead_provider_id: { type: :integer },
                 user_id: { type: :integer },
                 lead_provider_approval_status: { type: :string },
                 participant_outcome_state: { type: :string },
               },
               required: %w[id user_id lead_provider_approval_status]

        let(:id) { create(:application).id }
        run_test!
      end

      response "404", "application not found" do
        let(:id) { "invalid" }
        run_test!
      end

      response "406", "unsupported accept header" do
        let(:Accept) { "application/foo" }
        run_test!
      end
    end
  end
end
