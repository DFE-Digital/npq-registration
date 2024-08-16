# frozen_string_literal: true

RSpec.shared_examples "an API show endpoint" do
  context "when authorized" do
    context "when the resource exists" do
      it "returns the resource" do
        api_get(path(resource_id))

        expect(response.status).to eq 200
        expect(response.content_type).to eql("application/json")
        expect(parsed_response["data"]["id"]).to eq(resource_id)
      end

      it "calls the correct query/serializer" do
        serializer_params = { root: "data" }
        serializer_params[:view] = serializer_version if defined?(serializer_version)
        serializer_params[:lead_provider] = serializer_lead_provider if defined?(serializer_lead_provider)

        expect(serializer).to receive(:render).with(resource, **serializer_params).and_call_original
        expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider)).and_call_original

        api_get(path(resource_id))
      end
    end

    context "when the resource does not exist", :exceptions_app do
      it "returns not found" do
        api_get(path("123XXX"))

        expect(response.status).to eq(404)
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_get(path(resource_id), token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
