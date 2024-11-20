# frozen_string_literal: true

require "rails_helper"

RSpec.describe "npq_separation/admin/applications/change_training_statuses/new", type: :view do
  subject { render }

  before do
    assign(:application, application)
    assign(:change_training_status, change_training_status)
  end

  let(:application) { build_stubbed(:application, :accepted) }
  let(:change_training_status) { Applications::ChangeTrainingStatus.new(application:) }
  let(:form_path) { npq_separation_admin_applications_change_training_status_path(application) }

  it { is_expected.to have_css("h1", text: "Change training status") }

  it { is_expected.to have_css(".govuk-inset-text p:first-of-type", text: application.user.id) }
  it { is_expected.to have_css(".govuk-inset-text p:last-of-type", text: "Active") }
  it { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }
  it { is_expected.to have_css(%(.govuk-form-group fieldset label), text: "Deferred") }
  it { is_expected.to have_css(%(.govuk-form-group fieldset label), text: "Withdrawn") }
  it { is_expected.to have_css("optgroup", count: 2) }
  it { is_expected.to have_css("optgroup option") }

  context "when there are form errors" do
    before { change_training_status.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
