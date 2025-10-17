require "rails_helper"

RSpec.describe NpqSeparation::Admin::OutcomesTableComponent, type: :component do
  subject { page }

  before do
    render_inline(described_class.new(outcomes))
  end

  context "when there are multiple outcomes" do
    let(:outcomes) do
      [
        create(:participant_outcome, :failed, completion_date: 2.days.ago),
        create(:participant_outcome, :voided, completion_date: 3.days.ago),
        create(:participant_outcome, :passed, completion_date: 1.day.ago),
      ]
    end

    it "renders newest to oldest" do
      states = page.all("tbody tr td:first-child").map(&:text)
      expect(states).to eq(%w[Passed Failed Voided])
    end
  end
end
