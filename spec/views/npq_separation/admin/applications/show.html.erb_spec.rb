require "rails_helper"

RSpec.describe "npq_separation/admin/applications/show.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:declarations) { [] }

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

    it { is_expected.to have_css(".govuk-caption-m", text: "#{application.user.full_name}, #{application.course.name}, #{application.created_at.to_date.to_fs(:govuk_short)}", normalize_ws: true) }
    it { is_expected.to have_css "h1", text: "Application details" }

    context "with application overview summary card" do
      subject { Capybara.string(render).find(".govuk-summary-card", text: "Overview") }

      it { is_expected.to have_summary_item "Name", application.user.full_name }
      it { is_expected.to have_summary_item "Application ID", application.ecf_id }
      it { is_expected.to have_summary_item "User ID", application.user.ecf_id }
      it { is_expected.to have_summary_item "Provider", application.lead_provider.name }
      it { is_expected.to have_summary_item "Course", application.course.name }
    end
  end

  describe "a row for an employer with no URN" do
    let :application do
      build_stubbed :application, school: nil, employer_name: "No URN"
    end

    it { is_expected.to have_text(application.employer_name_to_display) }
    it { is_expected.not_to have_link(application.employer_name_to_display) }
  end

  describe "a row for a minimal application" do
    let :application do
      build_stubbed :application, cohort: nil, itt_provider: nil, school: nil
    end

    it { is_expected.to have_css "h1", text: "Application details" }
    it { is_expected.to have_summary_item "Application ID", application.ecf_id }
    it { is_expected.to have_summary_item "Provider", application.lead_provider.name }
    it { is_expected.to have_summary_item "Course", application.course.name }
    it { is_expected.to have_summary_item "Unique reference number (URN)", "" }
    it { is_expected.to have_summary_item "UK Provider Reference Number (UKPRN)", "" }
    it { is_expected.to have_summary_item "Schedule identifier", "-" }
  end
end
