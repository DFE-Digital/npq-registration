require "rails_helper"

RSpec.describe "accounts/show.html.erb", type: :view do
  subject { render }

  before do
    applications
    allow(view).to receive(:current_user).and_return(user)
  end

  let(:user) { create(:user) }
  let(:applications) { create_list :application, 2, user: }

  it { is_expected.to have_content "Register for another NPQ" }
  it { is_expected.to have_css ".govuk-summary-card", count: 2 }
  it { is_expected.to have_link "View details", href: accounts_user_registration_path(applications[0]) }
  it { is_expected.to have_link "View details", href: accounts_user_registration_path(applications[1]) }

  context "with expired applications" do
    before do
      applications[0].update!(lead_provider_approval_status: :rejected,
                              created_at: Application.cut_off_date_for_expired_applications - 1.day)
    end

    it { is_expected.to have_content "Register for another NPQ" }
    it { is_expected.to have_css ".govuk-summary-card", count: 2 }
    it { is_expected.to have_link "View details", href: accounts_user_registration_path(applications[0]) }
    it { is_expected.to have_link "View details", href: accounts_user_registration_path(applications[1]) }
  end
end
