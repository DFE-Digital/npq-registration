class Exporters::Contracts
  FIELD_NAMES =
    %w[
      lead_provider_name
      course_identifier
      recruitment_target
      per_participant
      service_fee_installments
      special_course
      monthly_service_fee
    ].freeze
  # technically service_fee_installments and monthly_service_fee are not used, but have been uploaded previously
  # monthly_service_fee, output_payment_percentage, number_of_payment_periods, service_fee_installments and service_fee_percentage will be removed in CPDNPQ-2927

  def initialize(cohort:)
    @cohort = cohort
  end

  def call
    CSV.generate(encoding: "utf-8") do |csv|
      csv << FIELD_NAMES
      query.each do |record|
        csv << FIELD_NAMES.map { |field| record.attributes[field] }
      end
    end
  end

private

  attr_reader :cohort

  def query
    ContractTemplate
      .joins(contracts: [{ statement: :lead_provider }, :course])
      .where(statements: { cohort:, output_fee: true })
      .where("MAKE_DATE(statements.year, statements.month, 1) <= DATE_TRUNC('month', CURRENT_DATE)")
      .order(:lead_provider_name, :course_identifier, "statements.year desc", "statements.month desc")
      .select(
        "DISTINCT ON (lead_provider_name, course_identifier) lead_providers.name AS lead_provider_name",
        "courses.identifier AS course_identifier",
        :recruitment_target,
        :per_participant,
        :service_fee_installments,
        :special_course,
        "COALESCE(monthly_service_fee, 0.0) AS monthly_service_fee",
      )
  end
end
