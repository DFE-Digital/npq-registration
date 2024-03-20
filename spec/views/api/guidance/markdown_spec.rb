require "rails_helper"

RSpec.describe "api/guidance/test.md", type: :view do
  subject { rendered }

  let(:markdown) do
    <<~MARKDOWN
      # content

      This is a markdown page with .md extension

      [Click here](http://example.com)

      ```json
      { "key": "value" }
      ```
    MARKDOWN
  end

  before do
    stub_template "api/guidance/test.md" => markdown

    render template: "api/guidance/test"
  end

  describe "converts markdown to HTML" do
    it { is_expected.to have_css("p", text: "This is a markdown page with .md extension") }
    it { is_expected.to have_css("h1", text: "content") }
    it { is_expected.to have_css("a", text: "Click here") }
  end

  describe "converts GOV.UK specific markdown to HTML" do
    it { is_expected.to have_css("a.govuk-link", text: "Click here") }
    it { is_expected.to have_css("h1.govuk-heading-xl", text: "content") }
  end

  describe "converts code blocks to HTML" do
    it { is_expected.to have_css("pre code", text: '{ "key": "value" }') }
  end
end
