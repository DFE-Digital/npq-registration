# frozen_string_literal: true

RSpec.shared_examples "an API create declaration endpoint" do
  context "when authorized" do
    let(:params) do
      {
        data: {
          type: "participant-declaration",
          attributes: {
            participant_id:,
            declaration_type:,
            declaration_date:,
            course_identifier:,
            has_passed:,
          },
        },
      }
    end
    let(:mock_declaration) { build(:declaration) }
    let(:stub_service) do
      service_double = instance_double(service, save: true, **service_args)
      allow(service).to receive(:new) { |args|
        expect(args.to_hash.symbolize_keys).to eq(service_args)
      }.and_return(service_double)
      allow(service_double).to receive(:declaration).and_return(mock_declaration)
      service_double
    end

    it "creates a declaration" do
      expect { api_post(path, params:) }.to change(participant.declarations.reload, :count).by(1)
    end

    it "responds with 200 and representation of the declaration" do
      api_post(path, params:)

      expect(response).to be_successful
      expect(parsed_response.dig("data", "attributes", "participant_id")).to eql(participant_id)
    end

    context "when the participant is eligible" do
      before { application.update!(eligible_for_funding: true) }

      it "create eligible declaration record" do
        api_post(path, params:)

        expect(response).to be_successful

        expect(parsed_response.dig("data", "attributes", "state")).to eq("eligible")
      end
    end

    it "calls the correct service" do
      service_double = stub_service

      api_post(path, params:)

      expect(service_double).to have_received("save")
    end

    it "calls the correct serializer" do
      stub_service

      serializer_params = { root: "data" }
      serializer_params[:view] = serializer_version if defined?(serializer_version)
      allow(serializer).to receive(:render).with(mock_declaration, **serializer_params).and_call_original

      api_post(path, params:)
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_post(path, token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end
