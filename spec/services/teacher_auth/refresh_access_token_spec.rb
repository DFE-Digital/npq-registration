require "rails_helper"

RSpec.describe TeacherAuth::RefreshAccessToken do
  let(:refresh_token) { "old-refresh-token" }
  let(:new_refresh_token) { "new-refresh-token" }
  let(:base_url) { Rails.configuration.x.teacher_auth.domain.to_s.chomp("/") }
  let(:token_url) { "#{base_url}/oauth2/token" }
  let(:client_id) { Rails.configuration.x.teacher_auth.client_id }
  let(:client_secret) { Rails.configuration.x.teacher_auth.client_secret }

  describe ".call" do
    context "when successful" do
      let!(:stub) do
        stub_request(:post, token_url)
          .to_return(
            status: 200,
            body: { access_token: "new-access", refresh_token: new_refresh_token, expires_in: 3600 }.to_json,
            headers: { "Content-Type" => "application/json" },
          )
      end

      it "returns the new refresh token" do
        expect(described_class.call(refresh_token:)).to eq(new_refresh_token)
      end

      it "POSTs the expected form-encoded body" do
        described_class.call(refresh_token:)

        expect(stub).to have_been_requested
        expect(WebMock).to(have_requested(:post, token_url)
          .with do |req|
            req.headers["Content-Type"] == "application/x-www-form-urlencoded" &&
              URI.decode_www_form(req.body).to_h == {
                "grant_type" => "refresh_token",
                "refresh_token" => refresh_token,
                "client_id" => client_id,
                "client_secret" => client_secret,
              }
          end)
      end
    end

    context "when the refresh token is rejected (400)" do
      before do
        stub_request(:post, token_url)
          .to_return(status: 400, body: { error: "invalid_grant" }.to_json)
      end

      it "raises an HTTParty::ResponseError" do
        expect {
          described_class.call(refresh_token:)
        }.to raise_error(HTTParty::ResponseError)
      end
    end

    context "when the server errors (500)" do
      before do
        stub_request(:post, token_url).to_return(status: 500)
      end

      it "raises an HTTParty::ResponseError" do
        expect {
          described_class.call(refresh_token:)
        }.to raise_error(HTTParty::ResponseError)
      end
    end
  end
end
