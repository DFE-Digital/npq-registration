require "rails_helper"

RSpec.describe "accounts/user_registrations/_work_details.html.erb", type: :view do
  subject { render_page && Capybara.string(rendered) }

  let :render_page do
    render(partial: "accounts/user_registrations/work_details", locals: { application: })
  end

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
