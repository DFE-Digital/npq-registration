module Statements
  class BulkCreator
    class ContractRow
      include ActiveModel::Model
      include ActiveModel::Attributes

      CONTRACT_TEMPLATE_ATTRIBUTES = %w[
        recruitment_target
        per_participant
        special_course
        monthly_service_fee
        service_fee_installments
      ].freeze

      attribute :lead_provider_name, :string
      attribute :course_identifier, :string
      attribute :recruitment_target, :strict_integer
      attribute :per_participant, :strict_decimal, default: nil
      attribute :special_course, :boolean, default: false
      attribute :monthly_service_fee, :strict_decimal, default: nil
      attribute :service_fee_installments, :strict_integer, default: nil

      validates :lead_provider_name, inclusion: { in: -> { LeadProvider.pluck(:name) }, message: "is not recognised" }
      validates :course_identifier, inclusion: { in: -> { Course.pluck(:identifier) }, message: "is not recognised" }
      validates :recruitment_target, numericality: { greater_than: 0 }
      validates :per_participant, numericality: { greater_than: 0 }
      validates :monthly_service_fee, numericality: { greater_than_or_equal_to: 0 }
      validates :service_fee_installments, numericality: { greater_than_or_equal_to: 0 }

      def self.example_csv
        <<~CSV.strip
          lead_provider_name,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course,monthly_service_fee
          "#{LeadProvider.first.name}",#{Course.first.identifier},30,1000,12,false,100
          "#{LeadProvider.first.name}",#{Course.last.identifier},50,400,6,true,200
          "#{LeadProvider.last.name}",#{Course.first.identifier},20,750,9,false,0
        CSV
      end

      def contract_template_attributes
        attributes.slice(*CONTRACT_TEMPLATE_ATTRIBUTES)
      end
    end
  end
end
