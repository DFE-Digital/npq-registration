require "rails_helper"

RSpec.describe "admin/applications/show.html.erb", type: :view do
  let(:application_page) { ApplicationPage.new }

  it "displays targeted_support_funding_eligibility" do
    assign(:application, build(:application, targeted_support_funding_eligibility: true))

    render

    application_page.load(rendered)

    expect(application_page.summary_list["Targeted support funding eligibility"].value).to eql("YES")
  end
end
