require "rails_helper"

RSpec.describe GetAnIdentity::User do
  describe "#find" do
    let(:access_token) { SecureRandom.uuid }
    let(:stubbed_url) { "https://example.com" }

    let(:uid) { "123456" }

    before do
      allow(ENV).to receive(:fetch).with("TRA_OIDC_DOMAIN").and_return(stubbed_url)

      stubbed_access_token = instance_double(GetAnIdentity::AccessToken, to_s: access_token)
      allow(GetAnIdentity::AccessToken).to receive(:new).and_return(stubbed_access_token)

      stub_request(:get, "#{stubbed_url}/api/v1/users/#{uid}")
        .with(
          headers: {
            "Authorization" => "Bearer #{access_token}",
          },
        )
        .to_return(
          status: response_status_code,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" },
        )
    end

    context "when the response is successful" do
      let(:response_uid) { uid }
      let(:response_body) do
        {
          "userId" => response_uid,
          "email" => "mail@example.com",
          "firstName" => "Jane",
          "lastName" => "Doe",
          "dateOfBirth" => "1990-01-01",
          "trn" => "1234567",
          "mobileNumber" => "",
          "mergedUserIds" => [],
        }
      end

      let(:response_status_code) { 200 }

      let(:loaded_user) do
        GetAnIdentity::User.find("123456")
      end

      it "returns a user that responds to the correct attributes" do
        expect(loaded_user.id).to eq uid
        expect(loaded_user.uid).to eq response_uid
        expect(loaded_user.email).to eq "mail@example.com"
        expect(loaded_user.full_name).to eq "Jane Doe"
        expect(loaded_user.date_of_birth).to eq Date.new(1990, 1, 1)
        expect(loaded_user.trn).to eq "1234567"
        expect(loaded_user.mobile_number).to eq ""
        expect(loaded_user.merged_user_ids).to eq []
        expect(loaded_user.raw).to eq response_body
      end

      context "when uid from response does not match the requested uid" do
        let(:response_uid) { "654321" }

        it "returns a user that responds to the correct attributes" do
          expect(loaded_user.id).to eq uid
          expect(loaded_user.uid).to eq response_uid
          expect(loaded_user.email).to eq "mail@example.com"
          expect(loaded_user.full_name).to eq "Jane Doe"
          expect(loaded_user.date_of_birth).to eq Date.new(1990, 1, 1)
          expect(loaded_user.trn).to eq "1234567"
          expect(loaded_user.mobile_number).to eq ""
          expect(loaded_user.merged_user_ids).to eq []
          expect(loaded_user.raw).to eq response_body
        end
      end
    end

    context "when the user is not found" do
      let(:response_body) do
        {
          "type" => "https://tools.ietf.org/html/rfc7231#section-6.5.1",
          "title" => "Request is not valid",
          "status" => 400,
          "traceId" => SecureRandom.uuid,
          "errorCode" => 10_004,
          "errors" => { "userId" => ["The value '#{uid}' is not valid for UserId."] },
        }
      end
      let(:response_status_code) { 400 }

      it "raises an error" do
        expect { GetAnIdentity::User.find(uid) }.to raise_error(GetAnIdentity::User::NotFoundError)
      end
    end

    context "when the access token is invalid" do
      let(:response_body) { "" }
      let(:response_status_code) { 401 }

      it "raises an error" do
        expect { GetAnIdentity::User.find(uid) }.to raise_error(GetAnIdentity::User::InvalidTokenError)
      end
    end
  end
end
