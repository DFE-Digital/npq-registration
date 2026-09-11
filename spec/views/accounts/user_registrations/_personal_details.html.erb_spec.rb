require "rails_helper"

RSpec.describe "accounts/user_registrations/_personal_details.html.erb", type: :view do
  subject { render_page && Capybara.string(rendered) }

  let :render_page do
    render(partial: "accounts/user_registrations/personal_details")
  end

  it { is_expected.to have_css("h2", text: "Personal details") }

  it "tells the user how to get their certificate" do
    expect(subject).to have_text("If you pass your course, you can sign in to the teaching qualifications service to view or download your certificate.")
  end

  it "links to the teaching qualifications service" do
    expect(subject).to have_link("teaching qualifications service", href: ExternalLink.fetch(:access_your_teaching_qualifications).url)
  end

  it "tells the user how to change their personal details" do
    expect(subject).to have_text("To change your personal details, you can go to your GOV.UK One Login account")
  end

  it "links to the GOV.UK One Login account" do
    expect(subject).to have_link("GOV.UK One Login account", href: Rails.configuration.x.teacher_auth.onelogin_home_uri)
  end
end
