RSpec::Matchers.define :have_component do |expected_component|
  match do |page|
    expected_html = ApplicationController.renderer.render(expected_component, layout: false)

    if page.is_a? ActiveSupport::SafeBuffer
      page.include?(expected_html)
    else
      page.html.include?(expected_html)
    end
  end
end
