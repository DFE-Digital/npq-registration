require "rails_helper"

RSpec.describe "layouts/api_docs.html.erb", type: :view do
  subject { Capybara.string(render) }

  describe "service navigation" do
    it { is_expected.to have_css(".govuk-service-navigation__container", text: "Register for a national professional qualification") }
  end
end
