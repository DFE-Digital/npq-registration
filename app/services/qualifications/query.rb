module Qualifications
  class Query
    def qualifications(trn:)
      (participant_outcomes(trn:) + legacy_outcomes(trn:)).uniq { |outcome|
        [outcome.trn, outcome.completion_date, outcome.course_short_code]
      }.sort_by(&:completion_date).reverse
    end

  private

    def participant_outcomes(trn:)
      ParticipantOutcome
        .includes(declaration: [application: [:course]])
        .where(state: "passed")
        .joins(declaration: [application: :user])
        .where("users.trn": trn)
        .order(completion_date: :desc)
    end

    def legacy_outcomes(trn:)
      LegacyPassedParticipantOutcome.where(trn:)
    end
  end
end
