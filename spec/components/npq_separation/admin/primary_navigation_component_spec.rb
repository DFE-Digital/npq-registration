require "rails_helper"

class TestPrimaryNavigationStructure < NpqSeparation::Admin::PrimaryNavigationComponent::PrimaryNavigationStructure
  def sections
    [
      Node.new(
        name: "First",
        path: "/some-path/first",
        prefix: "/some-path/first",
      ),
      Node.new(
        name: "Second",
        path: "/some-path/second",
        prefix: "/some-path/second",
      ),
    ]
  end
end

RSpec.describe NpqSeparation::Admin::PrimaryNavigationComponent, type: :component do
  let(:current_path) { "/some-path" }

  subject do
    NpqSeparation::Admin::PrimaryNavigationComponent.new(current_path, structure: TestPrimaryNavigationStructure.new)
  end

  it "renders a visually hidden level 2 heading" do
    render_inline(subject)

    expect(rendered_content).to have_css("h2.govuk-visually-hidden", text: "Navigation")
  end

  it "renders an unordered list of navigation nodes" do
    render_inline(subject)

    expect(rendered_content).to have_css(".x-govuk-primary-navigation .govuk-width-container > ul.x-govuk-primary-navigation__list")
  end

  it "lists the right primary navigation items" do
    render_inline(subject)

    TestPrimaryNavigationStructure.new.sections.each do |section|
      selector = %(ul > li.x-govuk-primary-navigation__item a.x-govuk-primary-navigation__link[href="#{section.path}"])

      expect(rendered_content).to have_css(selector, text: section.name)
    end
  end

  context "when the current_path matches a section prefix" do
    let(:current_path) { "/some-path/second" }

    it "only highlights the current section" do
      render_inline(subject)

      selector = %(ul > li.x-govuk-primary-navigation__item--current)

      expect(rendered_content).to have_css(selector, text: "Second")
      expect(rendered_content).to have_css(selector, count: 1)
    end
  end

  describe "#current_section" do
    context "when there is a node with a prefix that matches the current path" do
      let(:current_path) { "/some-path/second" }

      it "returns the matching section" do
        expect(subject.current_section.name).to eql("Second")
      end
    end

    context "when there isn't a node with a prefix that matches the current path" do
      let(:current_path) { "/some/non-existant/path" }

      # this is because we'll probably shorten the actual admin landing page to
      # /admin but actually render /admin/dashboard or whatever
      it "returns the first section by default" do
        expect(subject.current_section.name).to eql("First")
      end
    end
  end

  describe NpqSeparation::Admin::PrimaryNavigationComponent::AdminNavigationStructure do
    describe "#sections" do
      subject { NpqSeparation::Admin::PrimaryNavigationComponent::AdminNavigationStructure.new.sections }

      {
        "Dashboard" => "/npq-separation/admin",
        "Applications" => "/npq-separation/admin/applications",
        "Finance" => "/npq-separation/admin/finance/statements",
        "Schools" => "#",
        "Lead providers" => "#",
        "Settings" => "#",
      }.each_with_index do |(name, href), i|
        it "#{name} with href #{href} is at position #{i + 1}" do
          expect(subject[i].name).to eql(name)
          expect(subject[i].path).to eql(href)
        end
      end
    end
  end
end
