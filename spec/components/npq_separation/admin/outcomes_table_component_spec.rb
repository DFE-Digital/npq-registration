require "rails_helper"

RSpec.describe NpqSeparation::Admin::OutcomesTableComponent, type: :component do
  subject { page }

  before do
    render_inline(described_class.new(outcomes))
  end

  context "when there are multiple outcomes" do
    let(:outcomes) do
      [
        create(:participant_outcome, :failed, created_at: 2.days.ago),
        create(:participant_outcome, :voided, created_at: 3.days.ago),
        create(:participant_outcome, :passed, created_at: 1.day.ago),
      ]
    end

    it "renders newest to oldest" do
      states = page.all("tbody tr td:first-child").map(&:text)
      expect(states).to eq(%w[Passed Failed Voided])
    end
  end

  describe "Table caption text" do
    context "when passed" do
      let :outcomes do
        create_list(:participant_outcome, 1, :passed)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Passed" }
    end

    context "when failed" do
      let :outcomes do
        create_list(:participant_outcome, 1, :failed)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Failed" }
    end

    context "when voided" do
      let :outcomes do
        create_list(:participant_outcome, 1, :voided)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Voided" }
    end
  end
end
