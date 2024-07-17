# frozen_string_literal: true

class CourseForParticipantValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?
    return if has_accepted_application_for_course_given_course_identifier?(record)

    record.errors.add(:course_identifier, :invalid)
  end

private

  def has_accepted_application_for_course_given_course_identifier?(record)
    return if record.participant.blank?

    record.participant.applications.accepted.joins(:course).where(course: Course.find_by(identifier: record.course_identifier)&.rebranded_alternative_courses).any?
  end
end
