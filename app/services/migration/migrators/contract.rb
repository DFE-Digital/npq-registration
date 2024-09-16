module Migration::Migrators
  class Contract < Base
    SHARED_ATTRIBUTES = %w[
      created_at
      updated_at
      service_fee_percentage
      output_payment_percentage
      per_participant
      number_of_payment_periods
      recruitment_target
      service_fee_installments
      targeted_delivery_funding_per_participant
      monthly_service_fee
      special_course
    ].freeze

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
        %i[course statement]
      end
    end

    def call
      migrate(self.class.ecf_contracts) do |ecf_contract|
        course_id = find_course_id!(identifier: ecf_contract.course_identifier)

        ecf_statements(ecf_contract).find_each do |ecf_statement|
          statement_id = find_statement_id!(ecf_id: ecf_statement.id)

          contract_template = ::ContractTemplate.find_or_initialize_by(ecf_id: ecf_contract.id)
          contract_template.update!(ecf_contract.attributes.slice(*SHARED_ATTRIBUTES))

          contract = ::Contract.find_or_initialize_by(ecf_id: ecf_contract.id)

          contract.update!(contract_template:, statement_id:, course_id:)
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
  end
end
