require "rails_helper"

RSpec.describe User do
  describe "relationships" do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
    it { is_expected.to have_many(:participant_id_changes).order("created_at desc") }
    it { is_expected.to have_many(:declarations).through(:applications) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }

    it { is_expected.to validate_presence_of(:email).on(:npq_separation).with_message("Enter an email address") }
    it { is_expected.to validate_uniqueness_of(:email).on(:npq_separation).case_insensitive.with_message("Email address must be unique") }
    it { is_expected.not_to allow_value("invalid-email").for(:email).on(:npq_separation) }

    it { is_expected.to validate_uniqueness_of(:uid).allow_blank }

    it "does not allow a uid to change once set" do
      user = create(:user, uid: "123")
      user.uid = "456"

      expect(user).to be_invalid(:npq_separation)
      expect(user.errors[:uid]).to be_present
    end
  end

  describe "methods" do
    it { expect(User.new).to be_actual_user }
    it { expect(User.new).not_to be_null_user }
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
end
