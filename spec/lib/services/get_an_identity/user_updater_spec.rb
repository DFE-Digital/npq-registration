require "rails_helper"

RSpec.describe Services::GetAnIdentity::UserUpdater do
  let(:access_token) { SecureRandom.uuid }
  let(:stubbed_url) { "https://example.com" }

  let(:uid) { SecureRandom.uuid }
  let(:response_uid) { SecureRandom.uuid }
  let(:response_email) { "mail@example.com" }
  let(:response_first_name) { "Jane" }
  let(:response_last_name) { "Doe" }
  let(:response_date_of_birth) { "1990-01-01" }
  let(:response_trn) { "1234567" }
  let(:response_mobile_number) { "" }
  let(:response_merged_user_ids) { [] }

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

  let(:user) { create(:user, :with_get_an_identity_id, get_an_identity_id: uid) }

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

  it "updates the user" do
    frozen_at = Time.zone.now.at_beginning_of_day

    travel_to frozen_at do
      expect {
        described_class.call(user:)
      }.to change {
        user.reload.slice(
          :full_name,
          :date_of_birth,
          :trn,
          :uid,
          :email,
          :updated_from_tra_at,
        )
      }.to(
        {
          "full_name" => "Jane Doe",
          "date_of_birth" => Date.new(1990, 1, 1),
          "trn" => "1234567",
          "uid" => response_uid,
          "email" => "mail@example.com",
          "updated_from_tra_at" => frozen_at,
        },
      )
    end
  end

  context "when the user is not found" do
    let(:response_status_code) { 400 }

    it "raises an error" do
      expect {
        described_class.call(user:)
      }.to raise_error(::GetAnIdentity::User::NotFoundError)
    end
  end

  context "when the access token is invalid" do
    let(:response_status_code) { 401 }

    it "raises an error" do
      expect {
        described_class.call(user:)
      }.to raise_error(::GetAnIdentity::User::InvalidTokenError)
    end
  end
end
