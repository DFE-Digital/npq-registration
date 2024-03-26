module AdminHelper
  def format_cohort(cohort)
    start_year = cohort.start_year
    end_year = start_year.next - 2000

    "#{start_year}/#{end_year}"
  end

  def admin_navigation_structure
    @admin_navigation_structure ||= NpqSeparation::NavigationStructures::AdminNavigationStructure.new
  end
end
