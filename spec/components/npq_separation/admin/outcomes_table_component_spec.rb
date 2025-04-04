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
    context "when passed but not sent" do
      let :outcomes do
        create_list(:participant_outcome, 1, :passed)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Passed" }
    end

    context "when failed but not sent" do
      let :outcomes do
        create_list(:participant_outcome, 1, :failed)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Failed" }
    end

    context "when passed and sent and recorded" do
      let :outcomes do
        create_list(:participant_outcome, 1, :passed, :successfully_sent_to_qualified_teachers_api)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Passed and recorded" }
    end

    context "when failed and sent and recorded" do
      let :outcomes do
        create_list(:participant_outcome, 1, :failed, :successfully_sent_to_qualified_teachers_api)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Failed and recorded" }
    end

    context "when passed and sent but not recorded" do
      let :outcomes do
        create_list(:participant_outcome, 1, :passed, :unsuccessfully_sent_to_qualified_teachers_api)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Passed but not recorded" }
    end

    context "when failed and sent but not recored" do
      let :outcomes do
        create_list(:participant_outcome, 1, :failed, :unsuccessfully_sent_to_qualified_teachers_api)
      end

      it { is_expected.to have_css "caption", text: "Declaration Outcomes: Failed but not recorded" }
    end
  end

  describe "'Sent to TRA API' column" do
    let(:cell_text) { page.find("tbody tr td:nth-child(4)").text }

    context "when the outcome has not been sent to TRA" do
      let(:outcomes) { [create(:participant_outcome)] }

      it "renders 'N/A'" do
        expect(cell_text).to eq("N/A")
      end
    end

    context "when the outcome has been sent to TRA" do
      let(:outcomes) { [create(:participant_outcome, :sent_to_qualified_teachers_api)] }

      it "renders the timestamp" do
        expected = outcomes.first.sent_to_qualified_teachers_api_at.to_date.to_fs(:govuk_short)

        expect(Time.zone.parse(cell_text)).to eq(expected)
      end
    end
  end

  describe "'Recorded by API' column" do
    let(:cell_text) { page.find("tbody tr td:nth-child(5)").text }

    context "when the outcome has not been sent to TRA" do
      let(:cell_texts) { page.all("tbody tr td:nth-child(5)").map(&:text) }
      let(:declaration) { create :declaration }
      let(:outcomes) do
        2.times.map { create(:participant_outcome, declaration:) }
      end

      it "renders 'Pending' for the latest outcome" do
        expect(cell_texts[0]).to eq("Pending")
      end

      it "renders 'N/A' for superceded outcomes" do
        expect(cell_texts[1]).to eq("N/A")
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

  describe "Resend column" do
    let(:resend_cell) { page.find("tbody tr td:nth-child(6)") }

    context "when the outcome can be resent" do
      let :outcomes do
        create_list(:participant_outcome, 1, :unsuccessfully_sent_to_qualified_teachers_api)
      end

      let :resend_path do
        Rails.application
             .routes
             .url_helpers
             .resend_npq_separation_admin_participant_outcome_path(outcomes.first)
      end

      it "renders a resend button" do
        within(%(tbody tr td:nth-child(6) form[action="#{resend_path}")) do |form|
          expect(form).to have_button("Resend")
        end
      end
    end

    context "when the outcome cannot be resent" do
      let :outcomes do
        create_list(:participant_outcome, 1, :unsuccessfully_sent_to_qualified_teachers_api)
      end

      it "renders a blank cell" do
        expect(resend_cell).to have_text("")
      end
    end
  end
end
