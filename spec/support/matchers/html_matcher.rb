RSpec::Matchers.define :have_html do |expected_html, js: true|
  match do
    string = js ? expected_html.gsub("<br>", "\n") : expected_html # a quirk of the capybara vs racktest rendering
    expected_string = ActionController::Base.helpers.strip_tags(string)
    expect(page).to have_text(expected_string)
  end

  failure_message do |actual|
    "expected #{actual.body} to include #{expected_html}"
  end
end
