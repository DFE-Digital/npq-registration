require "rails_helper"

RSpec.describe "admin/applications/show.html.erb", type: :view do
  let(:application) { create(:application, targeted_delivery_funding_eligibility: true, DEPRECATED_private_childcare_provider_urn: "EY98753") }

  it "displays targeted_delivery_funding_eligibility" do
    assign(:application, application)

    render

    expect(rendered).to match(/Targeted delivery funding eligibility.*YES/m)
  end

  it "displays application created_at" do
    assign(:application, application)

    render

    expected = application.created_at.strftime("%R on %d/%m/%Y")
    expect(rendered).to match(/Created at.*#{expected}/m)
  end

  it "displays application DEPRECATED_private_childcare_provider_urn" do
    assign(:application, application)

    render

    expect(rendered).to match(/Private Childcare Provider URN.*EY98753/m)
  end
end
