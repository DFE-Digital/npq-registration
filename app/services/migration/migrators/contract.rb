module Migration::Migrators
  class Contract < Base
    INFRA_WORKER_COUNT = 1

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

      def number_of_workers
        return 1 if record_count > 1000

        super
      end

      def records_per_worker
        return record_count if record_count > 1000

        super
      end
    end

    def call
      migrate(self.class.ecf_contracts) do |ecf_contract|
        ApplicationRecord.transaction do
          course_id = find_course_id!(identifier: ecf_contract.course_identifier)

          contract_template = ::ContractTemplate.find_or_initialize_by(ecf_id: ecf_contract.id)
          unless contract_template.persisted?
            contract_template.update!(ecf_contract.attributes.slice(*SHARED_ATTRIBUTES))
          end

          statements_by_id = ::Statement.where(ecf_id: ecf_statements(ecf_contract).pluck(:id)).index_by(&:id)
          statements_by_id.each_key do |statement_id|
            contract = ::Contract.find_by(
              statement_id:,
              course_id:,
            )

            next if contract.present?

            ::Contract.create!(
              statement_id:,
              course_id:,
              contract_template:,
            )
          end
        end
      end
    end

    def ecf_statements(ecf_contract)
      @ecf_statements ||= {}
      @ecf_statements["#{ecf_contract.npq_lead_provider.cpd_lead_provider},#{ecf_contract.cohort},#{ecf_contract.version}"] ||= Migration::Ecf::Finance::Statement.where(
        cpd_lead_provider: ecf_contract.npq_lead_provider.cpd_lead_provider,
        cohort: ecf_contract.cohort,
        contract_version: ecf_contract.version,
      )
    end
  end
end
