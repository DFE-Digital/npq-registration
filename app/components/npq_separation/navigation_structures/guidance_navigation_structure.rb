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
            href: "#",
            prefix: "/api/guidance/what-you-can-do-in-the-api",
          ) => [],
          Node.new(
            name: "Definitions",
            href: "#",
            prefix: "/api/guidance/definitions",
          ) => [],
          Node.new(
            name: "API latest version",
            href: "#",
            prefix: "/api/guidance/api-latest-version",
          ) => [],
          Node.new(
            name: "Test environment",
            href: "#",
            prefix: "/api/guidance/test-environment",
          ) => [],
        }
      end
    end
  end
end
