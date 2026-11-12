class AdminService::HistoricUsersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  # One row per TRN, taking the earliest completion date.
  # Only use this when UsersSearch finds nothing: none of these TRNs belong to a user.
  def call
    LegacyPassedParticipantOutcome
      .where("trn ILIKE ?", "%#{q}%")
      .group(:trn)
      .select(:trn, "MIN(completion_date) AS completion_date")
      .order("MIN(completion_date) DESC", :trn)
  end
end
