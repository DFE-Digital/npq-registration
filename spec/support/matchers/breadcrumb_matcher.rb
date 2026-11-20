RSpec::Matchers.define :have_current_breadcrumb do |expected_text|
  match do |page|
    page.has_css?(".govuk-breadcrumbs__list-item[aria-current='page']", exact_text: expected_text)
  end

  match_when_negated do |page|
    page.has_no_css?(".govuk-breadcrumbs__list-item[aria-current='page']", exact_text: expected_text)
  end
end

RSpec::Matchers.define :have_breadcrumb_link do |expected_text, href: nil|
  match do |page|
    page.has_link?(expected_text, class: "govuk-breadcrumbs__link", href:, exact_text: true)
  end

  match_when_negated do |page|
    page.has_no_link?(expected_text, class: "govuk-breadcrumbs__link", href:, exact_text: true)
  end
end
