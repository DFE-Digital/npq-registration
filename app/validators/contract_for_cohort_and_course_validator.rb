# frozen_string_literal: true

class ContractForCohortAndCourseValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?
    return unless contract_for_cohort_and_course_missing?(record)

    record.errors.add(:cohort, options[:message] || I18n.t(:missing_npq_contract_for_cohort_and_course))
  end

private

  def contract_for_cohort_and_course_missing?(record)
    return unless npq_course?(record)

    contract_for_cohort_and_course(record).empty?
  end

  def contract_for_cohort_and_course(record)
    Contract.joins(:course, statement: %i[cohort lead_provider]).where(
      statement: { lead_provider: record.lead_provider, cohort: record.cohort },
      course: { identifier: record.course_identifier },
    )
  end

  def npq_course?(record)
    Course::IDENTIFIERS.include?(record.course_identifier)
  end
end
