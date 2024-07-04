require "rails_helper"

RSpec.describe ParticipantOutcome, type: :model do
  subject(:instance) { build(:participant_outcome) }

  describe ".latest" do
    subject { described_class.latest }

    let!(:latest_outcome) { create(:participant_outcome) }

    before { travel_to(1.day.ago) { create(:participant_outcome) } }

    it { is_expected.to eq(latest_outcome) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
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
end
