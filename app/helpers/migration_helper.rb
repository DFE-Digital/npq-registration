module MigrationHelper
  def migration_result_attributes(result, key)
    result.attribute_names.filter { |attribute_name| attribute_name.include?(key) }
  end

  def migration_result_summary_row(result, key, attribute)
    value = result.send(attribute)
    total = result.send("#{key}_count")
    percentage = number_to_percentage((value.to_f / total) * 100, precision: 0)
    tag_color = migration_result_percentage_color(key, attribute, value)

    content_tag(:div, class: "govuk-summary-list__row") do
      content_tag(:dt, attribute.gsub(key.pluralize, "").humanize, class: "govuk-summary-list__key govuk-!-width-one-half") +
        content_tag(:dd, number_with_delimiter(value), class: "govuk-summary-list__value") +
        content_tag(:dd, class: "govuk-summary-list__actions") do
          content_tag(:strong, percentage, class: "govuk-tag govuk-tag--#{tag_color}") if tag_color
        end
    end
  end

  def migration_result_percentage_color(key, attribute, value)
    return if value.zero?
    return :green if attribute.include?("matched")

    :red if attribute != "#{key}_count"
  end

  def migration_result_duration_in_words(result)
    duration_in_seconds = (result.completed_at - result.created_at).to_i
    ActiveSupport::Duration.build(duration_in_seconds).inspect
  end
end
