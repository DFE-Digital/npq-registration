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

  describe "#trn" do
    subject { instance.trn }

    it { is_expected.to eq instance.user.trn }
  end

  describe "#course_short_code" do
    subject { instance.course_short_code }

    it { is_expected.to eq instance.course.short_code }
  end
end
