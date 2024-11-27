# frozen_string_literal: true

require "rails_helper"

RSpec.describe "npq_separation/admin/applications/change_funding_eligibilities/new", type: :view do
  subject { render }

  before { assign(:application, application) }

  let(:application) { build_stubbed(:application, :accepted) }

  let :form_path do
    npq_separation_admin_applications_change_funding_eligibility_path(application)
  end

  it { is_expected.to have_css("h1") }
  xit { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }

  xcontext "when there are form errors" do
    before { update_form.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
