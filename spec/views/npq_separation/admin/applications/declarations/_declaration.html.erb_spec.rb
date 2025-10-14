require "rails_helper"

RSpec.describe "npq_separation/admin/applications/declarations/_declaration.html.erb", type: :view do
  subject { Capybara.string(render(locals: { declaration: })) }

  let(:declaration) { build_stubbed(:declaration, delivery_partner: nil) }

  it { is_expected.to have_summary_item("Declaration ID", declaration.ecf_id) }
  it { is_expected.to have_summary_item("Declaration date", declaration.declaration_date.to_fs(:govuk_short)) }
  it { is_expected.to have_summary_item("Declaration cohort", declaration.cohort.start_year) }
  it { is_expected.to have_summary_item("Provider", declaration.lead_provider.name) }
  it { is_expected.to have_summary_item("Delivery partner", "-") }
  it { is_expected.to have_summary_item("Secondary delivery partner", "-") }
  it { is_expected.to have_summary_item("Created at", declaration.created_at.to_fs(:govuk_short)) }
  it { is_expected.to have_summary_item("Updated at", declaration.updated_at.to_fs(:govuk_short)) }
  it { is_expected.to have_summary_item("Statements", "") }

  context "with delivery partners" do
    let(:declaration) { build_stubbed(:declaration, delivery_partner: build_stubbed(:delivery_partner), secondary_delivery_partner: build_stubbed(:delivery_partner)) }

    it { is_expected.to have_summary_item("Delivery partner", declaration.delivery_partner.name) }
    it { is_expected.to have_summary_item("Secondary delivery partner", declaration.secondary_delivery_partner.name) }
  end

  describe "state history timeline entries", :versioning do
    let(:declaration) { create(:declaration, :eligible) }

    it { is_expected.to have_css(".moj-timeline") }
    it { is_expected.to have_css(".moj-timeline__item", text: /Eligible\s+#{declaration.created_at.to_fs(:govuk_short)}/) }
  end
end
