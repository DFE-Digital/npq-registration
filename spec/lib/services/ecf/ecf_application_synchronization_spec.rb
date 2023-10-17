require "rails_helper"

RSpec.describe Services::Ecf::EcfApplicationSynchronization do
  describe "#call" do
    let(:service) { described_class.new }
    let(:get_an_identity_id) { SecureRandom.uuid }
    let(:response_data) { [{ id: get_an_identity_id, type: "application_synchronization", "attributes" => { "id" => get_an_identity_id, "lead_provider_approval_status" => "accepted", "participant_outcome_state" => "passed" } }] }
    let(:success_response) { instance_double("response", is_a?: Net::HTTPSuccess, body: { "data" => response_data }.to_json) }

    before do
      stub_request(:get, "https://ecf-app.gov.uk:443/api/v1/npq/application_synchronizations")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          "Host" => "ecf-app.gov.uk",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 200, body: "", headers: {})
    end

    context "when successful" do
      it "sends a GET request to the correct endpoint with the authorization header" do
        uri = URI.parse("https://ecf-app.gov.uk/api/v1/npq/application_synchronizations")
        request = instance_double("Net::HTTP::Get")
        http = instance_double("Net::HTTP")

        allow(URI).to receive(:parse).with("https://ecf-app.gov.uk/api/v1/npq/application_synchronizations").and_return(uri)
        allow(http).to receive(:request).with(request).and_return(success_response)

        service.call
      end

      it "updates the statuses in relevant applications" do
        application = create(:application, ecf_id: 1)
        allow(Application).to receive(:where).and_return([application])

        allow(application).to receive(:update).with(
          lead_provider_approval_status: "accepted",
          participant_outcome_state: "passed",
        )

        service.call
      end

      it "builds the correct URI with the query parameter" do
        ecf_ids = SecureRandom.uuid
        uri = URI.parse("https://ecf-app.gov.uk/api/v1/npq/application_synchronizations")
        request = instance_double("Net::HTTP::Get")
        http = instance_double("Net::HTTP")

        allow(URI).to receive(:parse).with("https://ecf-app.gov.uk/api/v1/npq/application_synchronizations").and_return(uri)
        allow(http).to receive(:request).with(request).and_return(success_response)

        uri.query = "ecf_ids=#{ecf_ids}"

        service.call
      end
    end

    context "when an error occurs" do
      it "logs the error message" do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError, "Some error message")

        logger = instance_double("ActiveSupport::Logger")
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error).with("An error occurred during application synchronization: Some error message")

        service.call
      end
    end
  end
end
