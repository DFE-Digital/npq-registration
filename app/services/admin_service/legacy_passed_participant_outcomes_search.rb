class AdminService::LegacyPassedParticipantOutcomesSearch
  attr_reader :trn

  def initialize(trn:)
    @trn = trn
  end

  def call
    legacy_outcomes(trn: trn)
  end

private

  def legacy_outcomes(trn:)
    LegacyPassedParticipantOutcome
      .select(:id, "'Historic outcome' as full_name", :trn, "completion_date as created_at", "'LegacyPassedParticipantOutcome' as class")
      .where(trn:)
  end
end
