module Statements
  class BulkCreator
    include ActiveModel::Validations

    attr_reader :cohort, :statements_csv_id, :contracts_csv_id

    validates :statements_csv_id, presence: true
    validates :contracts_csv_id, presence: true
    validate :validate_statements_csv
    validate :validate_contracts_csv
    validate :validate_statement_uniqueness

    def initialize(cohort:, statements_csv_id:, contracts_csv_id:)
      @cohort = cohort
      @statements_csv_id = statements_csv_id
      @contracts_csv_id = contracts_csv_id
    end

    def call(dry_run: true)
      return unless valid?

      ApplicationRecord.transaction do
        @result = create_statements
        raise ActiveRecord::Rollback if dry_run
      end

      @result
    end

  private

    def validate_statements_csv
      return if statements_csv_id.blank?

      statement_parser.errors.each { errors.add :statements_csv, _1 }
    end

    def validate_contracts_csv
      return if contracts_csv_id.blank?

      contract_parser.errors.each { errors.add :contracts_csv, _1 }
    end

    def validate_statement_uniqueness
      return if statements_csv_id.blank? || contracts_csv_id.blank?

      lead_providers = contract_parser.valid_rows
                                      .uniq(&:lead_provider_name)
                                      .map { lead_provider_for _1 }

      statement_parser.valid_rows.each.with_index(2) do |statement, line_number|
        lead_providers.each do |lead_provider|
          next unless Statement.exists?(cohort:, lead_provider:, year: statement.year, month: statement.month)

          errors.add(:statements_csv, "Statement already exists on line #{line_number}")
          break
        end
      end
    end

    def create_statements
      cache = {}

      statement_parser.each do |statement_row|
        contract_parser.each do |contract_row|
          statement_attributes = statement_attributes_for(statement_row, contract_row)
          contract_attributes = contract_attributes_for(contract_row)

          cache[statement_attributes] ||= Statement.create!(statement_attributes)
          cache[statement_attributes].contracts.create!(contract_attributes)
        end
      end

      cache.values
    end

    def statement_attributes_for(statement_row, contract_row)
      lead_provider = lead_provider_for(contract_row)

      statement_row.attributes.merge(cohort:, lead_provider:, reconcile_amount: 0)
    end

    def contract_attributes_for(contract_row)
      course = course_for(contract_row)
      contract_template = contract_template_for(contract_row, course.course_group)

      { contract_template:, course: }
    end

    def lead_provider_for(contract_row)
      name = contract_row.lead_provider_name

      @lead_provider_cache ||= {}
      @lead_provider_cache[name] ||= LeadProvider.find_by!(name:)
    end

    def course_for(contract_row)
      @course_cache ||= {}

      identifier = contract_row.course_identifier
      @course_cache[identifier] ||= Course.find_by!(identifier:)
    end

    def contract_template_for(contract_row, course_group)
      attributes = contract_row.contract_template_attributes
                               .merge(contract_template_attributes_for(course_group))

      @contract_template_cache ||= {}
      @contract_template_cache[attributes] ||= ContractTemplate.find_or_create_by!(attributes)
    end

    def contract_template_attributes_for(course_group)
      case course_group.name
      when "leadership"
        {
          number_of_payment_periods: 4,
          service_fee_percentage: 40,
          output_payment_percentage: 60,
        }
      when "specialist"
        {
          number_of_payment_periods: 3,
          service_fee_percentage: 40,
          output_payment_percentage: 60,
        }
      when "support"
        {
          number_of_payment_periods: 4,
          service_fee_percentage: 0,
          output_payment_percentage: 100,
        }
      when "ehco"
        {
          number_of_payment_periods: 4,
          service_fee_percentage: 0,
          output_payment_percentage: 100,
        }
      else
        raise ArgumentError, "Invalid course group name"
      end
    end

    def statement_parser
      @statement_parser ||= parse_blob(statements_csv_id, StatementRow)
    end

    def contract_parser
      @contract_parser ||= parse_blob(contracts_csv_id, ContractRow)
    end

    def parse_blob(signed_id, row_class)
      blob = ActiveStorage::Blob.find_signed!(signed_id)
      blob.open { |file| Parser.read(file, row_class) }
    end
  end
end
