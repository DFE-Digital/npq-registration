require "rails_helper"

RSpec.describe Services::EcfUserCreator do
  let(:user) { User.create!(email: "john.doe@example.com", full_name: "John Doe") }

  subject { described_class.new(user: user) }

  describe "#call" do
    let(:request_body) do
      {
        data: {
          type: "users",
          attributes: {
            email: "john.doe@example.com",
            full_name: "John Doe",
          },
        },
      }.to_json
    end

    let(:response_body) do
      {
        data: {
          type: "user",
          id: "123",
        },
      }.to_json
    end

    before do
      stub_request(:post, "https://ecf-app.gov.uk/api/v1/users")
        .with(
          body: request_body,
          headers: {
            "Accept" => "application/vnd.api+json",
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            "Content-Type" => "application/vnd.api+json",
          },
        )
        .to_return(
          status: 201,
          body: response_body,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    it "sets user.ecf_id with returned guid" do
      subject.call
      user.reload
      expect(user.ecf_id).to eql("123")
    end
  end
end
