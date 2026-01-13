module API
  class ParticipantSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "npq-participant" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:full_name)
      field(:teacher_reference_number) do |object, _options|
        object.trn if object.trn_verified
      end
      field(:updated_at) do |object, _options|
        updated_at(object)
      end

      field(:npq_enrolments) do |object, options|
        applications(object, options).map do |application|
          {
            email: object.email,
            course_identifier: application.course.identifier,
            schedule_identifier: application&.schedule&.identifier,
            cohort: application.cohort&.start_year&.to_s,
            npq_application_id: application.ecf_id,
            eligible_for_funding: application.eligible_for_funding,
            training_status: application.training_status,
            school_urn: application.school&.urn,
            targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
            withdrawal: withdrawal(application:, lead_provider: options[:lead_provider]),
            deferral: deferral(application:, lead_provider: options[:lead_provider]),
            created_at: application.accepted_at.rfc3339,
            funded_place: application.funded_place,
          }
        end
      end

      field(:participant_id_changes) do |object, _options|
        (object.participant_id_changes || []).map do |participant_id_change|
          API::ParticipantIdChangeSerializer.render_as_hash(participant_id_change)
        end
      end

      class << self
        def applications(object, options)
          return Application.none unless options[:lead_provider]

          object.applications.select { |application| application.accepted_lead_provider_approval_status? && application.lead_provider_id == options[:lead_provider].id }
        end

        def withdrawal(application:, lead_provider:)
          if application.withdrawn_training_status?
            # We are doing this in memory to avoid running those as queries on each request
            latest_application_state = application
              .application_states.sort_by(&:created_at)
              .reverse!
              .find { |as| as.state == ApplicationState.states[:withdrawn] && as.lead_provider_id == lead_provider.id }

            if latest_application_state.present?
              {
                reason: latest_application_state.reason,
                date: latest_application_state.created_at.rfc3339,
              }
            end
          end
        end

        def deferral(application:, lead_provider:)
          if application.deferred_training_status?
            # We are doing this in memory to avoid running those as queries on each request
            latest_application_state = application
              .application_states.sort_by(&:created_at)
              .reverse!
              .find { |as| as.state == ApplicationState.states[:deferred] && as.lead_provider_id == lead_provider.id }

            if latest_application_state.present?
              {
                reason: latest_application_state.reason,
                date: latest_application_state.created_at.rfc3339,
              }
            end
          end
        end

        def updated_at(user)
          (
            (user.participant_id_changes || []).map(&:updated_at) +
            (user.applications || []).map(&:updated_at) +
            [user.significantly_updated_at]
          ).compact.max
        end
      end
    end

    association :attributes, blueprint: AttributesSerializer do |participant|
      participant
    end
  end
end
