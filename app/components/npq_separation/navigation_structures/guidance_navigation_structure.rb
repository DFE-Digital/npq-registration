module NpqSeparation
  module NavigationStructures
    class GuidanceNavigationStructure < NpqSeparation::NavigationStructure
      include Rails.application.routes.url_helpers

    private

      def structure
        {
          Node.new(
            name: "Get Started",
            href: api_guidance_page_path(page: "get-started"),
            prefix: "/api/guidance/get-started",
          ) => [],
          Node.new(
            name: "What you can do in the API",
            href: api_guidance_page_path(page: "what-you-can-do-in-the-api"),
            prefix: "/api/guidance/what-you-can-do-in-the-api",
          ) => [],
          Node.new(
            name: "Definitions",
            href: api_guidance_page_path(page: "definitions"),
            prefix: "/api/guidance/definitions",
          ) => [],
          Node.new(
            name: "API latest version",
            href: api_guidance_page_path(page: "api-latest-version"),
            prefix: "/api/guidance/api-latest-version",
          ) => [],
          Node.new(
            name: "Test environment",
            href: api_guidance_page_path(page: "test-environment"),
            prefix: "/api/guidance/test-environment",
          ) => [],
        }
      end
    end
  end
end