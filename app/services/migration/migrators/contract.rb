module Migration::Migrators
  class Contract < Base
    class << self
      def record_count
        ecf_contracts.count
      end

      def model
        :contract
      end

      def ecf_contracts
        Migration::Ecf::NpqContract.includes(:cohort, npq_lead_provider: [:cpd_lead_provider])
      end

      def dependencies
        %i[cohort lead_provider course statement]
      end
    end

    def call
      migrate(self.class.ecf_contracts) do |ecf_contract|
        course = courses_by_identifier[ecf_contract.course_identifier]

        ecf_statements(ecf_contract).find_each do |ecf_statement|
          statement = ::Statement.find_by!(ecf_id: ecf_statement.id)

          contract_template = ::ContractTemplate.find_or_initialize_by(ecf_id: ecf_contract.id)
          contract_template.update!(
            created_at: ecf_contract.created_at,
            updated_at: ecf_contract.updated_at,

            service_fee_percentage: ecf_contract.service_fee_percentage,
            output_payment_percentage: ecf_contract.output_payment_percentage,
            per_participant: ecf_contract.per_participant,
            number_of_payment_periods: ecf_contract.number_of_payment_periods,
            recruitment_target: ecf_contract.recruitment_target,
            service_fee_installments: ecf_contract.service_fee_installments,
            targeted_delivery_funding_per_participant: ecf_contract.targeted_delivery_funding_per_participant,
            monthly_service_fee: ecf_contract.monthly_service_fee,
            special_course: ecf_contract.special_course,
          )

          contract = ::Contract.find_or_initialize_by(
            statement:,
            course:,
          )
          contract.update!(contract_template:)
        end
      end
    end

    def ecf_statements(ecf_contract)
      Migration::Ecf::Finance::Statement.where(
        cpd_lead_provider: ecf_contract.npq_lead_provider.cpd_lead_provider,
        cohort: ecf_contract.cohort,
        contract_version: ecf_contract.version,
      )
    end

  private

    def courses_by_identifier
      @courses_by_identifier ||= ::Course.all.index_by(&:identifier)
    end
  end
end
