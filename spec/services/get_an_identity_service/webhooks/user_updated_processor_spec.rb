require "rails_helper"

RSpec.describe GetAnIdentityService::Webhooks::UserUpdatedProcessor do
  let(:webhook_message) do
    ::GetAnIdentity::WebhookMessage.create!(
      message:,
      message_id: SecureRandom.uuid,
      message_type:,
      raw: message.to_json,
      sent_at:,
    )
  end

  let(:sent_at) { Time.zone.now }
  let(:old_email) { "mail@example.com" }
  let(:old_date_of_birth) { 30.years.ago.to_date }

  let(:user) { create(:user, :with_get_an_identity_id, email: old_email, date_of_birth: old_date_of_birth, full_name: "John Doe") }

  context "when passed the correct message_type" do
    let(:message_type) { "UserUpdated" }
    let(:message) do
      { "user" => {
          "trn" => new_trn,
          "userId" => user.get_an_identity_id,
          "lastName" => "something",
          "firstName" => "something",
          "middleName" => nil,
          "preferredName" => new_name,
          "dateOfBirth" => new_date_of_birth,
          "emailAddress" => new_email,
          "mobileNumber" => nil,
          "trnLookupStatus" => new_trn_status,
        },
        "changes" => { "firstName" => "Alkesh2Two" } }
    end

    let(:new_email) { "#{SecureRandom.uuid}@example.com" }
    let(:new_name) { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    let(:new_date_of_birth) { 20.years.ago.to_date.as_json }
    let(:new_trn) { rand(1_000_000..9_999_999).to_s }
    let(:new_trn_status) { "Found" }

    it "updates user data" do
      expect {
        described_class.call(webhook_message:)
      }.to change {
        user.reload.slice(:email, :trn, :full_name, :date_of_birth, :updated_from_tra_at).as_json
      }.from(
        "email" => old_email,
        "trn" => user.trn,
        "full_name" => "John Doe",
        "date_of_birth" => old_date_of_birth.as_json,
        "updated_from_tra_at" => nil,
      ).to({
        "email" => new_email,
        "trn" => new_trn,
        "full_name" => new_name,
        "date_of_birth" => new_date_of_birth,
        "updated_from_tra_at" => sent_at.as_json,
      })
    end

    context "when the new email is already in use" do
      before do
        create(:user, email: new_email)
      end

      it "marks the webhook_message as failed" do
        expect {
          described_class.call(webhook_message:)
        }.to change {
          webhook_message.reload.slice(:status, :status_comment)
        }.from(
          "status" => "pending",
          "status_comment" => nil,
        ).to({
          "status" => "failed",
          "status_comment" => "Email Email address must be unique",
        })
      end
    end

    context "when the trn is not present" do
      let(:new_trn) { nil }
      let(:new_trn_status) { "None" }

      it "stores the data without the TRN" do
        expect {
          described_class.call(webhook_message:)
        }.to change {
          user.reload.slice(:email, :trn, :full_name, :date_of_birth, :updated_from_tra_at).as_json
        }.from(
          "email" => old_email,
          "trn" => user.trn,
          "full_name" => "John Doe",
          "date_of_birth" => old_date_of_birth.as_json,
          "updated_from_tra_at" => nil,
        ).to({
          "email" => new_email,
          "trn" => nil,
          "full_name" => new_name,
          "date_of_birth" => new_date_of_birth,
          "updated_from_tra_at" => sent_at.as_json,
        })
      end
    end

    context "when the message is nonsense" do
      let(:message) { SecureRandom.uuid }

      it "stores the data without the TRN" do
        expect {
          described_class.call(webhook_message:)
        }.to change {
          webhook_message.reload.slice(:status, :status_comment, :raw, :message)
        }.from(
          "status" => "pending",
          "status_comment" => nil,
          "raw" => message.to_json,
          "message" => message,
        ).to({
          "status" => "failed",
          "status_comment" => "Invalid message format",
          "raw" => message.to_json,
          "message" => message,
        })
      end
    end
  end

  context "when passed the incorrect message_type" do
    let(:message_type) { "UserMerged" }
    let(:message) { { "uid" => "1234" } }

    it "marks the webhook_message as failed" do
      expect {
        described_class.call(webhook_message:)
      }.to change {
        webhook_message.reload.slice(:status, :status_comment)
      }.from(
        "status" => "pending",
        "status_comment" => nil,
      ).to({
        "status" => "failed",
        "status_comment" => "Wrong processor used for message type: #{message_type}",
      })
    end
  end
end
