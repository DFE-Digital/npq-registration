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
  let(:old_trn) { "1234567" }
  let(:old_trn_verified) { false }
  let(:old_trn_lookup_status) { nil }
  let(:old_name) { "John Doe" }

  let(:user) do
    create(:user,
           :with_get_an_identity_id,
           email: old_email,
           date_of_birth: old_date_of_birth,
           full_name: old_name,
           trn: old_trn,
           trn_lookup_status: old_trn_lookup_status,
           trn_verified: old_trn_verified)
  end

  subject { described_class.call(webhook_message:) }

  before { freeze_time }

  context "when passed the correct message_type" do
    let(:message_type) { "UserUpdated" }
    let(:message) do
      { "user" => {
          "trn" => new_trn,
          "userId" => user.get_an_identity_id,
          "lastName" => new_last_name,
          "firstName" => new_first_name,
          "middleName" => nil,
          "preferredName" => new_preferred_name,
          "dateOfBirth" => new_date_of_birth,
          "emailAddress" => new_email,
          "mobileNumber" => nil,
          "trnLookupStatus" => new_trn_status,
        },
        "changes" => { "firstName" => "Alkesh2Two" } }
    end

    let(:new_email) { "#{SecureRandom.uuid}@example.com" }
    let(:new_first_name) { Faker::Name.first_name }
    let(:new_last_name) { Faker::Name.last_name }
    let(:new_preferred_name) { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    let(:new_date_of_birth) { 20.years.ago.to_date }
    let(:new_trn) { rand(1_000_000..9_999_999).to_s }
    let(:new_trn_status) { "Found" }

    it "updates user data" do
      expect {
        subject
        user.reload
      }
        .to change(user, :email).from(old_email).to(new_email)
        .and change(user, :trn).from(old_trn).to(new_trn)
        .and change(user, :trn_verified).from(false).to(true)
        .and change(user, :trn_lookup_status).from(nil).to(new_trn_status)
        .and change(user, :full_name).from("John Doe").to("#{new_first_name} #{new_last_name}")
        .and change(user, :preferred_name).from(nil).to(new_preferred_name)
        .and change(user, :date_of_birth).from(old_date_of_birth).to(new_date_of_birth)
        .and change(user, :updated_from_tra_at).from(nil).to(sent_at)
    end

    with_versioning do
      it "saves the proper papertrail whodunnit attribute" do
        subject

        expect(user.reload.versions.last.whodunnit).to eq("UserUpdatedProcessor")
      end
    end

    context "when the new email is already in use" do
      before do
        create(:user, email: new_email)
      end

      it "marks the webhook_message as failed" do
        expect {
          subject
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

    context "when the TRN is not present" do
      let(:new_trn) { nil }
      let(:new_trn_status) { "None" }

      it "stores the data without changing the TRN" do
        expect {
          subject
          user.reload
        }
          .to change(user, :updated_from_tra_at).to(sent_at)
         .and not_change { user.trn }.from(old_trn)
      end
    end

    context "when there are no new attributes in the webhook" do
      let(:old_trn_verified) { true }
      let(:old_trn_lookup_status) { "Found" }

      let(:new_email) { old_email }
      let(:new_name) { old_name }
      let(:new_date_of_birth) { old_date_of_birth }
      let(:new_trn) { old_trn }
      let(:new_first_name) { "John" }
      let(:new_last_name) { "Doe" }
      let(:new_preferred_name) { nil }

      before do
        subject
      end

      it "does not save the user" do
        expect(user.reload.updated_from_tra_at).to be_nil
      end

      it "leaves appropriate comment on webhook" do
        expect(webhook_message.reload.status_comment).to eq("Skipped - no data changes")
      end
    end

    context "when the user already has a verified TRN" do
      let(:old_trn_verified) { true }

      context "when the new TRN is the same as the user's current TRN" do
        let(:new_trn) { old_trn }

        context "when the new trn_lookup_status is Found" do
          let(:new_trn_status) { "Found" }

          it "updates the trn_lookup_status to Found" do
            subject
            expect(user.reload.trn_lookup_status).to eq("Found")
          end
        end

        context "when the new trn_lookup_status is not Found" do
          let(:new_trn_status) { "None" }

          it "does not change trn_verified" do
            subject
            expect(user.reload.trn_verified).to be true
          end

          it "does not change trn_lookup_status" do
            subject
            expect(user.reload.trn_lookup_status).to be_nil
          end
        end
      end

      context "when the provider data has a TRN that is different from the user's current TRN" do
        let(:new_trn) { "2345678" }
        let(:new_trn_status) { "None" }

        it "updates the TRN" do
          expect { subject }.to change { user.reload.trn }.from(old_trn).to(new_trn)
        end

        it "updates trn_verified" do
          expect { subject }.to change { user.reload.trn_verified }.from(true).to(false)
        end

        it "updates trn_lookup_status" do
          expect { subject }.to change { user.reload.trn_lookup_status }.from(nil).to("None")
        end
      end
    end

    context "when the message is nonsense" do
      let(:message) { SecureRandom.uuid }

      it "stores the data without the TRN" do
        expect {
          subject
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
        subject
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
