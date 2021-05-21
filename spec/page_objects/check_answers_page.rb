class CheckAnswersPage < SitePrism::Page
  set_url "/registration/check-answers"

  section :summary_list, SummaryListSection, ".govuk-summary-list"
end
