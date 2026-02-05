module API
  class ParticipantOutcomeSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "participant-outcome" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:state)
      field(:completion_date)
      field(:course_identifier) { |outcome| outcome.declaration.application.course.identifier }
      field(:participant_id) { |outcome| outcome.user.ecf_id }
      field(:created_at)
      field(:updated_at)
    end

    association :attributes, blueprint: AttributesSerializer do |outcome|
      outcome
    end
  end
end
