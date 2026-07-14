require "rails_helper"

RSpec.describe "accounts/show.html.erb", type: :view do
  subject { render }

  before do
    assign(:active_applications, active_applications)
    assign(:expired_applications, expired_applications)
    allow(view).to receive(:current_user).and_return(user)
  end

  let(:user) { create(:user, :with_teacher_auth) }
  let(:active_applications) { create_list :application, 2, user: }
  let(:expired_applications) { [] }

  it { is_expected.to have_css "h1", text: "Your NPQ registrations" }
  it { is_expected.to have_content "Register for another NPQ" }
  it { is_expected.to have_css ".govuk-summary-card", count: 2 }
  it { is_expected.to have_link "View details", href: accounts_user_registration_path(active_applications[0]) }
  it { is_expected.to have_link "View details", href: accounts_user_registration_path(active_applications[1]) }

  it "shows a link to update personal details on GOV.UK One Login" do
    expect(render).to have_link "GOV.UK One Login (opens in a new tab)", href: Rails.configuration.x.teacher_auth.onelogin_home_uri
  end

  it "shows the awaiting provider application status" do
    expect(render).to have_content "Awaiting provider"
    expect(render).to have_content "Your provider will contact you with instructions on how to apply for the course."
  end

  context "with expired applications" do
    let(:active_applications) { [active] }
    let(:expired_applications) { [expired] }
    let(:active) { create :application, user: }

    let :expired do
      create :application,
             user:,
             lead_provider_approval_status: :rejected,
             created_at: Application.cut_off_date_for_expired_applications - 1.day
    end

    it { is_expected.to have_content "Register for another NPQ" }
    it { is_expected.to have_content "Expired registrations" }
    it { is_expected.to have_css ".govuk-summary-card", count: 2 }
    it { is_expected.to have_link "View details", href: accounts_user_registration_path(active) }
    it { is_expected.not_to have_link "View details", href: accounts_user_registration_path(expired) }
  end

  context "when signed in via Get an Identity" do
    let(:user) { create(:user, :with_get_an_identity_id) }

    it { is_expected.not_to have_content "Register for another NPQ" }
  end
end
