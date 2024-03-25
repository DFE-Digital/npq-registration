module NpqSeparation
  module NavigationStructures
    class GuidanceNavigationStructure < NpqSeparation::NavigationStructure
      include Rails.application.routes.url_helpers

    private

      # Returns a hash where the keys are primary nodes and the values are
      # sub nodes nested with the 'nodes: key'
      def structure
        {
          Node.new(
            name: "Get Started",
            href: api_guidance_page_path(page: "get-started"),
            prefix: "/api/guidance/get-started",
          ) => GuidancePage.new("get-started").sub_headings.map do |href, text|
            Node.new(
              name: text,
              href: "/api/guidance/get-started#{href}",
            )
          end,
          Node.new(
            name: "What you can do in the API",
            href: api_guidance_page_path(page: "what-you-can-do-in-the-api"),
            prefix: "/api/guidance/what-you-can-do-in-the-api",
          ) => GuidancePage.new("what-you-can-do-in-the-api").sub_headings.map do |href, text|
            Node.new(
              name: text,
              href: "/api/guidance/what-you-can-do-in-the-api#{href}",
            )
          end,
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
