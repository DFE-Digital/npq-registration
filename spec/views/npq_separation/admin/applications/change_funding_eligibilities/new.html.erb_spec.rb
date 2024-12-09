# frozen_string_literal: true

require "rails_helper"

RSpec.describe "npq_separation/admin/applications/change_funding_eligibilities/new", type: :view do
  subject { render }

  before do
    assign(:application, application)
    assign(:funding_eligibility, change_funding_eligibility)
  end

  let(:application) { build_stubbed(:application, :accepted) }
  let(:change_funding_eligibility) { Applications::ChangeFundingEligibility.new(application:) }

  let :form_path do
    npq_separation_admin_applications_change_funding_eligibility_path(application)
  end

  it { is_expected.to have_css("h1", text: application.user.full_name) }
  it { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }
  it { is_expected.to have_css(%(.govuk-form-group fieldset label), text: "Yes") }
  it { is_expected.to have_css(%(.govuk-form-group fieldset label), text: "No") }

  context "when there are form errors" do
    before { change_funding_eligibility.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
