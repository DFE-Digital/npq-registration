RSpec::Matchers.define :have_html do |attribute, js: true|
  match do
    string = attribute.gsub("<br>", "\n") if js # a quirk of the capybara vs racktest rendering
    expected_string = ActionController::Base.helpers.strip_tags(string)
    expect(page).to have_text(expected_string)
  end

  failure_message do |actual|
    "expected #{actual.body} to include #{attribute}"
  end
end
