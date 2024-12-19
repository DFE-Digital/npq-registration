LeadProvider.find_each do |lead_provider|
  Cohort.find_each do |cohort|
    Course.find_each do |course|
      if cohort.start_year < 2023 && course.npqlpm?
        next # maths starts from 2023
      end

      if cohort.start_year < 2024 && course.senco?
        next # senco starts from 2024
      end

      special_course = course.npqlpm? && cohort.start_year == 2023
      attr = FactoryBot.attributes_for(:contract_template, special_course:)
      contract_template = ContractTemplate.find_or_create_by!(attr)

      Statement.where(lead_provider:, cohort:).find_each do |statement|
        contract = Contract.find_or_initialize_by(
          statement:,
          course:,
        )
        contract.update!(contract_template:)
      end
    end
  end
end
