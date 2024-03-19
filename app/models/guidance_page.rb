class GuidancePage
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def template
    "api/guidance/#{path}"
  end
end
