module Guidance
  class GuidancePage
    def initialize(path, content: nil)
      @path = path
      @content = content
    end

    def sections
      headings = page_contents.scan(/^##\s(.*)$/).map(&:first)

      headings.index_by { |heading| "##{heading.underscore.parameterize.gsub("_", "-")}" }
    end

    def template
      "api/guidance/#{path}"
    end

    def index_page?
      false
    end

  private

    attr_reader :path

    def page_contents
      @content || File.read(Rails.root.join("app", "views", "#{template}.md"))
    end
  end
end
