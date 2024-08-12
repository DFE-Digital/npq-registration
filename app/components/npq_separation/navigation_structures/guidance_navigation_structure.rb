module NpqSeparation
  module NavigationStructures
    class GuidanceNavigationStructure < NpqSeparation::NavigationStructure
      include Rails.application.routes.url_helpers

    private

      def structure
        {
          Node.new(
            name: "Get started",
            href: api_guidance_page_path(page: "get-started"),
            prefix: "/api/guidance/get-started",
          ) => [],
          Node.new(
            name: "Test environments",
            href: api_guidance_page_path(page: "test-environments"),
            prefix: "/api/guidance/test-environments",
          ) => [],
          Node.new(
            name: "What's new",
            href: api_guidance_page_path(page: "release-notes"),
            prefix: "/api/guidance/release-notes",
          ) => [],
        }
      end
    end
  end
end
