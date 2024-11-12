require "rails_helper"

RSpec.describe "npq_separation/admin/applications/revert_to_pending/new", type: :view do
  subject { render }

  before do
    assign(:application, application)
    assign(:revert_to_pending_form, revert_form)
  end

  let(:application) { build_stubbed(:application, :accepted) }
  let(:revert_form) { Applications::RevertToPendingForm.new(application, {}) }
  let(:form_path) { npq_separation_admin_applications_revert_to_pending_path(application) }

  it { is_expected.to have_css("h1", text: /Are you sure/) }
  it { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }
  it { is_expected.to have_field("applications-revert-to-pending-form-change-status-to-pending-yes-field") }
  it { is_expected.to have_css("legend", text: "Change the status to pending?") }
  it { is_expected.to have_css("label", text: "Yes") }
  it { is_expected.to have_css("label", text: "No") }

  context "when there are form errors" do
    before { revert_form.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
