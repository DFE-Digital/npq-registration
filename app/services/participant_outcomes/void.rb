# frozen_string_literal: true

module ParticipantOutcomes
  class Void
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declaration

    def void_outcome
      return unless voidable_outcome?

      ParticipantOutcome.create!(
        declaration:,
        completion_date: declaration_date,
        state: "voided",
      )
    end

  private

    delegate :user, :lead_provider,
             :course, :declaration_date,
             to: :declaration

    def voidable_outcome?
      declaration.completed_declaration_type? &&
        valid_course_identifier_for_participant_outcome? &&
        !latest_existing_outcome&.voided_state?
    end

    def latest_existing_outcome
      @latest_existing_outcome ||= user&.latest_participant_outcome(lead_provider, course.identifier)
    end

    def valid_course_identifier_for_participant_outcome?
      CourseGroup.joins(:courses).leadership_or_specialist.where(courses: { identifier: course.identifier }).exists?
    end
  end
end
