class ApplicationPage < SitePrism::Page
  set_url "/admin/applications/{id}"

  section :summary_list, SummaryListSection, ".govuk-summary-list"
end
