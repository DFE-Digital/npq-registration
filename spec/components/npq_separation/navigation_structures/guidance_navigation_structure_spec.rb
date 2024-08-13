require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::GuidanceNavigationStructure, type: :component do
  describe "#primary_structure" do
    subject { NpqSeparation::NavigationStructures::GuidanceNavigationStructure.new.primary_structure }

    {
      "Get started" => "/api/guidance/get-started",
      "Test environments" => "/api/guidance/test-environments",
      "What's new" => "/api/guidance/release-notes",
    }.each_with_index do |(name, href), i|
      it "#{name} with href #{href} is at position #{i + 1}" do
        expect(subject[i].name).to eql(name)
        expect(subject[i].href).to eql(href)
      end
    end
  end
end
