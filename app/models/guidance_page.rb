class GuidancePage
  def initialize(path, content: nil)
    @path = path
    @content = content
  end

  def sub_headings
    page_contents.scan(/^##\s(.*)$/).map(&:first)
  end

  def template
    "api/guidance/#{path}"
  end

private

  attr_reader :path

  def page_contents
    @content || File.read(Rails.root.join("app", "views", "#{template}.md"))
  end
end
