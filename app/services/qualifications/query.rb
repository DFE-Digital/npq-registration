module Qualifications
  class Query
    def qualifications(trn:)
      ParticipantOutcome
        .includes(declaration: [application: [:course]])
        .where(state: "passed")
        .joins(declaration: [application: :user])
        .where("users.trn": trn)
    end
  end
end
