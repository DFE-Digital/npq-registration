require "rails_helper"

RSpec.describe Users::FindOrCreateFromTeacherAuth do
  subject { described_class.new(provider_data:, feature_flag_id:).call }

  let(:uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
  let(:feature_flag_id) { SecureRandom.uuid }
  let(:email) { "user@example.com" }
  let(:trn) { "1234567" }
  let(:verified_name) { %w[Test User] }

  let(:provider_data) do
    OpenStruct.new({
      uid:,
      info: OpenStruct.new({
        email:,
      }),
      extra: OpenStruct.new({
        raw_info: OpenStruct.new({
          trn:,
          verified_name:,
          verified_date_of_birth: "1990-01-01",
        }),
      }),
    })
  end

  before { create(:user, trn:, trn_verified: true, archived_at: 1.day.ago) }

  context "when the TRN matches a verified TRN on one user" do
    let(:user) { create(:user, trn:, trn_verified: true) }

    before { user }

    it "sets the uid and provider on the user" do
      subject
      expect(user.reload).to have_attributes(uid:, provider: "teacher_auth")
    end

    it "returns the user" do
      expect(subject).to eq(user)
    end

    context "when user's details have updated" do
      it "updates the user" do
        subject
        expect(user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
      end
    end
  end

  context "when the TRN matches a verified TRN on more than one user" do
    let(:most_recently_updated_user) { create(:user, trn:, trn_verified: true) }
    let(:older_user) { create(:user, trn:, trn_verified: true, updated_at: 2.days.ago) }
    let(:application) { create(:application, user: older_user) }

    before do
      travel_to(1.day.ago) { most_recently_updated_user }
      travel_to(2.days.ago) { application }
    end

    it "sets the uid and provider on the most recently updated user" do
      subject
      expect(most_recently_updated_user.reload).to have_attributes(uid:, provider: "teacher_auth")
    end

    it "moves applications to the most recently updated user" do
      subject
      expect(application.reload.user).to eq(most_recently_updated_user)
    end

    it "archives the other users" do
      subject
      expect(older_user.reload).to be_archived
    end

    it "creates participant ID records" do
      subject
      expect(most_recently_updated_user.participant_id_changes.find_by(from_participant_id: older_user.ecf_id, to_participant_id: most_recently_updated_user.ecf_id)).to be_present
    end

    it "returns the most recently updated user" do
      expect(subject).to eq(most_recently_updated_user)
    end

    context "when user's details have updated" do
      it "updates the user" do
        subject
        expect(most_recently_updated_user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
      end
    end
  end

  shared_examples "logging in using provider and UID" do
    context "when a user exists with the same provider and UID" do
      let(:existing_user) { create(:user, :with_teacher_auth, email: "oldemail@example.com", uid:) }

      before { existing_user }

      context "when users details have updated" do
        it "updates the user" do
          subject
          expect(existing_user.reload).to have_attributes(email:, full_name: verified_name.join(" "))
        end
      end

      context "when the TRN is different" do
        let(:existing_user) { create(:user, :with_teacher_auth, email:, uid:, trn: "2345678") }

        it "updates the verified TRN on the user" do
          subject
          expect(existing_user.reload).to have_attributes(trn:, trn_verified: true, trn_auto_verified: true)
        end
      end

      context "when the email clashes with an existing user" do
        before { create(:user, :with_get_an_identity_id, email:) }

        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email Email address must be unique")
        end
      end
    end

    context "when no user exists with the same provider and UID" do
      it "creates a new user" do
        subject
        expect(User.find_by(provider: "teacher_auth", uid:)).to have_attributes(
          email:,
          trn:,
          trn_verified: true,
          trn_auto_verified: true,
          full_name: verified_name.join(" "),
          date_of_birth: Date.parse("1990-01-01"),
          feature_flag_id:,
        )
      end

      context "when the email clashes with an existing user" do
        before { create(:user, :with_get_an_identity_id, email:) }

        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email Email address must be unique")
        end
      end
    end
  end

  context "when the TRN doesn't match a user" do
    it_behaves_like "logging in using provider and UID"
  end

  context "when no TRN is specified" do
    let(:trn) { nil }

    it_behaves_like "logging in using provider and UID"
  end
end
