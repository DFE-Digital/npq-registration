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
      Node.new(
        name: "Third",
        href: "/c",
        prefix: "/c",
      ) => [
        Node.new(name: "Third - with no prefix", href: "#"),
      ],
    }
  end
end

RSpec.describe NpqSeparation::SubNavigationComponent, type: :component do
  let(:current_path) { "/a" }
  let(:structure) { TestSubNavigationStructure.new }
  let(:heading) { {} }
  let(:default_to_first_section) { false }

  subject do
    NpqSeparation::SubNavigationComponent.new(current_path, structure: structure.sub_structure(current_path, default_to_first_section: default_to_first_section), heading:)
  end

  it "renders a visually hidden level 2 heading" do
    render_inline(subject)

    expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "Navigation")
  end

  context "when an unrecognised section is provided" do
    let(:current_path) { "/missing" }

    it "raises an error" do
      expect { render_inline(subject) }.to raise_error(NpqSeparation::NavigationStructure::SectionNotFoundError)
    end

    context "and default_to_first_section is true" do
      let(:default_to_first_section) { true }

      it "renders the first section" do
        render_inline(subject)

        expect(rendered_content).to have_css("li.x-govuk-sub-navigation__section-item", text: "This is the first page")
      end
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

  describe "when navigation node prefix is nil" do
    let(:current_path) { "/c" }

    it "does not highlight the section as current" do
      render_inline(subject)

      expect(rendered_content).to have_css("li.x-govuk-sub-navigation__section-item")
      expect(rendered_content).not_to have_css("li.x-govuk-sub-navigation__section-item--current")
    end
  end

  describe "heading" do
    before { render_inline(subject) }

    context "when heading options are not provided" do
      it "renders a visually hidden default heading" do
        expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "Navigation")
      end
    end

    context "when heading text is provided" do
      let(:heading) do
        { text: "My heading" }
      end

      it "renders the heading text" do
        expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "My heading")
      end
    end

    context "when heading visbility is enabled" do
      let(:heading) do
        { visible: true }
      end

      it "renders the heading" do
        expect(rendered_content).to have_css("h2:not(.govuk-visually-hidden)", text: "Navigation")
      end
    end
  end
end
