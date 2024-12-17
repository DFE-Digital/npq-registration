LeadProvider.find_each do |lead_provider|
  Cohort.find_each do |cohort|
    date    = cohort.registration_start_date.to_date
    periods = ((date.end_of_month + 1.day)...(date + 2.years)).map { [_1.year, _1.month] }.uniq

    periods.each.with_index(1) do |(year, month), i|
      final_statement  = i == periods.count
      output_fee       = final_statement || month.in?([3, 6, 9, 12])
      deadline_date    = Date.new(year, month, 1) - 6.days
      payment_date     = deadline_date + 1.month
      reconcile_amount = 0 # random manual adjustment is confusing outside of tests

      FactoryBot.create(:statement, lead_provider:, cohort:, year:, month:, output_fee:, deadline_date:, payment_date:, reconcile_amount:)
    end
  end
end
