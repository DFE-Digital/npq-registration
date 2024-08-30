def number_of_payment_periods_for(course:)
  case course.course_group.name
  when "specialist"
    3
  when "leadership", "support", "ehco"
    4
  else
    raise ArgumentError, "Invalid course group"
  end
end

def service_fee_percentage_for(course:)
  case course.course_group.name
  when "support", "ehco"
    0
  else
    40
  end
end

def output_payment_percentage_for(course:)
  case course.course_group.name
  when "support", "ehco"
    100
  else
    60
  end
end

[
  "db/seeds/data/contracts/2021.csv",
  "db/seeds/data/contracts/2022.csv",
  "db/seeds/data/contracts/2023.csv",
  "db/seeds/data/contracts/2024.csv",
].each do |file_path|
  data = CSV.read(Rails.root.join(file_path), headers: true)
  data.each do |row|
    lead_provider = LeadProvider.find_by!(name: row["provider_name"])
    cohort = Cohort.find_by!(start_year: row["cohort_year"])
    course = Course.find_by!(identifier: row["course_identifier"])

    Statement.where(lead_provider:, cohort:).find_each do |statement|
      contract = Contract.find_or_initialize_by(
        statement:,
        course:,
      )

      contract_template = ContractTemplate.find_or_create_by!(
        monthly_service_fee: row["monthly_service_fee"],
        recruitment_target: row["recruitment_target"],
        per_participant: row["per_participant"],
        service_fee_installments: row["service_fee_installments"],
        number_of_payment_periods: number_of_payment_periods_for(course:),
        service_fee_percentage: service_fee_percentage_for(course:),
        output_payment_percentage: output_payment_percentage_for(course:),
        special_course: (row["special_course"].to_s.upcase == "TRUE"),
      )

      contract.update!(contract_template:)
    end
  end
end
