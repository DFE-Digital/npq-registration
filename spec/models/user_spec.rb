require "rails_helper"

RSpec.describe User do
  subject { create(:user) }

  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
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
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
    it { is_expected.to validate_presence_of(:email).with_message("Enter an email address") }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive.with_message("Email address must be unique") }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }
    it { is_expected.to validate_uniqueness_of(:uid).allow_blank }
    it { is_expected.to validate_uniqueness_of(:ecf_id).allow_blank.case_insensitive.with_message("ECF ID must be unique") }

    context "when ecf_api_disabled flag is toggled on" do
      before { Flipper.enable(Feature::ECF_API_DISABLED) }

      # TODO: uncomment this when `before_validation` is removed from model, as `before_validation` is adding ecf_id regardless
      # it { is_expected.to validate_presence_of(:ecf_id).with_message("Enter an ECF ID") }

      it "ensures ecf_id is automatically populated" do
        user = build(:user, ecf_id: nil)
        user.valid?
        expect(user.ecf_id).not_to be_nil
      end

      it "ensures ecf_id does not change on validation" do
        ecf_id = SecureRandom.uuid
        application = build(:application, ecf_id:)
        application.valid?
        expect(application.ecf_id).to eq(ecf_id)
      end
    end

    context "when ecf_api_disabled flag is toggled off" do
      before { Flipper.disable(Feature::ECF_API_DISABLED) }

      it { is_expected.not_to validate_presence_of(:ecf_id) }

      it "ensures ecf_id is not automatically populated" do
        application = build(:application, ecf_id: nil)
        application.valid?
        expect(application.ecf_id).to be_nil
      end
    end
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

  describe "methods" do
    it { expect(User.new).to be_actual_user }
    it { expect(User.new).not_to be_null_user }
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

  describe ".latest_participant_outcome" do
    let(:user) { create(:user) }
    let(:lead_provider) { participant_outcome.lead_provider }
    let(:course_identifier) { participant_outcome.course.identifier }
    let(:participant_outcome) { create(:participant_outcome, user:) }
    let(:course) { participant_outcome.course }

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
    end

    it { is_expected.to eq(participant_outcome) }

    context "when there are no participant outcomes" do
      before { ParticipantOutcome.destroy_all }

      it { is_expected.to be_nil }
    end
  end

  describe "#update_email_updates_status" do
    let(:user) { create(:user) }
    let(:form) { EmailUpdates.new(email_updates_status: :senco) }
    let(:uuid) { "123" }

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

  describe "#ecf_user" do
    subject(:user) { build(:user) }

    before { allow(External::EcfAPI::Npq::User).to receive(:find).and_return(%w[anything]) }

    it "calls the correct ECF API service" do
      expect(External::EcfAPI::Npq::User).to receive(:find).with(user.ecf_id)

      user.ecf_user
    end

    context "when ecf_id is nil" do
      before { user.update!(ecf_id: nil) }

      it "returns nil" do
        expect(user.ecf_user).to be_nil
      end
    end

    context "when ecf_api_disabled flag is toggled on" do
      before { Flipper.enable(Feature::ECF_API_DISABLED) }

      it "returns nil" do
        expect(user.ecf_user).to be_nil
      end
    end
  end

  context "when updating the user with the TRA data" do
    let(:provider_data) do
      OpenStruct.new(
        provider: "example_provider",
        uid: "example_uid",
        info: OpenStruct.new(
          email: "user@example.com",
          email_verified: true,
          name: "Example User",
          trn:,
        ),
      )
    end

    let(:feature_flag_id) { 1 }
    let(:trn) { "1234567" }

    shared_examples "a TRN updater" do |method_name|
      context "when TRA provides a TRN" do
        it "update the user" do
          described_class.public_send(method_name, provider_data, feature_flag_id:)

          expect(user.trn).to eq "1234567"
          expect(user.email).to eq "user@example.com"
          expect(user.full_name).to eq "Example User"
        end
      end

      context "when TRA provides a nil TRN" do
        let(:trn) { nil }

        it "update the user, but keep the TRN unchanged" do
          original_trn = user.trn

          described_class.public_send(method_name, provider_data, feature_flag_id:)

          expect(user.trn).to eq original_trn
          expect(user.email).to eq "user@example.com"
          expect(user.full_name).to eq "Example User"
        end
      end
    end

    describe ".find_or_create_from_tra_data_on_uid" do
      let(:user) { create(:user, provider: "example_provider", trn: "1020304") }

      before do
        allow(User).to receive(:find_or_initialize_by).and_return(user)
      end

      it_behaves_like "a TRN updater", :find_or_create_from_tra_data_on_uid
    end

    describe ".find_or_create_from_tra_data_on_unclaimed_email" do
      let(:user) { create(:user, provider: nil, uid: nil, email: "user@example.com", trn: "1020304") }

      before do
        allow(User).to receive(:find_or_initialize_by).and_return(user)
      end

      it_behaves_like "a TRN updater", :find_or_create_from_tra_data_on_unclaimed_email

      context "when TRA provides a TRN and user has unclaimed email" do
        it "updates provider and UID along with TRN" do
          described_class.find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)

          expect(user.trn).to eq "1234567"
          expect(user.email).to eq "user@example.com"
          expect(user.full_name).to eq "Example User"
          expect(user.provider).to eq "example_provider"
          expect(user.uid).to eq "example_uid"
        end
      end

      context "when user cannot be saved" do
        before do
          allow(user).to receive(:save).and_return(false)
          allow(Rails.logger).to receive(:info)
        end

        it "logs the error" do
          described_class.find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)

          expect(Rails.logger).to have_received(:info).with(/\[GAI\] User not persisted, .+ trying to reclaim email failed/)
        end
      end
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

  describe ".find_or_create_from_provider_data" do
    subject { described_class.find_or_create_from_provider_data(provider_data, feature_flag_id:) }

    let(:provider) { "example_provider" }
    let(:uid) { "example_uid" }
    let(:provider_data) do
      OpenStruct.new(
        provider:,
        uid:,
        info: OpenStruct.new(
          email: "clashing@example.com",
          email_verified: true,
          name: "Example User",
        ),
      )
    end
    let(:feature_flag_id) { 1 }

    context "when the email has changed in the provider but clashes with an existing user" do
      let!(:user) { create(:user, email: "old@example.com", provider:, uid:) }
      let!(:clashing_user) { create(:user, :with_get_an_identity_id, email: "clashing@example.com") }

      it "archives the clashing user" do
        subject
        expect(clashing_user.reload).to be_archived
      end

      it "returns the user" do
        expect(subject).to eq user
      end

      it "the returned user has unsaved changes" do
        expect(subject.changed?).to be true
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
end
