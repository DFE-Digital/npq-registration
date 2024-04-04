require "rails_helper"

RSpec.describe NpqSeparation::NavigationStructures::GuidanceNavigationStructure, type: :component do
  describe "#primary_structure" do
    subject { NpqSeparation::NavigationStructures::GuidanceNavigationStructure.new.primary_structure }

    {
      "Get Started" => "/api/guidance/get-started",
      "What you can do in the API" => "/api/guidance/what-you-can-do-in-the-api",
      "Definitions" => "/api/guidance/definitions",
      "API latest version" => "/api/guidance/api-latest-version",
      "Test environment" => "/api/guidance/test-environment",
    }.each_with_index do |(name, href), i|
      it "#{name} with href #{href} is at position #{i + 1}" do
        expect(subject[i].name).to eql(name)
        expect(subject[i].href).to eql(href)
      end
    end
  end
end
