require "rails_helper"

RSpec.describe Services::Ecf::EcfUserFinder do
  subject { described_class.new(user:) }

  let(:user) { User.create!(email: "john.doe@example.com", full_name: "John Doe") }

  describe "#call" do
    before do
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

      it "returns the user" do
        object = subject.call

        expect(object).to be_a(EcfApi::User)
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
  end
end
