# frozen_string_literal: true

RSpec.shared_examples "an API change application funded place endpoint" do
  context "when authorized" do
    let(:params) { { data: { type: "npq-application-change-funded-place", attributes: { funded_place: true } } } }

    it "updates funded place" do
      expect { api_put(path(application_id), params:) }
        .to change { application.reload.funded_place }.to be_truthy
    end

    it "responds with 200 and representation of the application" do
      api_put(path(application_id), params:)

      expect(response).to be_successful
      expect(parsed_response.dig("data", "attributes", "funded_place")).to be_truthy
    end

    context "when funded_place is nil in the params" do
      let(:params) { { data: { type: "npq-application-change-funded-place", attributes: { funded_place: nil } } } }

      it "return 422" do
        api_put(path(application_id), params:)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error in response" do
        api_put(path(application_id), params:)

        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("The entered '#/funded_place' is missing from your request. Check details and try again.")
      end
    end

    context "with no params" do
      let(:params) { {} }

      it "return 422" do
        api_put(path(application_id), params:)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error in response" do
        api_put(path(application_id), params:)

        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("The entered '#/funded_place' is missing from your request. Check details and try again.")
      end
    end

    context "when application is not accepted" do
      before { allow_any_instance_of(Application).to receive(:accepted?).and_return(false) }

      it "returns 422 & error in response" do
        api_put(path(application_id), params:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("You must accept the application before attempting to change the '#/funded_place' setting.")
      end
    end

    context "when application is not eligible for funding" do
      before { allow_any_instance_of(Application).to receive(:eligible_for_funding?).and_return(false) }

      it "returns 422 & error in response" do
        api_put(path(application_id), params:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("This participant is not eligible for funding. Contact us if you think this is wrong.")
      end
    end

    context "when application cohort does not accept capping" do
      before { allow_any_instance_of(Cohort).to receive(:funding_cap?).and_return(false) }

      it "returns 422 & error in response" do
        api_put(path(application_id), params:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("Leave the '#/funded_place' field blank. It's only needed for participants starting NPQs from autumn 2024 onwards.")
      end
    end

    context "when the given resource ID does not exist", exceptions_app: true do
      it "returns 404" do
        api_put(path(123), params:)

        expect(response.status).to eq 404
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_put(path(application_id), token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
