require "rails_helper"

RSpec.describe "npq_separation/admin/applications/show.html.erb", type: :view do
  subject { Capybara.string(render) }

  before do
    assign(:application, application)
    assign(:declarations, declarations)
  end

  describe "a row for a full application" do
    let :application do
      build_stubbed :application, :accepted, :with_school, :with_private_childcare_provider
    end

    let :declarations do
      build_stubbed_pair :declaration, application_id: application.id,
                                       lead_provider: application.lead_provider
    end

    it { is_expected.to have_css "h1", text: "Application for #{application.user.full_name}" }
    it { is_expected.to have_summary_item "Application ID", application.ecf_id }
    it { is_expected.to have_summary_item "TRN", application.user.trn }
    it { is_expected.to have_summary_item "Lead provider name", application.lead_provider.name }
    it { is_expected.to have_summary_item "Course name", application.course.name }
    it { is_expected.to have_summary_item "School URN", application.school.urn }
    it { is_expected.to have_summary_item "School UKPRN", application.school.ukprn }
  end

  describe "a row for a minimal application" do
    let :application do
      build_stubbed :application, cohort: nil, itt_provider: nil, school: nil
    end

    let(:declarations) { [] }

    it { is_expected.to have_css "h1", text: "Application for #{application.user.full_name}" }
    it { is_expected.to have_summary_item "Application ID", application.ecf_id }
    it { is_expected.to have_summary_item "TRN", application.user.trn }
    it { is_expected.to have_summary_item "Lead provider name", application.lead_provider.name }
    it { is_expected.to have_summary_item "Course name", application.course.name }
    it { is_expected.to have_summary_item "School URN", "" }
    it { is_expected.to have_summary_item "School UKPRN", "" }
  end
end
