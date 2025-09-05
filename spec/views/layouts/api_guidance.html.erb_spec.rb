require "rails_helper"

RSpec.describe "layouts/api_guidance.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:expected_items) do
    structure = NpqSeparation::NavigationStructures::GuidanceNavigationStructure.new
    structure.primary_structure.map(&:name)
  end

  before do
    view.instance_variable_set(:@page, instance_double(Guidance::GuidancePage, index_page?: true))
  end

  describe "service navigation" do
    it { is_expected.not_to have_css(".govuk-service-navigation__service-name") }

    it "has links for the guidance navigation structure" do
      expected_items.each do |item|
        expect(subject).to have_link(item)
      end
    end
  end
end
