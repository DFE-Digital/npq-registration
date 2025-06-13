# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementSelectorComponent, type: :component do
  include StatementHelper

  let(:lead_provider)    { create :lead_provider }
  let!(:statement)       { create(:statement, lead_provider:) }
  let(:cohort)           { statement.cohort }
  let(:instance)         { described_class.new(statement) }

  let(:rendered) { render_inline instance }
  let(:payment_status_selector) { "select#payment-status-field" }

  it "has a form that GETs to correct action" do
    expect(rendered).to have_selector("form[method=get][action='/npq-separation/admin/finance/statements']")
  end

  it "has dropdown with state" do
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
    expect(rendered).to have_selector("select#cohort-id-field option[value='#{cohort.id}']", text: cohort.start_year)
  end

  it "has dropdown with statement" do
    expect(rendered).to have_selector("select#statement-field")
    expect(rendered).to have_selector("select#statement-field option[value='#{statement_period(statement)}']", text: statement_name(statement))
  end

  it "has submit button" do
    expect(rendered).to have_selector("button[type=submit]")
  end

  it "defaults to selected lead provider" do
    expect(rendered).to have_selector("select#lead-provider-id-field option[selected]", text: statement.lead_provider.name, visible: :all)
  end

  it "defaults to selected cohort" do
    expect(rendered).to have_selector("select#cohort-id-field option[selected]", text: statement.cohort.start_year, visible: :all)
  end

  it "defaults to selected statement" do
    expect(rendered).to have_selector("select#statement-field option[selected]", text: statement_name(statement), visible: :all)
  end

  context "when sidebar mode is enabled" do
    let(:instance) { described_class.new(statement, sidebar: true) }

    it "does not have payment status dropdown" do
      expect(rendered).not_to have_selector(payment_status_selector)
    end

    it "uses a single-column layout" do
      expect(rendered).to have_selector(".govuk-grid-column-full", count: 3)
      expect(rendered).not_to have_selector(".govuk-grid-column-one-half")
    end
  end
end
