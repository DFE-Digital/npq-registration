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
          Node.new(
            name: "How-to guides",
            href: api_guidance_page_path(page: "/", anchor: "how-to-guides"),
            prefix: "/api/guidance//#how-to-guides",
          ) => [],
          Node.new(
            name: "Process diagrams",
            href: api_guidance_page_path(page: "/", anchor: "process-diagrams"),
            prefix: "/api/guidance/participant-training-journey-diagrams",
          ) => [],
        }
      end
    end
  end
end
