require "rails_helper"

RSpec.describe "npq_separation/admin/applications/index.html.erb", type: :view do
  subject { render }

  before { assign :applications, [full_application, minimal_application] }

  let :full_application do
    build_stubbed :application, :accepted, :with_school, :with_private_childcare_provider
  end

  let :minimal_application do
    build_stubbed :application, cohort: nil, itt_provider: nil, school: nil
  end

  it { is_expected.to have_css "h1", text: "All applications" }

  it { is_expected.to have_css "table.govuk-table thead tr", count: 1 }
  it { is_expected.to have_css "table.govuk-table tbody tr", count: 2 }

  # full application
  describe "a row for a full application" do
    it { is_expected.to have_css "tbody tr:first-of-type a", text: full_application.ecf_id }
    it { is_expected.to have_css "tbody tr:first-of-type a", text: full_application.user.full_name }
    it { is_expected.to have_css "tbody tr:first-of-type a", text: full_application.school.name }
  end

  describe "a row for a minimal application" do
    it { is_expected.to have_css "tbody tr:last-of-type a", text: minimal_application.ecf_id }
    it { is_expected.to have_css "tbody tr:last-of-type a", text: minimal_application.user.full_name }
    it { is_expected.to have_css "tbody tr:last-of-type td", text: "" }
  end
end
