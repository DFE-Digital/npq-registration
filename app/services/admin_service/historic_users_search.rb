class AdminService::HistoricUsersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  # Finds the full TRN only. One row for the TRN, with its earliest completion date.
  # Only use this when UsersSearch finds nothing: then the TRN does not belong to a user.
  def call
    LegacyPassedParticipantOutcome
      .where(trn: q)
      .group(:trn)
      .select(:trn, "MIN(completion_date) AS completion_date")
  end
end
