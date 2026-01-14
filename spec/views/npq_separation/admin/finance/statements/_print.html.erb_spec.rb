require "rails_helper"

RSpec.describe "npq_separation/admin/finance/statements/_print", type: :view do
  let(:rendered) { Capybara.string(subject) }
  let(:statement) { create(:statement) }
  let(:admin_user) { create(:admin) }

  before do
    assign(:statement, statement)
    assign(:contracts, [])
    assign(:special_contracts, [])
    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin_user) }
    allow(view).to receive(:nonced_stylesheet_link_tag).and_return("")
  end

  describe "cohort display" do
    context "when rendering for provider (internal_dfe_use: false)" do
      subject { render partial: "npq_separation/admin/finance/statements/print", locals: { internal_dfe_use: false } }

      it "displays the cohort start_year" do
        summary_card = rendered.find(".govuk-summary-card", text: "Overview")
        expect(summary_card).to have_summary_item("Cohort", statement.cohort.start_year)
      end
    end

    context "when rendering for DfE (internal_dfe_use: true)" do
      subject { render partial: "npq_separation/admin/finance/statements/print", locals: { internal_dfe_use: true } }

      it "displays the cohort name" do
        summary_card = rendered.find(".govuk-summary-card", text: "Overview")
        expect(summary_card).to have_summary_item("Cohort", statement.cohort.name)
      end
    end
  end
end
