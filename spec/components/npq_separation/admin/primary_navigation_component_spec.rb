require "rails_helper"

RSpec.describe NpqSeparation::Admin::PrimaryNavigationComponent, type: :component do
  let(:path) { "/some-path" }

  before { render_inline(NpqSeparation::Admin::PrimaryNavigationComponent.new(path)) }

  it "renders a visually hidden level 2 heading" do
    expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "Navigation")
  end

  it "renders an unordered list of navigation nodes" do
    expect(rendered_content).to have_css(".x-govuk-primary-navigation .govuk-width-container > ul.x-govuk-primary-navigation__list")
  end

  it "lists the right primary navigation items" do
    {
      "Dashboard" => "/npq-separation/admin/dashboards/summary",
      "Applications" => "/npq-separation/admin/applications",
      "Finance" => "/npq-separation/admin/finance/statements",
      "Schools" => "#",
      "Lead providers" => "#",
      "Settings" => "#",
    }.each do |text, href|
      expect(rendered_content).to have_css(%(ul > li.x-govuk-primary-navigation__item a.x-govuk-primary-navigation__link[href="#{href}"]), text:)
    end
  end

  context "when we're looking at section" do
    {
      "Dashboard" => "/npq-separation/admin/dashboards/summary",
      "Applications" => "/npq-separation/admin/applications/all",
      "Finance" => "/npq-separation/admin/finance/statements",
      # "Schools" => "#",
      # "Lead providers" => "#",
      # "Settings" => "#",
    }.each do |text, path|
      describe text do
        let(:path) { path }

        specify "'#{text}' is the current section and is the only one highlighted" do
          expect(rendered_content).to have_css("li.x-govuk-primary-navigation__item.x-govuk-primary-navigation__item--current a", text:)
          expect(rendered_content).to have_css(".x-govuk-primary-navigation__item--current", count: 1)
        end
      end
    end
  end
end
