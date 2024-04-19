module AdminHelper
  def format_cohort(cohort)
    start_year = cohort.start_year
    end_year = start_year.next - 2000

    "#{start_year}/#{end_year}"
  end

  def format_address(school)
    keys = %i[address_1 address_2 address_3 town county postcode]
    parts = keys.map { |k| school[k] }.compact_blank

    return if parts.blank?

    safe_join(parts, tag.br)
  end

  def admin_navigation_structure
    @admin_navigation_structure ||= NpqSeparation::NavigationStructures::AdminNavigationStructure.new
  end
end
