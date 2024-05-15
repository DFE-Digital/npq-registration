RSpec.shared_examples "an API reject application endpoint" do
  context "when authorized" do
    context "when application is pending" do
      let(:application) { create(:application, :pending, lead_provider: current_lead_provider) }

      it "returns successfully" do
        api_post(path(application.ecf_id))

        expect(response).to be_successful
        expect(response.content_type).to eql("application/json")

        expect(parsed_response.dig("data", "attributes", "status")).to eql("rejected")
      end

      it "calls the correct service" do
        mock_service = instance_double(service_class)
        allow(service_class).to receive(:new).with(application:).and_return(mock_service)
        allow(mock_service).to receive(:reject).and_return(true)
        allow(mock_service).to receive(:application).and_return(application)

        serializer_params = { root: "data" }
        serializer_params[:view] = serializer_version if defined?(serializer_version)
        expect(serializer).to receive(:render).with(application, **serializer_params).and_call_original

        api_post(path(application.ecf_id))
      end
    end

    context "when application is accepted" do
      let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }

      it "returns error" do
        api_post(path(application.ecf_id))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eql("application/json")

        expect(parsed_response).to be_key("errors")
        expect(parsed_response.dig("errors", 0, "title")).to eql("application")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("Once accepted an application cannot change state")
      end
    end
  end

  context "when unauthorized" do
    let(:application) { create(:application, lead_provider: current_lead_provider) }

    it "returns 401 - unauthorized" do
      api_post(path(application.ecf_id), token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
