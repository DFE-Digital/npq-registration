require "rails_helper"

RSpec.describe NpqSeparation::Admin::SecondaryNavigationComponent, type: :component do
  let(:fake_logger) { object_double(Rails.logger, error: true) }
  let(:path) { "/npq-separation/admin" }

  before do
    allow(Rails).to receive(:logger).and_return(fake_logger)
    render_inline(NpqSeparation::Admin::SecondaryNavigationComponent.new(path))
  end

  it "renders a visually hidden level 2 heading" do
    expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "Navigation")
  end

  context "when a current path that doesn't match any section prefixes is provided" do
    let(:path) { "/npq-separation/some-other-path" }

    it "doesn't render anything" do
      expect(rendered_content).to be_empty
    end

    it "logs an error but doesn't raise" do
      expect(fake_logger).to have_received(:error).with("No matching admin section for '#{path}'")
    end
  end

  describe "main sections" do
    describe "Dashboard" do
      context "when the path is '/npq-separation/dashboard'" do
        let(:path) { "/npq-separation/admin/dashboard" }
        let(:list_item_matcher) { "ul.x-govuk-sub-navigation__section li.x-govuk-sub-navigation__section-item.x-govuk-sub-navigation__section-item--current" }
        let(:sublist_item_matcher) { "ul.x-govuk-sub-navigation__section.x-govuk-sub-navigation__section--nested" }

        it "renders the secondary nav with 'Dashboard' marked as current " do
          expect(rendered_content).to have_css(list_item_matcher)
          expect(rendered_content).to have_css("#{list_item_matcher} a.x-govuk-sub-navigation__link[aria-current='true']", text: "Summary")
        end

        it "renders the nested items beneath 'Dashboard' as extra subnavigation nodes" do
          { "Dashboard 1" => "#", "Dashboard 2" => "#" }.each do |text, href|
            expect(page).to have_css("#{list_item_matcher} #{sublist_item_matcher} a[href='#{href}']", text:)
          end
        end

        context "when a subnavigation node is current" do
          let(:path) { "/npq-separation/admin/dashboards/one" }

          it "adds aria-current to the current subnode" do
            expect(page).to have_css("#{list_item_matcher} #{sublist_item_matcher} a[aria-current='true'][href='#']", text: "Dashboard 1")
          end
        end
      end
    end
  end
end
