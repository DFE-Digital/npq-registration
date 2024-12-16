require "rails_helper"

RSpec.describe "npq_separation/admin/finance/statements/payment_authorisations/new", type: :view do
  subject { render }

  before do
    assign(:statement, statement)
    assign(:payment_authorisation_form, auth_form)
  end

  let(:statement) { build_stubbed(:statement, month: 3, year: 2024) }
  let(:component) { NpqSeparation::Admin::StatementDetailsComponent.new(statement:, link_to_voids: false) }
  let(:auth_form) { Statements::PaymentAuthorisationForm.new(statement, {}) }
  let(:form_path) { npq_separation_admin_finance_payment_authorisation_path(statement) }

  it { is_expected.to have_css("h1", text: /Check March 2024 statement/) }
  it { is_expected.to have_component(component) }
  it { is_expected.to have_css(%(form[action="#{form_path}"]), count: 1) }
  it { is_expected.to have_field("statements-payment-authorisation-form-checks-done-1-field") }
  it { is_expected.to have_css("legend", text: /Have all necessary assurance/) }
  it { is_expected.to have_css("label", text: /Yes, I'm ready/) }

  context "when there are form errors" do
    before { auth_form.valid? }

    it { is_expected.to have_css(".govuk-error-summary") }
    it { is_expected.to have_css(".govuk-error-message") }
  end
end
