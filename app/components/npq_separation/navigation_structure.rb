module NpqSeparation
  class NavigationStructure
    class SectionNotFoundError < StandardError; end

    include Rails.application.routes.url_helpers

    # A Node is an entry in a navigation list, it contains:
    #
    # * name    - the hyperlink text which appears in the list
    # * href    - the hyperlink href
    # * prefix  - the beginning of a path which will trigger the node to be marked
    #            'current' and highlighted in the nav
    # * current - a boolean value where the result of the prefix match is stored,
    #             this isn't done on the fly so we can pass the value along from
    #             the primary nav to the sub nav
    # * nodes   - a list of nodes that sit under this one in the structure
    Node = Struct.new(:name, :href, :prefix, :current, :nodes, keyword_init: true) do
      def to_service_navigation_item
        { text: name, href: href, active_when: prefix }
      end
    end

    def primary_structure
      structure.keys
    end

    def sub_structure(path, default_to_first_section: false)
      primary_section = primary_structure.find { |section| path.start_with?(section.prefix) }

      if primary_section.nil?
        fail(SectionNotFoundError) unless default_to_first_section

        primary_section = primary_structure.first
      end

      structure.fetch(primary_section)
    end

    def service_navigation_items
      primary_structure.map(&:to_service_navigation_item)
    end

  private

    def structure = fail(NotImplementedError)
  end
end
