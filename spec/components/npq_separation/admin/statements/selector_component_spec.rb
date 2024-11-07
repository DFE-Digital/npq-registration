# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::Statements::SelectorComponent, type: :component do
  let(:lead_provider)    { create :lead_provider }
  let!(:statement)       { create(:statement, lead_provider:) }
  let!(:other_statement) { create(:statement) }
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

  it "has dropdown with statements" do
    expect(rendered).to have_selector("select#period-field")
    expect(rendered).to have_selector("select#period-field option[value='#{statement.period}']", text: statement.name)
  end

  it "has submit button" do
    expect(rendered).to have_selector("button[type=submit]")
  end

  it "defaults selected lead provider to current lead provider" do
    expect(rendered).to have_selector("select#lead-provider-id-field option[selected]", text: statement.lead_provider.name, visible: false)
  end

  it "defaults selected lead provider to current lead provider" do
    expect(rendered).to have_selector("select#cohort-id-field option[selected]", text: statement.cohort.start_year, visible: false)
  end

  it "defaults selected statement to current statement" do
    expect(rendered).to have_selector("select#period-field option[selected]", text: statement.name, visible: false)
  end
end
