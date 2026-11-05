class AdminService::HistoricUsersSearch
  attr_reader :q

  def initialize(q:)
    @q = q
  end

  # One row per TRN that is only in the legacy data, with its earliest completion date.
  # A TRN that also belongs to a user is already found as that user.
  def call
    user_trns = User.where.not(trn: nil).select(:trn)

    LegacyPassedParticipantOutcome
      .where("trn ILIKE ?", "%#{q}%")
      .where.not(trn: user_trns)
      .group(:trn)
      .select(:trn, "MIN(completion_date) AS completion_date")
      .order("MIN(completion_date) DESC", :trn)
  end
end
