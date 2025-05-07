require "rails_helper"

RSpec.describe NpqSeparation::Admin::AdjustmentsTableComponent, type: :component do
  subject { render_inline described_class.new(adjustments: adjustments, show_total: show_total) }

  let(:statement) { create(:statement) }
  let(:adjustment_1) { create(:adjustment, statement:, amount: 100) }
  let(:adjustment_2) { create(:adjustment, statement:, amount: 200) }
  let(:adjustment_3) { create(:adjustment, statement:, amount: 300) }
  let(:adjustments) { [adjustment_1, adjustment_2, adjustment_3] }
  let(:show_total) { nil }

  describe "table of adjustments" do
    it { is_expected.to have_css "thead th", text: t(".description") }
    it { is_expected.to have_css "thead th", text: t(".amount") }

    it { is_expected.to have_css "tbody td", text: adjustment_1.description }
    it { is_expected.to have_css "tbody td", text: "£#{adjustment_1.amount}" }
    it { is_expected.to have_css "tbody td", text: adjustment_2.description }
    it { is_expected.to have_css "tbody td", text: "£#{adjustment_2.amount}" }
    it { is_expected.to have_css "tbody td", text: adjustment_3.description }
    it { is_expected.to have_css "tbody td", text: "£#{adjustment_3.amount}" }
  end

  describe "adjustment total" do
    context "when show_total is false" do
      it { is_expected.not_to have_css "tbody th", text: t(".total") }
      it { is_expected.not_to have_css "tbody td", text: "£600" }
    end

    context "when show_total is true" do
      let(:show_total) { true }

      it { is_expected.to have_css "tbody th", text: t(".total") }
      it { is_expected.to have_css "tbody td", text: "£600" }
    end
  end
end
