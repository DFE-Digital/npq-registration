require "rails_helper"

RSpec.describe "layouts/admin.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:admin) { build_stubbed(:admin) }
  let(:expected_items) do
    structure = NpqSeparation::NavigationStructures::AdminNavigationStructure.new(admin)
    structure.primary_structure.map(&:name)
  end

  before do
    view.define_singleton_method(:current_admin, &method(:admin))
  end

  describe "service navigation" do
    it { is_expected.to have_css(".govuk-service-navigation__container", text: "Manage NPQs") }

    it "has links for the admin navigation primary structure" do
      expected_items.each do |item|
        expect(subject).to have_link(item)
      end
    end

    it { is_expected.to have_link("Sign out") }
  end
end
