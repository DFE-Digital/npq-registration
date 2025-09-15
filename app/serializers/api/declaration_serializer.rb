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

      view :v1 do
        field(:voided_state?, name: :voided)
        field(:eligible_for_payment?, name: :eligible_for_payment)
      end

      view :v2 do
      end

      view :v3 do
        field(:delivery_partner_id) { |declaration| declaration.delivery_partner&.ecf_id }
        field(:delivery_partner_name) { |declaration| declaration.delivery_partner&.name }
        field(:secondary_delivery_partner_id) { |declaration| declaration.secondary_delivery_partner&.ecf_id }
        field(:secondary_delivery_partner_name) { |declaration| declaration.secondary_delivery_partner&.name }
        lp_self_serve_feature_flag_checker = ->(*) { Feature.lp_self_serve? }

        field(:statement_id) { |declaration| declaration.billable_statement&.ecf_id }
        field(:application_id, if: lp_self_serve_feature_flag_checker) { |declaration| declaration.application.ecf_id }
        field(:clawback_statement_id) { |declaration| declaration.refundable_statement&.ecf_id }
        field(:uplift_paid?, name: :uplift_paid)
        field(:lead_provider_name)
        field(:ineligible_for_funding_reason)
        field(:created_at)
      end

      field(:updated_at)
    end

    %i[v1 v2 v3].each do |version|
      view version do
        association :attributes, blueprint: AttributesSerializer, view: version do |declaration|
          declaration
        end
      end
    end
  end
end
