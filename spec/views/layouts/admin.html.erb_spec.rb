require "rails_helper"

RSpec.describe "layouts/admin.html.erb", type: :view do
  subject(:rendered) { Capybara.string(render) }

  let(:admin) { build_stubbed(:admin) }
  let(:nav) { Admin::NavigationStructures::AdminNavigationStructure.new(admin) }
  let(:expected_items) { nav.primary_structure.map(&:name) }

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

  describe "sidebar navigation" do
    subject do
      rendered.find(".govuk-width-container > .govuk-main-wrapper > .govuk-grid-row")
    end

    before { allow(view).to receive(:admin_navigation_structure).and_return(nav) }

    context "when sidebar navigation content present" do
      it { is_expected.to have_css "> .govuk-grid-column-one-quarter" }
      it { is_expected.to have_css "> .govuk-grid-column-three-quarters" }
      it { is_expected.not_to have_css "> .govuk-grid-column-full" }
    end

    context "when sidebar navigation content is blank" do
      before { allow(nav).to receive(:sub_structure).and_return([]) }

      it { is_expected.to have_css "> .govuk-grid-column-full" }
      it { is_expected.not_to have_css "> .govuk-grid-column-one-quarter" }
      it { is_expected.not_to have_css "> .govuk-grid-column-three-quarters" }
    end
  end
end
