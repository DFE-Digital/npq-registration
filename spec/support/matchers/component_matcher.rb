RSpec::Matchers.define :have_component do |expected_component|
  match do |page|
    actual_html(page).include? expected_html(expected_component)
  end

  failure_message do |page|
    [
      "expected to find",
      expected_html(expected_component),
      "within page content",
      actual_html(page),
    ].join("\n\n")
  end

  def expected_html(component)
    CGI.unescapeHTML render_component(component)
  end

  def actual_html(page)
    page.is_a?(ActiveSupport::SafeBuffer) ? page : page.html
  end

  def render_component(component)
    ApplicationController.renderer.render(component, layout: false)
  end
end
