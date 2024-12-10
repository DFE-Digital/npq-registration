require "rails_helper"

RSpec.describe Ecf::EcfUserFinder do
  subject { described_class.new(user:) }

  let(:user) { User.create!(email: "john.doe@example.com", full_name: "John Doe") }

  describe "#call" do
    let!(:get_ecf_stub) do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/users?filter[email]=john.doe@example.com&page[page]=1&page[per_page]=1")
        .with(
          headers: {
            "Accept" => "application/vnd.api+json",
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            "Content-Type" => "application/vnd.api+json",
          },
        )
        .to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    context "when user exists" do
      let(:response_body) do
        {
          data: [{
            type: "user",
            id: "123",
            attributes: {
              email: user.email,
            },
          }],
        }.to_json
      end

      it "calls ecf to get a user profile" do
        subject.call

        expect(get_ecf_stub).to have_been_requested
      end

      it "returns the user" do
        object = subject.call

        expect(object).to be_a(External::EcfAPI::User)
        expect(object.id).to be_present
        expect(object.email).to eql(user.email)
      end
    end

    context "when user does not exist" do
      let(:response_body) do
        {
          data: [],
        }.to_json
      end

      it "returns nil" do
        expect(subject.call).to be_nil
      end
    end

    context "when ecf_api_disabled flag is toggled on" do
      let(:response_body) { "anything" }

      before { Flipper.enable(Feature::ECF_API_DISABLED) }

      it "does not call ecf" do
        subject.call

        expect(get_ecf_stub).not_to have_been_requested
      end
    end
  end
end
