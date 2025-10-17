# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementSelectorComponent, type: :component do
  include StatementHelper

  let(:lead_provider) { create :lead_provider }
  let!(:statement) { create(:statement, lead_provider:) }
  let!(:statement_other_cohort) { create(:statement, lead_provider:, cohort: other_cohort) }
  let!(:statement_other_lead_provider) { create(:statement, lead_provider: create(:lead_provider)) }
  let(:other_cohort) { create(:cohort, :previous) }
  let(:cohort) { statement.cohort }
  let(:instance) { described_class.new(statement_params) }
  let(:lead_provider_param) { nil }
  let(:cohort_param) { nil }
  let(:statement_param) { nil }
  let(:payment_status_param) { nil }
  let(:output_fee_param) { nil }
  let(:rendered) { render_inline instance }
  let(:payment_status_selector) { "select#payment-status-field" }

  let(:statement_params) do
    { lead_provider_id: lead_provider_param,
      cohort_id: cohort_param,
      payment_status: payment_status_param,
      statement: statement_param,
      output_fee: output_fee_param }
  end

  it "has a form that GETs to correct action" do
    expect(rendered).to have_selector("form[method=get][action='/npq-separation/admin/finance/statements']")
  end

  it "has dropdown with status" do
    expect(rendered).to have_selector(payment_status_selector)
    expect(rendered).to have_selector("#{payment_status_selector} option[value='']", text: "All")
    expect(rendered).to have_selector("#{payment_status_selector} option[value='paid']", text: "Paid")
    expect(rendered).to have_selector("#{payment_status_selector} option[value='unpaid']", text: "Unpaid")
  end

  it "has dropdown with lead providers" do
    expect(rendered).to have_selector("select#lead-provider-id-field")
    expect(rendered).to have_selector("select#lead-provider-id-field option[value='#{lead_provider.id}']", text: lead_provider.name)
  end

  it "has dropdown with cohorts" do
    expect(rendered).to have_selector("select#cohort-id-field")
    expect(rendered).to have_selector("select#cohort-id-field option[value='#{cohort.id}']", text: cohort.name)
  end

  it "has dropdown with statement dates" do
    expect(rendered).to have_selector("select#statement-field")
    expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement)}']", text: statement_name(statement))
    expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement_other_cohort)}']", text: statement_name(statement_other_cohort))
    expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement_other_lead_provider)}']", text: statement_name(statement_other_lead_provider))
  end

  context "when a lead provider has been selected" do
    let(:lead_provider_param) { lead_provider.id }

    it "only shows statements for that lead provider" do
      expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement)}']", text: statement_name(statement))
      expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement_other_cohort)}']", text: statement_name(statement_other_cohort))
      expect(rendered).not_to have_selector("select#statement-field option[value='#{statement_period(statement_other_lead_provider)}']", text: statement_name(statement_other_lead_provider))
    end

    context "and a cohort has been selected" do
      let(:cohort_param) { other_cohort.id }

      it "only shows statements for that lead provider and cohort" do
        expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement_other_cohort)}']", text: statement_name(statement_other_cohort))
        expect(rendered).not_to have_selector("select#statement-field option[value='#{statement_period(statement)}']", text: statement_name(statement))
      end
    end
  end

  context "when a cohort has been selected" do
    let(:cohort_param) { cohort.id }

    it "only shows statements for that cohort" do
      expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement)}']", text: statement_name(statement))
      expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement_other_lead_provider)}']", text: statement_name(statement_other_lead_provider))
      expect(rendered).not_to have_selector("select#statement-field option[value='#{statement_period(statement_other_cohort)}']", text: statement_name(statement_other_cohort))
    end
  end

  it "has a dropdown with payment run" do
    expect(rendered).to have_selector("select#output-fee-field")
    expect(rendered).to have_selector("select#output-fee-field option[value='']", text: "All")
    expect(rendered).to have_selector("select#output-fee-field option[value='true']", text: "Yes")
    expect(rendered).to have_selector("select#output-fee-field option[value='false']", text: "No")
  end

  it "has submit button" do
    expect(rendered).to have_selector("button[type=submit]", text: "Search")
  end

  context "when the statement param is present" do
    let(:statement_param) { statement_period(statement) }

    it "defaults to selected statement" do
      expect(rendered).to have_selector("select#statement-field option[selected]", text: statement_name(statement), visible: :all)
    end
  end

  context "when the lead provider param is present" do
    let(:lead_provider_param) { lead_provider.id }

    it "defaults to selected lead provider" do
      expect(rendered).to have_selector("select#lead-provider-id-field option[selected]", text: statement.lead_provider.name, visible: :all)
    end
  end

  context "when the cohort param is present" do
    let(:cohort_param) { cohort.id }

    it "defaults to selected cohort" do
      expect(rendered).to have_selector("select#cohort-id-field option[selected]", text: statement.cohort.name, visible: :all)
    end
  end

  context "when the payment status param is present" do
    let(:payment_status_param) { "paid" }

    it "defaults to selected payment status" do
      expect(rendered).to have_selector("#{payment_status_selector} option[selected]", text: "Paid", visible: :all)
    end
  end

  context "when the output fee param is present" do
    let(:output_fee_param) { "true" }

    it "defaults to selected output fee" do
      expect(rendered).to have_selector("select#output-fee-field option[selected]", text: "Yes", visible: :all)
    end
  end

  context "when the output fee param is not present (initial page load)" do
    let(:statement_params) do
      { lead_provider_id: lead_provider_param,
        cohort_id: cohort_param,
        payment_status: payment_status_param,
        statement: statement_param }
    end

    it "defaults to 'Yes' selected" do
      expect(rendered).to have_selector("select#output-fee-field option[selected]", text: "Yes", visible: :all)
    end
  end

  context "when the output fee param is blank (user selected 'All')" do
    let(:output_fee_param) { "" }

    it "does not pre-select Yes or No" do
      expect(rendered).not_to have_selector("select#output-fee-field option[selected]", visible: :all)
    end
  end

  context "when sidebar mode is enabled" do
    let(:instance) { described_class.new(statement, format_for_sidebar: true) }

    it "does not have payment status dropdown" do
      expect(rendered).not_to have_selector(payment_status_selector)
    end

    it "uses a single-column layout" do
      expect(rendered).to have_selector(".govuk-grid-column-full", count: 3)
      expect(rendered).not_to have_selector(".govuk-grid-column-one-half")
    end

    it "has a different label for the submit button" do
      expect(rendered).to have_selector("button[type=submit]", text: "View")
    end
  end
end
