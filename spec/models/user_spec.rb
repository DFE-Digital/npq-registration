require "rails_helper"

RSpec.describe User do
  subject { create(:user) }

  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:participant_id_changes).order("created_at desc") }
    it { is_expected.to have_many(:declarations).through(:applications) }
  end

  describe "paper_trail" do
    subject { create(:user, full_name: "Joe") }

    it "enables paper trail" do
      expect(subject).to be_versioned
    end

    it "creates a version with a note" do
      with_versioning do
        expect(PaperTrail).to be_enabled

        subject.update!(
          full_name: "Changed Name",
          version_note: "This is a test",
        )
        version = subject.versions.last
        expect(version.note).to eq("This is a test")
        expect(version.object_changes["full_name"]).to eq(["Joe", "Changed Name"])
      end
    end

    context "when user logs in" do
      it "does not create a new version when insignificant attributes remains unchanged" do
        with_versioning do
          expect(PaperTrail).to be_enabled

          expect {
            subject.update!(
              updated_at: 1.second.from_now,
              feature_flag_id: SecureRandom.uuid,
            )
          }.not_to(change { subject.reload.versions.count })
        end
      end

      it "creates a new version when one of significant attributes changes" do
        with_versioning do
          expect(PaperTrail).to be_enabled

          expect {
            subject.update!(
              updated_at: 1.second.from_now,
              updated_from_tra_at: 1.second.from_now,
              trn: "1212121",
              feature_flag_id: SecureRandom.uuid,
            )
          }.to(change { subject.reload.versions.count })
        end
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
    it { is_expected.to validate_presence_of(:email).with_message("Enter an email address") }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive.with_message("Email address must be unique") }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }
    it { is_expected.to validate_uniqueness_of(:uid).allow_blank }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:email_updates_status).with_values(
        empty: 0,
        senco: 1,
        other_npq: 2,
      ).backed_by_column_of_type(:integer).with_suffix
    }
  end

  describe "touch_significantly_updated_at" do
    let(:user) { travel_to(1.day.ago) { create(:user, :without_significantly_updated_at) } }
    let(:significant_change) { { full_name: "New Name" } }
    let(:insignificant_change) { { raw_tra_provider_data: { foo: :bar } } }

    it "sets significantly_updated_at on creation" do
      expect(user.significantly_updated_at).to be_present
    end

    it "sets significantly_updated_at when a significant change is made" do
      expect { user.update!(significant_change) }.to(change { user.reload.significantly_updated_at })
      expect(user.significantly_updated_at).to eq(user.updated_at)
    end

    it "sets significantly_updated_at when a significant change is made alongside an insignificant change" do
      expect { user.update!(significant_change.merge(insignificant_change)) }.to(change { user.reload.significantly_updated_at })
      expect(user.significantly_updated_at).to eq(user.updated_at)
    end

    it "does not update significantly_updated_at when an insignificant change is made" do
      expect { user.update!(insignificant_change) }.not_to(change { user.reload.significantly_updated_at })
    end

    it "updates significantly_updated_at when touched" do
      expect { user.touch(time: 1.day.from_now) }.to(change { user.reload.significantly_updated_at })
      expect(user.significantly_updated_at).to eq(user.updated_at)
    end

    it "does not override significantly_updated_at when setting it explicitly" do
      significantly_updated_at = 1.month.from_now
      user.update!(significant_change.merge(significantly_updated_at:))
      expect(user.significantly_updated_at).to be_within(1.second).of(significantly_updated_at)
    end

    context "when skip_touch_user_if_changed is true" do
      before { user.skip_touch_significantly_updated_at = true }

      it "does not update significantly_updated_at" do
        expect { user.touch(time: 1.day.from_now) }.not_to(change { user.reload.significantly_updated_at })
      end
    end
  end

  describe "#latest_participant_outcome" do
    let(:user) { create(:user) }
    let(:lead_provider) { create(:lead_provider) }
    let(:course_identifier) { ParticipantOutcomes::Create::PERMITTED_COURSES.first }
    let(:participant_outcome) { create(:participant_outcome, user:, course:, lead_provider:) }
    let(:course) { Course.find_by!(identifier: course_identifier) }

    subject { user.latest_participant_outcome(lead_provider, course_identifier) }

    before do
      # Older participant outcome.
      travel_to(1.day.ago) { create(:participant_outcome, user:, course:, lead_provider:) }

      travel_to(1.day.from_now) do
        # Not a completed declaration.
        create(:participant_outcome, user:, course:, lead_provider:).declaration.update!(declaration_type: "retained-1")

        # Declaration on another provider.
        create(:participant_outcome, user:, course:, lead_provider: LeadProvider.where.not(id: lead_provider.id).first)

        # Declaration with different course.
        create(:participant_outcome, user:, course: create(:course, identifier: "other-course"), lead_provider:)

        # Declarations that are not billable or voidable.
        Declaration.states.keys.excluding(Declaration::BILLABLE_STATES + Declaration::VOIDABLE_STATES).each do |state|
          create(:participant_outcome, user:, course:, lead_provider:).declaration.update!(state:)
        end
      end

      participant_outcome
    end

    it { is_expected.to eq(participant_outcome) }

    context "when there are no participant outcomes" do
      before { ParticipantOutcome.destroy_all }

      it { is_expected.to be_nil }
    end
  end

  describe ".find_or_create_from_provider_data" do
    let(:provider_data) { { foo: :bar } }
    let(:feature_flag_id) { "123" }
    let(:service) { instance_double(Users::FindOrCreateFromProviderData) }

    before { allow(Users::FindOrCreateFromProviderData).to receive(:new).with(provider_data: provider_data, feature_flag_id: feature_flag_id) { service } }

    it "calls Users::FindOrCreateFromProviderData service" do
      expect(service).to receive(:call)
      described_class.find_or_create_from_provider_data(provider_data, feature_flag_id: feature_flag_id)
    end
  end

  describe "#update_email_updates_status" do
    let(:user) { create(:user) }
    let(:form) { EmailUpdates.new(email_updates_status: :senco) }
    let(:uuid) { "7d023b82-e0eb-4ae2-b613-0a4a51bacf8f" }

    before do
      allow(SecureRandom).to receive(:uuid) { uuid }
    end

    context "when value is correct" do
      it "saves the value" do
        expect {
          user.update_email_updates_status(form)
        }.to change { user.reload.email_updates_status }.from("empty").to("senco")
      end

      it "creates proper unsubscribe key" do
        expect {
          user.update_email_updates_status(form)
        }.to change { user.reload.email_updates_unsubscribe_key }.from(nil).to(uuid)
      end
    end

    context "when value is changed" do
      let(:user) { create(:user, email_updates_unsubscribe_key: "432") }

      it "does not changes unsubscribe key" do
        expect {
          user.update_email_updates_status(form)
        }.not_to(change { user.reload.email_updates_unsubscribe_key })
      end
    end
  end

  describe "#unsubscribe_from_email_updates" do
    let(:user) { create(:user, email_updates_unsubscribe_key: "432", email_updates_status: "senco") }

    it "saves the value" do
      expect {
        user.unsubscribe_from_email_updates
      }.to change { user.reload.email_updates_status }.from("senco").to("empty")
    end

    it "creates proper unsubscribe key" do
      expect {
        user.unsubscribe_from_email_updates
      }.to change { user.reload.email_updates_unsubscribe_key }.from("432").to(nil)
    end
  end

  describe "#archived?" do
    context "when user is archived" do
      subject(:user) { build(:user, :archived) }

      it "returns true" do
        expect(user.archived?).to be(true)
      end
    end

    context "when user is not archived" do
      subject(:user) { build(:user) }

      it "returns false" do
        expect(user.archived?).to be(false)
      end
    end
  end

  describe "#set_closed_registration_feature_flag" do
    before do
      Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)
      Flipper.disable(Feature::REGISTRATION_OPEN)
    end

    let(:user) { create(:user) }

    context "when user is on the ClosedRegistrationUser list" do
      before do
        ClosedRegistrationUser.create!(email: user.email)
      end

      it "can be added" do
        expect { user.set_closed_registration_feature_flag }.to change { Feature.registration_closed?(user) }.from(true).to(false)
      end
    end

    context "when user is not on the ClosedRegistrationUser list" do
      it "can not be added" do
        expect { user.set_closed_registration_feature_flag }.not_to change { Feature.registration_closed?(user) }.from(true)
      end
    end
  end

  describe ".find_by_get_an_identity_id" do
    let(:uid) { SecureRandom.uuid }
    let!(:user) { create(:user, :with_get_an_identity_id, uid:) }

    it "returns the user with matching uid from the with_get_an_identity_id scope" do
      expect(User.find_by_get_an_identity_id(uid)).to eq(user)
    end

    it "returns nil if no user matches the uid" do
      expect(User.find_by_get_an_identity_id("nonexistent-uid")).to be_nil
    end
  end

  describe "#get_an_identity_user" do
    let(:user) { create(:user, :with_get_an_identity_id, uid:) }
    let(:uid) { SecureRandom.uuid }
    let(:external_user) { instance_double(External::GetAnIdentity::User) }

    context "when get_an_identity_id is present" do
      it "returns the external user from GetAnIdentity" do
        allow(External::GetAnIdentity::User).to receive(:find).with(uid).and_return(external_user)
        expect(user.get_an_identity_user).to eq(external_user)
      end
    end

    context "when get_an_identity_id is blank" do
      let(:uid) { nil }

      it "returns nil without calling the external service" do
        expect(External::GetAnIdentity::User).not_to receive(:find)
        expect(user.get_an_identity_user).to be_nil
      end
    end
  end

  describe "#get_an_identity_provider?" do
    context "when the user is using GAI" do
      let(:user) { create(:user, :with_get_an_identity_id) }

      it "returns true" do
        expect(user).to be_get_an_identity_provider
      end
    end

    context "when the user provider is empty" do
      let(:user) { create(:user) }

      it "returns false" do
        expect(user).not_to be_get_an_identity_provider
      end
    end
  end

  describe "#get_an_identity_id" do
    context "when the user is using GAI" do
      let(:uid) { SecureRandom.uuid }
      let(:user) { create(:user, :with_get_an_identity_id, uid:) }

      it "returns true" do
        expect(user.get_an_identity_id).to eq(uid)
      end
    end

    context "when the user provider is empty" do
      let(:user) { create(:user) }

      it "returns false" do
        expect(user.get_an_identity_id).to be_nil
      end
    end
  end

  describe "#flipper_id" do
    let(:feature_flag_id) { SecureRandom.uuid }
    let(:user) { build(:user) }

    before do
      allow(user).to receive(:retrieve_or_persist_feature_flag_id).and_return(feature_flag_id)
    end

    it "returns the feature_flag_id prefixed with 'User;'" do
      expect(user.flipper_id).to eq("User;#{feature_flag_id}")
    end
  end

  describe "#set_updated_from_tra_at" do
    let(:user) { create(:user, updated_from_tra_at: nil).reload }

    context "when significant attribute does change" do
      before do
        user.trn = "1231234"
        user.set_updated_from_tra_at
      end

      it "changes updated_from_tra_at" do
        expect(user.updated_from_tra_at).to be_present
      end
    end

    context "when significant attribute does not change" do
      before do
        user.set_updated_from_tra_at
      end

      it "changes updated_from_tra_at" do
        expect(user.updated_from_tra_at).not_to be_present
      end
    end
  end

  describe "#retrieve_or_persist_feature_flag_id" do
    let(:feature_flag_id) { SecureRandom.uuid }

    context "when feature_flag_id is nil" do
      let(:user) { create(:user) }

      before do
        allow(SecureRandom).to receive(:uuid).and_return(feature_flag_id)
      end

      it "generates a new feature_flag_id and saves it" do
        expect(user.feature_flag_id).to be_nil

        expect(user.retrieve_or_persist_feature_flag_id).to eq(feature_flag_id)
      end
    end

    context "when feature_flag_id is already present" do
      let(:feature_flag_id) { SecureRandom.uuid }
      let(:user) { create(:user, feature_flag_id:) }

      it "returns the correct flag id" do
        expect(user.retrieve_or_persist_feature_flag_id).to eq(feature_flag_id)
      end
    end
  end

  context "when email has upcase characters" do
    let(:user) { build(:user, email: "Foo@example.com") }

    before do
      user.save
    end

    it "downcases email during saving" do
      expect(user.reload.email).to eq("foo@example.com")
    end
  end
end
