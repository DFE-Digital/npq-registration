LeadProvider.find_each do |lead_provider|
  Cohort.find_each do |cohort|
    FactoryBot.create_list(:statement, 10, lead_provider:, cohort:, year: cohort.start_year, state: Statement.state_machine.states.map(&:name).sample)
  end
end
