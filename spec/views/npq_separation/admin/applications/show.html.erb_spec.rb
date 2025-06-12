require "rails_helper"

RSpec.describe "npq_separation/admin/applications/show.html.erb", type: :view do
  subject { Capybara.string(render) }

  before do
    assign(:application, application)
    assign(:declarations, declarations)
  end

  describe "a row for a full application" do
    let :application do
      build_stubbed :application, :accepted, :with_school
    end

    let :declarations do
      build_stubbed_pair :declaration, application_id: application.id,
                                       lead_provider: application.lead_provider
    end

    it { is_expected.to have_css "h1", text: application.user.full_name }
    it { is_expected.to have_text "TRN: #{application.user.trn}", normalize_ws: true }
    it { is_expected.to have_summary_item "Unique reference number (URN)", application.school.urn }
    it { is_expected.to have_summary_item "UK Provider Reference Number (UKPRN)", application.school.ukprn }

    context "with application overview summary card" do
      subject { Capybara.string(render).find(".govuk-summary-card", text: "Application overview") }

      it { is_expected.to have_summary_item "Application ID", application.ecf_id }
      it { is_expected.to have_summary_item "Course provider", application.lead_provider.name }
      it { is_expected.to have_summary_item "Course", application.course.name }
    end
  end

  describe "a row for a minimal application" do
    let :application do
      build_stubbed :application, cohort: nil, itt_provider: nil, school: nil
    end

    let(:declarations) { [] }

    it { is_expected.to have_css "h1", text: application.user.full_name }
    it { is_expected.to have_text "TRN: #{application.user.trn}", normalize_ws: true }
    it { is_expected.to have_summary_item "Application ID", application.ecf_id }
    it { is_expected.to have_summary_item "Course provider", application.lead_provider.name }
    it { is_expected.to have_summary_item "Course", application.course.name }
    it { is_expected.to have_summary_item "Unique reference number (URN)", "" }
    it { is_expected.to have_summary_item "UK Provider Reference Number (UKPRN)", "" }
  end
end
