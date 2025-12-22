require "rails_helper"

RSpec.describe "accounts/_work_details.html.erb", type: :view do
  subject(:rendered_page) { render(partial: "accounts/work_details", locals: { application: }) && Capybara.string(rendered) }

  let(:application) { build_stubbed(:application, employment_type: "lead_mentor_for_accredited_itt_provider", itt_provider:) }

  context "when itt_provider is present" do
    let(:itt_provider) { build_stubbed(:itt_provider) }

    it { is_expected.to have_summary_item "ITT provider", itt_provider.legal_name }
  end

  context "when itt_provider is nil" do
    let(:itt_provider) { nil }

    it { is_expected.to have_summary_item "ITT provider", "" }
  end
end
