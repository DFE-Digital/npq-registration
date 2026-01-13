# statements representative of production
[
  {
    cohort_identifier: "2021a",
    start: Date.new(2024, 7),
    end: Date.new(2027, 4),
    output_fee_statements: [Date.new(2024, 12), Date.new(2025, 7), Date.new(2026, 2), Date.new(2026, 3), Date.new(2026, 9), Date.new(2027, 3)],
  },
  {
    cohort_identifier: "2022a",
    start: Date.new(2022, 12),
    end: Date.new(2026, 9),
    output_fee_statements: [Date.new(2022, 12), Date.new(2023, 3), Date.new(2023, 7), Date.new(2023, 11), Date.new(2024, 2), Date.new(2024, 3), Date.new(2024, 6), Date.new(2024, 9), Date.new(2025, 3), Date.new(2025, 6), Date.new(2025, 9), Date.new(2026, 1), Date.new(2026, 5), Date.new(2026, 9)],
  },
  {
    cohort_identifier: "2023a",
    start: Date.new(2023, 3),
    end: Date.new(2026, 12),
    output_fee_statements: [Date.new(2023, 3), Date.new(2023, 12), Date.new(2024, 3), Date.new(2024, 7), Date.new(2024, 11), Date.new(2025, 2), Date.new(2025, 3), Date.new(2026, 1), Date.new(2026, 5), Date.new(2026, 9)],
  },
  {
    cohort_identifier: "2024a",
    start: Date.new(2024, 7),
    end: Date.new(2027, 4),
    output_fee_statements: [Date.new(2024, 12), Date.new(2025, 7), Date.new(2026, 2), Date.new(2026, 3), Date.new(2026, 9), Date.new(2027, 3)],
  },
  {
    cohort_identifier: "2025a",
    start: Date.new(2025, 1),
    end: Date.new(2027, 7),
    output_fee_statements: [Date.new(2025, 6), Date.new(2026, 1), Date.new(2026, 7), Date.new(2026, 8), Date.new(2027, 2)],
  },
  {
    cohort_identifier: "2025b",
    start: Date.new(2025, 12),
    end: Date.new(2026, 8),
    output_fee_statements: [Date.new(2026, 2)],
  },
].each do |values|
  cohort = Cohort.find_by(identifier: values[:cohort_identifier])
  start_date = Date.new(values[:start].year, values[:start].month, 1)
  end_date = Date.new(values[:end].year, values[:end].month, 1)
  periods = (start_date..end_date).map { |date| [date.year, date.month] }.uniq

  periods.each do |year, month|
    LeadProvider.find_each do |lead_provider|
      output_fee = values[:output_fee_statements].include?(Date.new(year, month))
      deadline_date = Date.new(year, month, 1) - 6.days
      payment_date = deadline_date + 1.month
      reconcile_amount = 0 # random manual adjustment is confusing outside of tests
      FactoryBot.create(:statement, lead_provider:, cohort:, year:, month:, output_fee:, deadline_date:, payment_date:, reconcile_amount:)
    end
  end
end
