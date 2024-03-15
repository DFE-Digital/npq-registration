require "rails_helper"

class TestSubNavigationStructure < NpqSeparation::NavigationStructure
  def structure
    {
      Node.new(
        name: "First",
        href: "/a",
        prefix: "/a",
      ) => [
        Node.new(
          name: "This is the first page",
          href: "/a/first",
          prefix: "/a/first",
          nodes: [
            Node.new(name: "First part 1", href: "#", prefix: "/a/first/one"),
            Node.new(name: "First part 2", href: "#", prefix: "/a/first/two"),
          ],
        ),
      ],
      Node.new(
        name: "Second",
        href: "/b",
        prefix: "/b",
      ) => [
        Node.new(
          name: "This is the second page",
          href: "/b/second",
          prefix: "/b/second",
          nodes: [
            Node.new(name: "Second part 1", href: "#", prefix: "/b/second/one"),
            Node.new(name: "Second part 2", href: "#", prefix: "/b/second/two"),
          ],
        ),
      ],
    }
  end
end

RSpec.describe NpqSeparation::SubNavigationComponent, type: :component do
  let(:current_path) { "/some-path" }
  let(:current_section) { "First" }
  let(:structure) { TestSubNavigationStructure.new }

  subject do
    NpqSeparation::SubNavigationComponent.new(current_path, structure: structure.sub_structure(current_section))
  end

  it "renders a visually hidden level 2 heading" do
    render_inline(subject)

    expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "Navigation")
  end

  context "when an unrecognised section is provided" do
    let(:current_section) { "Missing" }

    it "renders a visually hidden level 2 heading" do
      expect { render_inline(subject) }.to raise_error(NpqSeparation::NavigationStructure::SectionNotFoundError)
    end
  end

  it "only renders the provided current_section" do
    render_inline(subject)

    selector = "li.x-govuk-sub-navigation__section-item > a.x-govuk-sub-navigation__link"

    expect(rendered_content).to have_css(selector, text: "This is the first page")
    expect(rendered_content).not_to have_css(selector, text: "This is the second page")
  end

  it "only renders the navigation nodes within the subsection" do
    render_inline(subject)

    selector = %w[
      li.x-govuk-sub-navigation__section-item
      ul.x-govuk-sub-navigation__section--nested
      li.x-govuk-sub-navigation__section-item
      a.x-govuk-sub-navigation__link
    ].join(" > ")

    expect(rendered_content).to have_css(selector, text: "First part 1")
    expect(rendered_content).to have_css(selector, text: "First part 2")

    expect(rendered_content).not_to have_css(selector, text: /Second/)
  end

  describe "highlighting the current section" do
    context "when the prefix matches the start of the current path" do
      let(:current_path) { "/b/second" }
      let(:current_section) { "Second" }

      it "marks only the section as current" do
        render_inline(subject)

        selector = "li.x-govuk-sub-navigation__section-item--current"

        expect(rendered_content).to have_css(selector, text: "This is the second page")
        expect(rendered_content).to have_css(selector, count: 1)
      end
    end
  end

  describe "highlighting the current link in the right subsection" do
    context "when the prefix matches the start of the current path" do
      let(:current_path) { "/b/second/two" }
      let(:current_section) { "Second" }

      it "marks only the section as current" do
        render_inline(subject)

        selector = %w[
          li.x-govuk-sub-navigation__section-item
          ul.x-govuk-sub-navigation__section--nested
          li.x-govuk-sub-navigation__section-item
          a.x-govuk-sub-navigation__link[aria-current="true"]
        ].join(" > ")

        expect(rendered_content).to have_css(selector, text: "Second part 2")
        expect(rendered_content).to have_css(selector, count: 1)
      end
    end
  end
end
