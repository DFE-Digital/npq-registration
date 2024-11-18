RSpec::Matchers.define :have_component do |expected_component|
  match do |page|
    page.html.include?(ApplicationController.new.view_context.render(expected_component))
  end
end
