require "rails_helper"

RSpec.describe "admin/applications/show.html.erb", type: :view do
  let(:application_page) { ApplicationPage.new }
  let(:application) { create(:application, targeted_delivery_funding_eligibility: true, DEPRECATED_private_childcare_provider_urn: "EY98753") }

  it "displays targeted_delivery_funding_eligibility" do
    assign(:application, application)
    render
    application_page.load(rendered)

    expect(application_page.summary_list["Targeted delivery funding eligibility"].value).to eql("YES")
  end

  it "displays application created_at" do
    assign(:application, application)
    render
    application_page.load(rendered)

    expected = application.created_at.strftime("%R on %d/%m/%Y")

    expect(application_page.summary_list["Created at"].value).to eql(expected)
  end

  it "displays application DEPRECATED_private_childcare_provider_urn" do
    assign(:application, application)
    render
    application_page.load(rendered)

    expect(application_page.summary_list["Private Childcare Provider URN"].value).to eql("EY98753")
  end
end
