# frozen_string_literal: true

class CourseForParticipantValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?
    return if has_accepted_application_for_course_given_course_identifier?(record)

    record.errors.add(:course_identifier, I18n.t(:invalid_course))
  end

private

  def has_accepted_application_for_course_given_course_identifier?(record)
    return if record.participant.blank?

    record.participant.applications.joins(:course).accepted.active.map { |application|
      application.course.rebranded_alternative_courses.map(&:identifier)
    }.flatten.include?(record.course_identifier)
  end
end
