# frozen_string_literal: true

class ContractForCohortAndCourseValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?
    return unless contract_for_cohort_and_course(record).empty?

    record.errors.add(:cohort, :missing_contract_for_cohort_and_course)
  end

private

  def contract_for_cohort_and_course(record)
    Contract.joins(:course, :statement).where(
      courses: { identifier: record.course_identifier },
      statements: {
        cohort: record.cohort,
        lead_provider: record.lead_provider,
      },
    )
  end
end
