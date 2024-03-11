class GuidancePage
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def sub_headings
    page_contents.scan(/##\s(.*)$/).map(&:first)
  end

  def template
    "api/guidance/#{path}"
  end

private

  def page_contents
    File.read("#{Rails.root.join("app/views/#{template}")}.md")
  end
end
