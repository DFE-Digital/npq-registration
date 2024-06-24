# frozen_string_literal: true

RSpec.shared_examples "an API update endpoint" do
  context "when authorized" do
    context "when the resource exists" do
      it "returns the resource" do
        api_put(path(resource_id))

        expect(response.status).to eq 200
        expect(response.content_type).to eql("application/json")
        expect(parsed_response["data"]["id"]).to eq(resource_id)
      end

      it "calls the correct service" do
        action = service.name.demodulize.downcase.to_sym
        service_double = instance_double(service, "#{action}": true, **service_args)

        allow(service).to receive(:new).with(service_args).and_return(service_double)

        api_put(path(resource_id))

        expect(service_double).to have_received(action)
      end

      it "calls the correct serializer" do
        serializer_params = { root: "data" }
        serializer_params[:view] = serializer_version if defined?(serializer_version)
        serializer_params[:lead_provider] = serializer_lead_provider if defined?(serializer_lead_provider)

        expect(serializer).to receive(:render).with(resource, **serializer_params).and_call_original

        api_put(path(resource_id))
      end
    end

    context "when the resource does not exist", exceptions_app: true do
      it "returns not found" do
        api_put(path("123XXX"))

        expect(response.status).to eq(404)
      end
    end

    context "when the service has errors", exceptions_app: true do
      it "returns 422 - unprocessable entity" do
        action = service.name.demodulize.downcase.to_sym
        errors = instance_double("errors", messages: { attr: %w[error] })
        service_double = instance_double(service, "#{action}": false, errors:)

        allow(service).to receive(:new).with(service_args).and_return(service_double)

        api_put(path(resource_id))

        expect(response.status).to eq(422)
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_put(path(resource_id), token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
