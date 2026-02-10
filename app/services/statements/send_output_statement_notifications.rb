class Statements::SendOutputStatementNotifications
  def call
    contracts_team_email_address = ENV["CONTRACTS_TEAM_EMAIL_ADDRESS"]

    return unless contracts_team_email_address

    UpcomingOutputStatementsMailer.email_upcoming_output_statements_mail(
      to: contracts_team_email_address,
      this_months_statements:,
      next_months_statements:,
    ).deliver_now
  end

private

  def this_months_statements
    statements_bullet_points(Time.zone.today)
  end

  def next_months_statements
    statements_bullet_points(Time.zone.today + 1.month)
  end

  def statements_bullet_points(date)
    statements = Statement
      .with_output_fee
      .where(deadline_date: date.beginning_of_month..date.end_of_month)
      .select(:deadline_date, :cohort_id, :year, :month)
      .distinct
      .order(:deadline_date, :cohort_id, :year, :month)

    return "none" if statements.empty?

    statements.map { |statement|
      "* deadline date: #{statement.deadline_date.to_fs(:govuk)}, " \
        "cohort: #{statement.cohort.identifier}, " \
        "statement: #{Date.new(statement.year, statement.month).to_fs(:govuk_approx)}"
    }.join("\n")
  end
end
