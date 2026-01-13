module API
  class DeclarationSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "participant-declaration" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id
      field(:participant_id) { |declaration| declaration.user.ecf_id }
      field(:declaration_type)
      field(:course_identifier)
      field(:declaration_date)
      field(:state) { |declaration| declaration.state.dasherize }
      field(:has_passed) do |declaration|
        declaration
          .participant_outcomes
          .max_by(&:created_at)
          &.has_passed?
      end

      field(:delivery_partner_id) { |declaration| declaration.delivery_partner&.ecf_id }
      field(:delivery_partner_name) { |declaration| declaration.delivery_partner&.name }
      field(:secondary_delivery_partner_id) { |declaration| declaration.secondary_delivery_partner&.ecf_id }
      field(:secondary_delivery_partner_name) { |declaration| declaration.secondary_delivery_partner&.name }
      field(:statement_id) { |declaration| declaration.billable_statement&.ecf_id }
      field(:application_id) { |declaration| declaration.application.ecf_id }
      field(:clawback_statement_id) { |declaration| declaration.refundable_statement&.ecf_id }
      field(:uplift_paid?, name: :uplift_paid)
      field(:lead_provider_name)
      field(:ineligible_for_funding_reason)
      field(:created_at)

      field(:updated_at)
    end

    association :attributes, blueprint: AttributesSerializer do |declaration|
      declaration
    end
  end
end
