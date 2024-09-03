LeadProvider.find_each do |lead_provider|
  Cohort.find_each do |cohort|
    Course.find_each do |course|
      if cohort.start_year < 2023 && (course.senco? || course.npqlpm?)
        next # senco and math starts from 2023
      end

      special_course = course.senco? || course.npqlpm?

      Statement.where(lead_provider:, cohort:).find_each do |statement|
        contract = Contract.find_or_initialize_by(
          statement:,
          course:,
        )
        attr = FactoryBot.attributes_for(:contract_template, special_course:)
        contract_template = ContractTemplate.find_or_create_by!(attr)
        contract.update!(contract_template:)
      end
    end
  end
end
