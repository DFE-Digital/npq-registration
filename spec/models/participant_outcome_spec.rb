require "rails_helper"

RSpec.describe ParticipantOutcome, type: :model do
  let(:application) { create(:application, :accepted) }
  let(:declaration_date) { application.schedule.applies_from + 1.day }
  let!(:declaration) do
    travel_to declaration_date do
      create(:declaration, :completed, application:, declaration_date:)
    end
  end

  subject(:instance) { build(:participant_outcome, declaration:) }

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:state).with_values(
        passed: "passed",
        failed: "failed",
        voided: "voided",
      ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe ".latest" do
    subject { described_class.latest }

    let!(:latest_outcome) { create(:participant_outcome) }

    before { travel_to(1.hour.ago) { create(:participant_outcome) } }

    it { is_expected.to eq(latest_outcome) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:completion_date) }

    describe "completion_date" do
      context "when the completion_date is in the future" do
        before { instance.completion_date = 1.day.from_now }

        it "is invalid" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :completion_date, type: :future_date)
        end
      end

      context "when the completion_date is now" do
        it "is valid" do
          freeze_time do
            instance.completion_date = Time.zone.today
            expect(instance).to be_valid
          end
        end
      end

      context "when the completion_date is in the past" do
        before { instance.completion_date = 1.day.ago }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:user).to(:declaration) }
    it { is_expected.to delegate_method(:lead_provider).to(:declaration) }
    it { is_expected.to delegate_method(:course).to(:declaration) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:declaration) }
    it { is_expected.to have_many(:participant_outcome_api_requests) }
  end

  describe "#has_passed?" do
    context "when the outcome is voided" do
      before { instance.state = :voided }

      it { expect(instance.has_passed?).to be_nil }
    end

    context "when the outcome is passed" do
      before { instance.state = :passed }

      it { is_expected.to be_has_passed }
    end

    described_class.states.keys.excluding("passed", "voided").each do |state|
      context "when the outcome is #{state}" do
        before { instance.state = state }

        it { is_expected.not_to be_has_passed }
      end
    end
  end

  describe "#has_failed?" do
    context "when the outcome is voided" do
      before { instance.state = :voided }

      it { expect(instance.has_failed?).to be_nil }
    end

    context "when the outcome is passed" do
      before { instance.state = :failed }

      it { is_expected.to be_has_failed }
    end

    described_class.states.keys.excluding("failed", "voided").each do |state|
      context "when the outcome is #{state}" do
        before { instance.state = state }

        it { is_expected.not_to be_has_failed }
      end
    end
  end

  describe "#latest_for_declaration?" do
    let!(:previous_outcome) { create(:participant_outcome, :voided, declaration:, created_at: 2.minutes.ago) }
    let!(:latest_outcome) { create(:participant_outcome, :passed, declaration:, created_at: 1.minute.ago) }

    it "returns false for superceded outcomes" do
      expect(previous_outcome).not_to be_latest_for_declaration
    end

    it "returns true for latest outcomes" do
      expect(latest_outcome).to be_latest_for_declaration
    end
  end

  describe ".to_send_to_qualified_teachers_api" do
    subject(:result) { described_class.to_send_to_qualified_teachers_api.map(&:id) }

    context "when the latest outcome for a declaration has been sent to the qualified teachers API" do
      before do
        create(:participant_outcome, :passed, :sent_to_qualified_teachers_api, declaration:)
        create(:participant_outcome, :failed, :sent_to_qualified_teachers_api, declaration:)
      end

      it { is_expected.to be_empty }
    end

    context "when the latest outcome for a declaration has not been sent to the qualified teachers API but a previous outcome has been sent" do
      before do
        create(:participant_outcome, :passed, :sent_to_qualified_teachers_api, declaration:)
        create(:participant_outcome, :failed, :not_sent_to_qualified_teachers_api, declaration:)
      end

      let!(:outcome) { create(:participant_outcome, :voided, :not_sent_to_qualified_teachers_api, declaration:) }

      it { is_expected.to contain_exactly(outcome.id) }
    end

    context "when the latest outcome is sent but previous outcomes were not sent" do
      before do
        create(:participant_outcome, :passed, :not_sent_to_qualified_teachers_api, declaration:)
        create(:participant_outcome, :voided, :not_sent_to_qualified_teachers_api, declaration:)
        create(:participant_outcome, :passed, :sent_to_qualified_teachers_api, declaration:)
      end

      it { is_expected.to be_empty }
    end

    context "when no outcomes for a declaration have been sent to the qualified teachers API" do
      context "when the latest outcome is passed" do
        before do
          create(:participant_outcome, :passed, :not_sent_to_qualified_teachers_api, declaration:)
          create(:participant_outcome, :voided, :not_sent_to_qualified_teachers_api, declaration:)
        end

        let!(:outcome) { create(:participant_outcome, :passed, :not_sent_to_qualified_teachers_api, declaration:) }

        it { is_expected.to contain_exactly(outcome.id) }
      end

      context "when the latest outcome is not passed" do
        before do
          create(:participant_outcome, :passed, :not_sent_to_qualified_teachers_api, declaration:)
          create(:participant_outcome, :failed, :not_sent_to_qualified_teachers_api, declaration:)
          create(:participant_outcome, :voided, :not_sent_to_qualified_teachers_api, declaration:)
        end

        it { is_expected.to be_empty }
      end
    end

    describe ".sent_to_qualified_teachers_api" do
      before { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      let!(:outcome) { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      subject(:result) { described_class.sent_to_qualified_teachers_api.map(&:id) }

      it { is_expected.to contain_exactly(outcome.id) }
    end

    describe ".not_sent_to_qualified_teachers_api" do
      before { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      let!(:outcome) { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      subject(:result) { described_class.not_sent_to_qualified_teachers_api.map(&:id) }

      it { is_expected.to contain_exactly(outcome.id) }
    end

    describe ".declarations_where_outcome_passed_and_sent" do
      let(:application_1) { create(:application, :accepted) }
      let(:declaration_date_1) { application.schedule.applies_from + 1.day }
      let(:application_2) { create(:application, :accepted) }
      let(:declaration_date_2) { application.schedule.applies_from + 1.day }
      let!(:declaration_1) do
        travel_to declaration_date_1 do
          create(:declaration, :completed, application:, declaration_date:)
        end
      end
      let!(:declaration_2) do
        travel_to declaration_date_2 do
          create(:declaration, :completed, application:, declaration_date:)
        end
      end

      before do
        create(:participant_outcome, :failed, :sent_to_qualified_teachers_api, declaration: declaration_1)
        create(:participant_outcome, :passed, :not_sent_to_qualified_teachers_api, declaration: declaration_2)
        create(:participant_outcome, :passed, :sent_to_qualified_teachers_api, declaration: declaration_2)
        create(:participant_outcome, :voided, :sent_to_qualified_teachers_api, declaration: declaration_2)
      end

      subject(:result) { described_class.declarations_where_outcome_passed_and_sent }

      it { is_expected.to contain_exactly(declaration_2.id) }
    end

    describe ".latest_per_declaration" do
      let(:application_1) { create(:application, :accepted) }
      let(:declaration_date_1) { application.schedule.applies_from + 1.day }
      let(:application_2) { create(:application, :accepted) }
      let(:declaration_date_2) { application.schedule.applies_from + 1.day }
      let!(:declaration_1) do
        travel_to declaration_date_1 do
          create(:declaration, :completed, application:, declaration_date:)
        end
      end
      let!(:declaration_2) do
        travel_to declaration_date_2 do
          create(:declaration, :completed, application:, declaration_date:)
        end
      end
      let!(:outcome_1) { create(:participant_outcome, declaration: declaration_1) }
      let!(:outcome_2) { create(:participant_outcome, declaration: declaration_2) }

      before { create(:participant_outcome, declaration: declaration_1, created_at: 1.day.ago) }

      subject(:result) { described_class.latest_per_declaration.map(&:id) }

      it { is_expected.to contain_exactly(outcome_1.id, outcome_2.id) }
    end
  end

  describe "#not_sent?" do
    subject { outcome.not_sent? }

    context "with successfully delivery" do
      let(:outcome) { create(:participant_outcome, :successfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with failed delivery" do
      let(:outcome) { create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with incomplete delivery" do
      let(:outcome) { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with undelivered" do
      let(:outcome) { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      it { is_expected.to be true }
    end
  end

  describe "#sent_and_recorded?" do
    subject { outcome.sent_and_recorded? }

    context "with successfully delivery" do
      let(:outcome) { create(:participant_outcome, :successfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be true }
    end

    context "with failed delivery" do
      let(:outcome) { create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with incomplete delivery" do
      let(:outcome) { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with undelivered" do
      let(:outcome) { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end
  end

  describe "#sent_and_not_recorded?" do
    subject { outcome.sent_but_not_recorded? }

    context "with successfully delivery" do
      let(:outcome) { create(:participant_outcome, :successfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with failed delivery" do
      let(:outcome) { create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be true }
    end

    context "with incomplete delivery" do
      let(:outcome) { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with undelivered" do
      let(:outcome) { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end
  end

  describe "#allow_resending_to_qualified_teachers_api?" do
    subject { outcome.allow_resending_to_qualified_teachers_api? }

    context "with successfully delivery" do
      let(:outcome) { create(:participant_outcome, :successfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with failed delivery" do
      let(:outcome) { create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be true }
    end

    context "with incomplete delivery" do
      let(:outcome) { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "with undelivered" do
      let(:outcome) { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end

    context "when not latest outcome" do
      before do
        create(:participant_outcome, :failed, declaration: outcome.declaration,
                                              created_at: 3.minutes.from_now)
      end

      let(:outcome) { create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
    end
  end

  describe "#resend_to_qualified_teachers_api!" do
    subject(:resend) { outcome.resend_to_qualified_teachers_api! }

    context "with successfully delivery" do
      let(:outcome) { create(:participant_outcome, :successfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
      it { expect { resend }.not_to change(outcome.reload, :sent_to_qualified_teachers_api_at) }
      it { expect { resend }.not_to change(outcome.reload, :qualified_teachers_api_request_successful) }
    end

    context "with failed delivery" do
      let(:outcome) { create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api) }

      it { is_expected.to be true }
      it { expect { resend }.to change(outcome.reload, :sent_to_qualified_teachers_api_at).to(nil) }
      it { expect { resend }.to change(outcome.reload, :qualified_teachers_api_request_successful).to(nil) }
    end

    context "with incomplete delivery" do
      let(:outcome) { create(:participant_outcome, :sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
      it { expect { resend }.not_to change(outcome.reload, :sent_to_qualified_teachers_api_at) }
      it { expect { resend }.not_to change(outcome.reload, :qualified_teachers_api_request_successful) }
    end

    context "with undelivered" do
      let(:outcome) { create(:participant_outcome, :not_sent_to_qualified_teachers_api) }

      it { is_expected.to be false }
      it { expect { resend }.not_to change(outcome.reload, :sent_to_qualified_teachers_api_at) }
      it { expect { resend }.not_to change(outcome.reload, :qualified_teachers_api_request_successful) }
    end
  end

  describe "#trn" do
    subject { instance.trn }

    it { is_expected.to eq instance.user.trn }
  end

  describe "#course_short_code" do
    subject { instance.course_short_code }

    it { is_expected.to eq instance.course.short_code }
  end
end
