require "rails_helper"

RSpec.describe "accounts/_provider_pending_status.html.erb", type: :view do
  subject { Capybara.string(rendered) }

  before do
    render partial: "accounts/provider_pending_status"
  end

  it "renders the main instruction paragraph" do
    expect(subject).to have_css("p.govuk-body", text: /You need to apply separately with your training provider/)
  end

  it "renders the email notification paragraph" do
    expect(subject).to have_css("p.govuk-body", text: /They.ll email you/)
  end

  it "renders the application process introduction paragraph" do
    expect(subject).to have_css("p.govuk-body", text: /During the application process, your provider will check your:/)
  end

  it "renders the checklist as a bulleted list" do
    expect(subject).to have_css("ul.govuk-list.govuk-list--bullet")
  end

  describe "checklist items" do
    it "includes identity check" do
      expect(subject).to have_css("li", text: "identity")
    end

    it "includes place of work check" do
      expect(subject).to have_css("li", text: "place of work")
    end

    it "includes course suitability check" do
      expect(subject).to have_css("li", text: /suitability for the NPQ course you.ve chosen/)
    end

    it "includes funding eligibility check" do
      expect(subject).to have_css("li", text: "eligibility for scholarship funding")
    end

    it "includes workplace support check" do
      expect(subject).to have_css("li", text: "decision to complete an NPQ is supported by your workplace")
    end
  end

  it "renders all five checklist items" do
    expect(subject).to have_css("li", count: 5)
  end

  it "uses correct GOV.UK Design System classes" do
    expect(subject).to have_css(".govuk-body")
    expect(subject).to have_css("[class*='govuk-!-margin-top-2']")
    expect(subject).to have_css(".govuk-list")
    expect(subject).to have_css(".govuk-list--bullet")
  end

  it "has the correct structure with paragraphs and list" do
    # Should have 3 paragraphs
    expect(subject).to have_css("p", count: 3)

    # Should have 1 unordered list
    expect(subject).to have_css("ul", count: 1)

    # List should contain 5 items
    expect(subject).to have_css("ul li", count: 5)
  end

  it "renders content in the correct order" do
    content = subject.text.strip

    # Check that content appears in the expected order
    apply_index = content.index("You need to apply separately")
    email_index = content.index("email you")
    process_index = content.index("During the application process")
    identity_index = content.index("identity")

    expect(apply_index).to be < email_index
    expect(email_index).to be < process_index
    expect(process_index).to be < identity_index
  end
end
