module API
  class ParticipantSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "npq-participant" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:email)
      field(:full_name)
      field(:trn, name: :teacher_reference_number)
      field(:updated_at)

      view :v1 do
        field(:npq_courses) do |object, options|
          applications(object, options).map { |application| application.course.identifier }
        end

        field(:funded_places) do |object, options|
          applications(object, options).map do |application|
            {
              npq_course: application.course.identifier,
              funded_place: application.funded_place,
              npq_application_id: application.ecf_id,
            }
          end
        end
      end

      view :v2 do
        field(:npq_enrolments) do |object, options|
          applications(object, options).map do |application|
            {
              course_identifier: application.course.identifier,
              # TODO: Add when schedules are implemented
              schedule_identifier: nil,
              cohort: application.cohort&.start_year&.to_s,
              npq_application_id: application.ecf_id,
              eligible_for_funding: application.eligible_for_funding,
              training_status: application.training_status,
              school_urn: application.school&.urn,
              targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
              funded_place: application.funded_place,
            }
          end
        end
      end

      view :v3 do
        field(:npq_enrolments) do |object, options|
          applications(object, options).map do |application|
            {
              email: object.email,
              course_identifier: application.course.identifier,
              # TODO: Add when schedules are implemented
              schedule_identifier: nil,
              cohort: application.cohort&.start_year&.to_s,
              npq_application_id: application.ecf_id,
              eligible_for_funding: application.eligible_for_funding,
              training_status: application.training_status,
              school_urn: application.school&.urn,
              targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
              withdrawal: nil,
              deferral: nil,
              created_at: application.created_at.rfc3339,
              funded_place: application.funded_place,
            }
          end
        end

        field(:participant_id_changes) do |object, _options|
          (object.participant_id_changes || []).map do |participant_id_change|
            {
              from_participant_id: participant_id_change.from_participant.ecf_id,
              to_participant_id: participant_id_change.to_participant.ecf_id,
              changed_at: participant_id_change.created_at.rfc3339,
            }
          end
        end
      end

      def self.applications(object, options)
        scope = object.applications

        if options[:lead_provider]
          scope.where(lead_provider: options[:lead_provider])
        else
          Application.none
        end
      end
    end

    association :attributes, blueprint: AttributesSerializer do |participant|
      participant
    end

    %i[v1 v2 v3].each do |version|
      view version do
        association :attributes, blueprint: AttributesSerializer, view: version do |participant|
          participant
        end
      end
    end
  end
end
