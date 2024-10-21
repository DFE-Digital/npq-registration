module Migration::Migrators
  class ContractTemplate < Base
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
        :contract_template
      end

      def ecf_contracts
        Migration::Ecf::NpqContract.includes(:cohort, npq_lead_provider: [:cpd_lead_provider])
      end
    end

    def call
      migrate(self.class.ecf_contracts) do |ecf_contract|
        contract_template = ::ContractTemplate.find_or_initialize_by(ecf_id: ecf_contract.id)
        contract_template.update!(ecf_contract.attributes.slice(*SHARED_ATTRIBUTES))
      end
    end
  end
end
