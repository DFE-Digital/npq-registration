class RenameOutcomeToParticipantOutcome < ActiveRecord::Migration[7.1]
  def change
    rename_table :outcomes, :participant_outcomes
  end
end
