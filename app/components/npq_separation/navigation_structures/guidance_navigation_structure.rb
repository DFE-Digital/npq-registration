module NpqSeparation
  module NavigationStructures
    class GuidanceNavigationStructure < NpqSeparation::NavigationStructure
      include Rails.application.routes.url_helpers

    private

      def structure
        {
          Node.new(
            name: "Get started",
            href: api_guidance_page_path(page: "get_started"),
            prefix: "/api/guidance/get-started",
          ) => [],
          Node.new(
            name: "API documentation latest version",
            href: api_guidance_page_path(page: "what-you-can-do-in-the-api"),
            prefix: "/api/guidance/what-you-can-do-in-the-api",
          ) => [],
          Node.new(
            name: "Test environments",
            href: api_guidance_page_path(page: "test_environment"),
            prefix: "/api/guidance/test_environments",
          ) => [],
          Node.new(
            name: "What's new",
            href: api_guidance_page_path(page: "release-notes"),
            prefix: "/api/guidance/test_environment",
          ) => [],
        }
      end
    end
  end
end
