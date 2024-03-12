require "rails_helper"

RSpec.describe NpqSeparation::Admin::StatementsTableComponent, type: :component do
  subject! do
    render_inline(NpqSeparation::Admin::StatementsTableComponent.new(statements, show_lead_provider:))
  end

  let(:statements) { FactoryBot.create_list(:statement, 3) }
  let(:show_lead_provider) { true }
  let(:expected_columns) { ["ID", "Lead provider", "Cohort", "Status"] }

  it "renders a table with ID, Lead provider, Cohort and Status columns" do
    expected_columns.each do |heading|
      expect(rendered_content).to have_css("th", text: heading)
    end
  end

  it "renders a link to each statement page" do
    statements.each do |statement|
      expect(page).to have_link(statement.id.to_s, href: "/npq-separation/admin/finance/statements/#{statement.id}")
    end
  end

  it "renders a link to each cohort page"

  it "renders a link to each lead provider page" do
    statements.each do |statement|
      expect(page).to have_link(statement.lead_provider.name, href: "/npq-separation/admin/lead-providers/#{statement.lead_provider.id}")
    end
  end

  context "when show_lead_provider: false" do
    let(:show_lead_provider) { false }

    it "renders no lead provider column" do
      expect(rendered_content).not_to have_css("th", text: "Lead provider")
    end

    it "does render the other columns" do
      expected_columns.excluding("Lead provider").each do |heading|
        expect(rendered_content).to have_css("th", text: heading)
      end
    end
  end
end
