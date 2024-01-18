# frozen_string_literal: true

require "jsonapi/serializer/instrumentation"

module Api
  module V3
    class DeclarationSerializer
      include JSONAPI::Serializer
      include JSONAPI::Serializer::Instrumentation

      set_id :id
      set_type :'participant-declaration'

      attributes :participant_id, :declaration_type, :course_identifier

      attribute :declaration_date do |declaration|
        declaration.declaration_date.rfc3339
      end

      attribute(:mentor_id) do |object|
        # object.mentor_user_id # TODO missing
      end

      attribute(:participant_id) do |object|
        object.application.user.ecf_id
      end

      attribute(:course_identifier) do |object|
        # object.course.identifier
      end

      attribute :state do |declaration|
        declaration.state
      end

      attribute :updated_at do |declaration|
        declaration.updated_at.rfc3339
      end

      attribute :created_at do |declaration|
        declaration.created_at.rfc3339
      end

      attribute :delivery_partner_id do |declaration|
        # ECF only
      end

      attribute :statement_id do |declaration|
        # declaration.statement_items.detect(&:billable?)&.statement_id
        declaration.statement_items.first&.statement_id
      end

      attribute :clawback_statement_id do |declaration|
        # declaration.statement_items.detect(&:refundable?)&.statement_id
        declaration.statement_items.first&.statement_id
      end

      attribute :ineligible_for_funding_reason do |declaration|
        # TODO missing
        # if declaration.ineligible?
        #   reason = declaration.declaration_states.detect(&:ineligible?)&.state_reason

        #   case reason
        #   when "duplicate"
        #     "duplicate_declaration"
        #   else
        #     reason
        #   end
        # end
      end

      attribute :uplift_paiddo do |declaration|
        # declaration.uplift_paid?
      end

      attribute :evidence_held do |declaration|
        # ECF only
      end

      attribute :has_passed do |declaration|
        declaration.outcomes.sort_by(&:created_at).reverse!&.first&.has_passed?
      end

      attribute :lead_provider_name do |declaration|
        declaration.application.lead_provider&.name
      end
    end
  end
end
