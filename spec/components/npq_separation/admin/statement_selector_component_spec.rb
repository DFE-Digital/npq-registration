# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementSelectorComponent, type: :component do
  let(:lead_provider)    { create :lead_provider }
  let!(:statement)       { create(:statement, lead_provider:) }
  let(:cohort)           { statement.cohort }

  let(:rendered) { render_inline(described_class.new(statement)) }

  it "has a form that GETs to correct action" do
    expect(rendered).to have_selector("form[method=get][action='/npq-separation/admin/finance/statements']")
  end

  it "has dropdown with lead providers" do
    expect(rendered).to have_selector("select#lead-provider-id-field")
    expect(rendered).to have_selector("select#lead-provider-id-field option[value='#{lead_provider.id}']", text: lead_provider.name)
  end

  it "has dropdown with cohorts" do
    expect(rendered).to have_selector("select#cohort-id-field")
    expect(rendered).to have_selector("select#cohort-id-field option[value='#{cohort.id}']", text: cohort.start_year)
  end

  it "has dropdown with period" do
    expect(rendered).to have_selector("select#period-field")
    expect(rendered).to have_selector("select#period-field option[value='#{statement.period}']", text: statement.name)
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

  it "defaults to selected period" do
    expect(rendered).to have_selector("select#period-field option[selected]", text: statement.name, visible: :all)
  end
end
