# frozen_string_literal: true

require "rails_helper"

RSpec.describe "npq_separation/admin/applications/training_statuses/edit", type: :view do
  subject { render }

  before do
    assign(:application, application)
  end

  let(:application) { build_stubbed(:application, :accepted) }
  let(:form_path) { npq_separation_admin_applications_training_status_path(application) }

  it { is_expected.to have_css("h1") }
  xit { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }

  xcontext "when there are form errors" do
    before { update_form.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
