class GuidancePage
  def initialize(path, content: nil)
    @path = path
    @content = content
  end

  def sub_headings
    headings = page_contents.scan(/^##\s(.*)$/).map(&:first)

    headings.index_by { |heading| "##{heading.underscore.parameterize.gsub("_", "-")}" }
  end

  def template
    "api/guidance/#{path}"
  end

  def self.index_page
    GuidanceIndexPage.new
  end

  def index_page?
    false
  end

private

  attr_reader :path

  def page_contents
    @content || File.read(Rails.root.join("app", "views", "#{template}.md"))
  end

  class GuidanceIndexPage
    def sub_headings
      {}
    end

    def index_page?
      true
    end
  end
end
