module OneOff
  class CreateOrUpdateStatements
    YEAR = {
      "22" => 2022,
      "23" => 2023,
      "24" => 2024,
      "25" => 2025,
    }.freeze

    MONTH = {
      "Jan" => 1,
      "Feb" => 2,
      "Mar" => 3,
      "Apr" => 4,
      "May" => 5,
      "Jun" => 6,
      "Jul" => 7,
      "Aug" => 8,
      "Sep" => 9,
      "Oct" => 10,
      "Nov" => 11,
      "Dec" => 12,
    }.freeze
    TEMPLATE_STATEMENT_YEAR = 2025
    TEMPLATE_STATEMENT_MONTH = 1
    def call(cohort_year:, csv_path:)
      csv_file = CSV.read(csv_path, headers: true)

      ActiveRecord::Base.transaction do
        @cohort = Cohort.find_by!(start_year: cohort_year)

        csv_file.each do |row|
          # NIoT has no 2021 cohort so its excluded
          LeadProvider.where.not(name: "National Institute of Teaching").find_each do |lead_provider|
            year, month = parse_date(row["name"])
            statements = Statement.where(year:, month:, cohort: @cohort, lead_provider: lead_provider)

            statement = statements.first
            if statement
              statement.output_fee = output_fee(row["output_fee"])
              statement.deadline_date = row["deadline_date"]
              statement.payment_date = row["payment_date"]

              if statement.changed?
                FinancialChangeLog.log!(description: FinancialChangeLog::ONE_OFF_2520, data: { updated_statement_id: statement.id, changes: statement.changes })
                statement.save!
              end
            else
              create_statement(row, lead_provider:)
            end
          end
        end
      end
    end

    def create_statement(row, lead_provider:)
      template_statement = Statement.find_by!(year: TEMPLATE_STATEMENT_YEAR, month: TEMPLATE_STATEMENT_MONTH, cohort: @cohort, lead_provider:)
      year, month = parse_date(row["name"])
      statement = Statement.create! do |s|
        s.month = month
        s.year = year
        s.deadline_date = row["deadline_date"]
        s.payment_date = row["payment_date"]
        s.output_fee = output_fee(row["output_fee"])
        s.cohort = @cohort
        s.lead_provider = lead_provider
      end

      template_statement.contracts.each do |contract|
        contract = statement.contracts.create!(course_id: contract.course_id, contract_template_id: contract.contract_template_id)
        FinancialChangeLog.log!(description: FinancialChangeLog::ONE_OFF_2326, data: { created_statement_id: statement.id, created_contract_id: contract.id })
      end
    end

    def parse_date(date)
      date_array = date.split("-")
      year = YEAR[date_array.first]
      raise ArgumentError if year.nil?

      month = MONTH[date_array.last]
      raise ArgumentError if month.nil?

      [year, month]
    end

    def output_fee(value)
      { "TRUE" => true, "FALSE" => false }.fetch(value)
    end
  end
end
