require "rails_helper"

RSpec.describe "npq_separation/admin/users/_application.html.erb", type: :view do
  subject { Capybara.string(rendered) }

  let :rendered do
    render("npq_separation/admin/users/application", application:,
                                                     application_iteration:)
  end

  let(:application_iteration) { Struct.new(:index).new(1) }

  context "with school present" do
    let :application do
      build_stubbed :application, :accepted, :with_school, :with_private_childcare_provider
    end

    it { is_expected.to have_summary_item "Application ID", application.id }
    it { is_expected.to have_summary_item "Lead Provider", application.lead_provider.name }
    it { is_expected.to have_summary_item "Lead Provider Approval Status", application.lead_provider_approval_status }
    it { is_expected.to have_summary_item "NPQ Course", application.course.name }
    it { is_expected.to have_summary_item "School URN", application.school.urn }
    it { is_expected.to have_summary_item "School UKPRN", application.school.ukprn }
    it { is_expected.to have_summary_item "Funded Place", "" }
    it { is_expected.to have_summary_item "Created At", application.created_at.to_fs(:govuk_short) }
    it { is_expected.to have_summary_item "Updated At", application.updated_at.to_fs(:govuk_short) }
  end

  context "without school present" do
    let :application do
      build_stubbed :application, cohort: nil, itt_provider: nil, school: nil
    end

    it { is_expected.to have_summary_item "Application ID", application.id }
    it { is_expected.to have_summary_item "Lead Provider", application.lead_provider.name }
    it { is_expected.to have_summary_item "Lead Provider Approval Status", application.lead_provider_approval_status }
    it { is_expected.to have_summary_item "NPQ Course", application.course.name }
    it { is_expected.to have_summary_item "School URN", "" }
    it { is_expected.to have_summary_item "School UKPRN", "" }
    it { is_expected.to have_summary_item "Funded Place", "" }
    it { is_expected.to have_summary_item "Created At", application.created_at.to_fs(:govuk_short) }
    it { is_expected.to have_summary_item "Updated At", application.updated_at.to_fs(:govuk_short) }
  end
end
