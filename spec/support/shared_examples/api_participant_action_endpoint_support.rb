# frozen_string_literal: true

RSpec.shared_examples "an API participant action endpoint" do |service|
  let(:params) do
    {
      data: {
        attributes: { course_identifier: }.tap { |h| h[:reason] = reason if defined?(reason) },
      },
    }
  end

  context "when authorized" do
    context "when the participant exists" do
      it "returns the participant" do
        api_put(path(participant_id), params:)

        expect(response.status).to eq 200
        expect(response.content_type).to eql("application/json")
        expect(parsed_response["data"]["id"]).to eq(participant_id)

        assert_on_successful_response(parsed_response) if defined?(assert_on_successful_response)
      end

      it "calls the correct service" do
        action = service.name.demodulize.downcase.to_sym
        service_double = instance_double(service, "#{action}": true, participant:)

        allow(service).to receive(:new) { |args|
          expect(args[:participant]).to eq(participant)
          expect(args[:lead_provider]).to eq(current_lead_provider)
          expect(args[:course_identifier]).to eq(course_identifier)
          expect(args[:reason]).to eq(reason) if defined?(reason)
        }.and_return(service_double)

        api_put(path(participant_id), params:)

        expect(service_double).to have_received(action)
      end

      it "calls the correct serializer" do
        serializer_params = { root: "data" }
        serializer_params[:view] = serializer_version if defined?(serializer_version)
        serializer_params[:lead_provider] = serializer_lead_provider if defined?(serializer_lead_provider)

        expect(serializer).to receive(:render).with(participant, **serializer_params).and_call_original

        api_put(path(participant_id), params:)
      end

      context "when the request body is malformed" do
        it "raises an error" do
          api_put(path(participant_id), params: { data: { attributes: {} } })

          expect(response.status).to eq 400
          expect(response.content_type).to eql("application/json")
          expect(parsed_response["errors"][0]).to include({
            "title" => "Bad request",
            "detail" => I18n.t(:invalid_data_structure),
          })
        end
      end
    end

    context "when the participant does not exist", exceptions_app: true do
      it "returns not found" do
        api_put(path("123XXX"), params:)

        expect(response.status).to eq(404)
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_put(path(participant_id), params:, token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
