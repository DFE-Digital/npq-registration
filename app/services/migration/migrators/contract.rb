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
        %i[course statement contract_template]
      end
    end

    def call
      migrate(self.class.ecf_contracts) do |ecf_contract|
        course_id = find_course_id!(identifier: ecf_contract.course_identifier)
        contract_template_id = find_contract_template_id!(ecf_id: ecf_contract.id)
        statements_by_id = ::Statement.where(ecf_id: ecf_statements(ecf_contract).pluck(:id)).index_by(&:id)

        statements_by_id.each_key do |statement_id|
          contract = ::Contract.find_or_initialize_by(
            statement_id:,
            course_id:,
          )
          contract.update!(contract_template_id:)
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
