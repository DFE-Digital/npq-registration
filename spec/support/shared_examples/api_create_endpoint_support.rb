# frozen_string_literal: true

RSpec.shared_examples "an API create endpoint" do
  let(:params) { defined?(attributes) ? { data: { attributes: } } : nil }
  let(:stub_service) do
    service_double = instance_double(service, "#{action}": true, **service_args.merge(defined?(service_methods) ? service_methods : {}))
    allow(service).to receive(:new) { |args|
      expect(args.to_hash.symbolize_keys).to eq(service_args)
    }.and_return(service_double)
    allow(service_double).to receive(resource_name).and_return(resource) if defined?(resource_name)
    service_double
  end

  context "when authorized" do
    it "returns the resource" do
      stub_service

      api_post(path, params:)

      expect(response.status).to eq 200
      expect(response.content_type).to eql("application/json")
      expect(parsed_response["data"]["id"]).to eq(resource_id)
    end

    it "calls the correct service" do
      service_double = stub_service

      api_post(path, params:)

      expect(service_double).to have_received(action)
    end

    it "calls the correct serializer" do
      stub_service

      serializer_params = { root: "data" }
      serializer_params[:view] = serializer_version if defined?(serializer_version)
      serializer_params[:lead_provider] = serializer_lead_provider if defined?(serializer_lead_provider)

      expect(serializer).to receive(:render).with(resource, **serializer_params).and_call_original

      api_post(path, params:)
    end

    context "when the service has errors", :exceptions_app do
      it "returns 422 - unprocessable entity" do
        errors = instance_double(ActiveModel::Errors, messages: { attr: %w[error] })
        service_double = instance_double(service, "#{action}": false, errors:)
        allow(service).to receive(:new) { |args|
          expect(args.to_hash.symbolize_keys).to eq(service_args)
        }.and_return(service_double)

        api_post(path, params:)

        expect(response.status).to eq(422)
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_post(path, params:, token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
