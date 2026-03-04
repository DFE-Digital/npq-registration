require "rails_helper"

RSpec.describe "npq_separation/admin/applications/declarations/index.html.erb", :versioning, type: :view do
  subject { Capybara.string(render) }

  let(:application) { build_stubbed(:application) }

  before do
    assign(:application, application)
    assign(:declarations, [])
  end

  context "with no declarations" do
    it { is_expected.to have_text("No declarations.") }
    it { is_expected.not_to have_css ".govuk-summary-card" }
  end

  context "with declarations" do
    before do
      assign :declarations, [
        build_stubbed(:declaration, application:, created_at: 1.day.ago),
        build_stubbed(:declaration, application:, created_at: 2.days.ago),
      ]
    end

    it { is_expected.not_to have_text("No declarations.") }
    it { is_expected.to have_css ".govuk-summary-card", count: 2 }
  end
end
