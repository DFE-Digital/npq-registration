class SummaryListSection < SitePrism::Section
  sections :rows, SummaryListRowSection, ".govuk-summary-list__row"

  def [](key)
    result = rows.find { |row| row.key == key }

    raise "No row with key '#{key}' could be found. The following row keys were present: #{rows.map(&:key)}" unless result

    result
  end

  def key?(key)
    rows.find { |row| row.key == key }
  end
end
