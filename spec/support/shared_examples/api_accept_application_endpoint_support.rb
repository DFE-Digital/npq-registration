# frozen_string_literal: true

RSpec.shared_examples "an API accept application endpoint" do
  context "when authorized" do
    it "updates status to accepted" do
      expect { api_post(path(application_id)) }
        .to change { application.reload.lead_provider_approval_status }.from("pending").to("accepted")
    end

    it "responds with 200 and representation of the application" do
      api_post(path(application_id))

      expect(response).to be_successful
      expect(parsed_response.dig("data", "attributes", "status")).to eql("accepted")
    end

    context "when participant has applied for multiple NPQs" do
      let!(:another_application) { create(:application, cohort: application.cohort, course: application.course, user: application.user) }
      let(:another_course) { create(:course, :lt) }
      let!(:another_accepted_application) { create(:application, :accepted, course: another_course, lead_provider: current_lead_provider, user: application.user) }

      it "rejects all pending NPQs on same course & cohort" do
        api_post(path(application_id))

        expect(another_application.reload.lead_provider_approval_status).to eql("rejected")
      end

      it "does not reject non-pending NPQs on same course & cohort" do
        api_post(path(application_id))

        expect(another_accepted_application.reload.lead_provider_approval_status).to eql("accepted")
      end
    end

    context "when application has been rejected" do
      let(:application) { create(:application, :rejected, lead_provider: current_lead_provider) }

      it "returns 422" do
        api_post(path(application_id))

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error in response" do
        api_post(path(application_id))

        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("Once rejected an application cannot change state")
      end
    end

    context "when the given resource ID does not exist", exceptions_app: true do
      it "returns 404" do
        api_post(path(123))

        expect(response.status).to eq 404
      end
    end

    describe "NPQ capping" do
      let(:params) { { data: { type: "npq-application-accept", attributes: { funded_place: true } } } }

      before do
        application.update!(eligible_for_funding: true)
        application.cohort.update!(funding_cap: true)
      end

      it "updates funded place attribute" do
        api_post(path(application_id), params:)

        expect(application.reload.funded_place).to be_truthy
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_post(path(application_id), token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
