module AdminHelper
  def format_cohort(cohort)
    start_year = cohort.start_year
    end_year = start_year.next - 2000

    govuk_link_to("#{start_year}/#{end_year}", "#", no_visited_state: true)
  end
end
