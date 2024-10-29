module MigrationHelper
  def migration_started_at(data_migrations)
    # When a migration is first kicked off all data_migration records are briefly
    # pending (with a `started_at` of `nil`) until a worker picks up the job.
    # We use the current time as the start time in this case.
    data_migrations.map(&:started_at).compact.min || Time.zone.now
  end

  def migration_completed_at(data_migrations)
    data_migrations.map(&:completed_at).compact.max
  end

  def migration_duration_in_words(data_migrations)
    duration_in_seconds = (migration_completed_at(data_migrations) - migration_started_at(data_migrations)).to_i
    ActiveSupport::Duration.build(duration_in_seconds).inspect
  end

  def data_migration_status_tag(data_migration)
    return govuk_tag(text: "Completed", colour: "green") if data_migration.complete?
    return govuk_tag(text: "In progress - #{data_migration.percentage_migrated}%", colour: "yellow") if data_migration.in_progress?
    return govuk_tag(text: "Queued", colour: "blue") if data_migration.queued?

    govuk_tag(text: "Pending", colour: "grey")
  end

  def data_migration_failure_count_tag(data_migrations)
    failure_count = data_migrations.sum(&:failure_count)

    return if failure_count.zero?

    govuk_tag(text: number_with_delimiter(failure_count), colour: "red")
  end

  def data_migration_total_count_tag(data_migrations)
    total_count = data_migrations.sum(&:total_count)

    return unless total_count&.positive?

    govuk_tag(text: number_with_delimiter(total_count), colour: "blue")
  end

  def data_migration_percentage_migrated_successfully_tag(data_migrations)
    avg_percentage = data_migrations.sum(&:percentage_migrated_successfully).fdiv(data_migrations.count)

    colour = if avg_percentage < 80
               "red"
             elsif avg_percentage < 100
               "yellow"
             else
               "green"
             end

    govuk_tag(text: "#{avg_percentage.floor}%", colour:)
  end

  def data_migration_download_failures_report_link(data_migrations)
    failure_count = data_migrations.sum(&:failure_count)

    return unless failure_count.positive?

    govuk_link_to("Failures report", download_report_npq_separation_migration_migrations_path(data_migrations.sample.model))
  end

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
