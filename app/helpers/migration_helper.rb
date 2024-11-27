module MigrationHelper
  def response_comparison_status_tag(different, equal_text: "equal", different_text: "different")
    if different
      govuk_tag(text: different_text.upcase, colour: "red")
    else
      govuk_tag(text: equal_text.upcase, colour: "green")
    end
  end

  def response_comparison_status_code_tag(status_code)
    if status_code <= 299
      govuk_tag(text: status_code, colour: "green")
    elsif status_code <= 399
      govuk_tag(text: status_code, colour: "yellow")
    else
      govuk_tag(text: status_code, colour: "red")
    end
  end

  def response_comparison_performance(comparisons)
    comparisons = Array.wrap(comparisons)
    average_performance = (comparisons.sum(&:ecf_response_time_ms).to_f / comparisons.sum(&:npq_response_time_ms)).round(1)
    formatted_performance = average_performance.to_s.chomp(".0")

    if average_performance < 1
      tag.strong("🐌 #{formatted_performance}x as fast")
    else
      tag.i("🚀 #{formatted_performance}x faster")
    end
  end

  def response_comparison_detail_path(comparisons)
    return unless comparisons.any? { |c| c.different? || c.unexpected? }

    response_comparison_npq_separation_migration_parity_checks_path(comparisons.sample.id)
  end

  def response_comparison_response_duration_human_readable(comparisons, response_time_attribute)
    comparisons = Array.wrap(comparisons)
    duration_ms = (comparisons.sum(&response_time_attribute).to_f / comparisons.size).round(0)

    if duration_ms < 1_000
      "#{duration_ms}ms"
    else
      ActiveSupport::Duration.build(duration_ms / 1_000).inspect
    end
  end

  def response_comparison_page_summary(comparison)
    tag.div(class: "govuk-grid-row") do
      tag.div("Page #{comparison.page}", class: "govuk-grid-column-two-thirds") +
        tag.div(class: "govuk-grid-column-one-third govuk-!-text-align-right") do
          tag.span("ECF: ", class: "govuk-!-font-weight-regular govuk-!-font-size-16") +
            response_comparison_status_code_tag(comparison.ecf_response_status_code) +
            tag.span(" NPQ: ", class: "govuk-!-font-weight-regular govuk-!-font-size-16") +
            response_comparison_status_code_tag(comparison.npq_response_status_code)
        end
    end
  end

  def contains_duplicate_ids?(comparisons, attribute)
    ids = comparisons.map(&attribute).flatten
    ids.size != ids.uniq.size
  end
end
