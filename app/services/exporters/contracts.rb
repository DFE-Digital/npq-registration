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
        csv << FIELD_NAMES.map { |field| attribute(field, record) }
      end
    end
  end

private

  attr_reader :cohort

  def attribute(field, record)
    record.attributes[field].tap do |value|
      return 0 if field == "monthly_service_fee" && value.nil?
    end
  end

  def query
    ContractTemplate
      .joins(contracts: [{ statement: :lead_provider }, :course])
      .where(statements: { cohort: })
      .select(
        "lead_providers.name as lead_provider_name",
        "courses.identifier as course_identifier",
        :recruitment_target,
        :per_participant,
        :service_fee_installments,
        :special_course,
        :monthly_service_fee,
      ).distinct
  end
end
