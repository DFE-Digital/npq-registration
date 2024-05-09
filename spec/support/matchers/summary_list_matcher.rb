RSpec::Matchers.define :have_summary_item do |expected_title, expected_value|
  match do |summary_list|
    summary_list
      .find(".govuk-summary-list__key", text: expected_title, exact_text: true)
      .sibling(".govuk-summary-list__value", text: expected_value.to_s)
  end
end
