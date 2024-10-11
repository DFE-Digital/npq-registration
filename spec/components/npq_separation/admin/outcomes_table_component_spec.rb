require "rails_helper"

RSpec.describe NpqSeparation::Admin::OutcomesTableComponent, type: :component do
  before do
    render_inline(NpqSeparation::Admin::OutcomesTableComponent.new(outcomes))
  end

  context "when there are no outcomes" do
    let(:outcomes) { build(:application).participant_outcomes }

    it "renders a message" do
      expect(rendered_content).to have_text("No outcomes recorded.")
    end
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

  describe "'Sent to TRA API' column" do
    let(:cell_text) { page.find("tbody tr td:nth-child(4)").text }

    context "when the outcome has not been sent to TRA" do
      let(:outcomes) { [create(:participant_outcome)] }

      it "renders 'No'" do
        expect(cell_text).to eq("No")
      end
    end

    context "when the outcome has been sent to TRA" do
      let(:outcomes) { [create(:participant_outcome, :sent_to_qualified_teachers_api)] }

      it "renders the timestamp" do
        expected = outcomes.first.sent_to_qualified_teachers_api_at.to_fs(:govuk_short)

        expect(Time.zone.parse(cell_text)).to eq(expected)
      end
    end
  end

  describe "'Recorded by TRA API' column" do
    let(:cell_text) { page.find("tbody tr td:nth-child(5)").text }

    context "when the outcome has not been sent to TRA" do
      let(:outcomes) { [create(:participant_outcome)] }

      it "is empty" do
        expect(cell_text).to be_empty
      end
    end

    context "when the outcome was unsuccessfully sent to TRA" do
      let(:outcomes) { [create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api)] }

      it "renders no" do
        expect(cell_text).to eq("No")
      end
    end

    context "when the outcome was successfully sent to TRA" do
      let(:outcomes) { [create(:participant_outcome, :successfully_sent_to_qualified_teachers_api)] }

      it "renders yes" do
        expect(cell_text).to eq("Yes")
      end
    end
  end
end
