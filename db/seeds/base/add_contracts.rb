LeadProvider.find_each do |lead_provider|
  Cohort.find_each do |cohort|
    Course.find_each do |course|
      Statement.where(lead_provider:, cohort:).find_each do |statement|
        FactoryBot.create(:contract, course.identifier.underscore, statement:)
      end
    end
  end
end
