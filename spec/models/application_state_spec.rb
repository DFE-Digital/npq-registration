require "rails_helper"

RSpec.describe ApplicationState do
  let(:application) { create(:application) }

  subject(:application_state) { create(:application_state, application:) }

  describe "relationships" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:lead_provider).optional }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:state).with_values(
        active: "active",
        deferred: "deferred",
        withdrawn: "withdrawn",
      ).backed_by_column_of_type(:enum)
    }
  end

  describe "scopes" do
    describe ".most_recent" do
      let!(:another_application_state) { create(:application_state, application:) }

      before do
        application_state.update!(created_at: 2.weeks.ago)
      end

      it "fetches the most recent record only" do
        expect(described_class.most_recent).to eq([another_application_state])
      end
    end

    describe ".for_lead_provider" do
      let(:lead_provider) { create(:lead_provider, name: "ABC1234") }

      before do
        create(:application_state, application:)
        application_state.update!(lead_provider:)
      end

      it "fetches records from the given lead provider only" do
        expect(described_class.for_lead_provider(lead_provider)).to eq([application_state])
      end
    end
  end
end
