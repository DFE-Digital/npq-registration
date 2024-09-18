class ChangeFromAndToParticipantIdsToUuidInParticipantIdChanges < ActiveRecord::Migration[7.1]
  def up
    change_column :participant_id_changes, :from_participant_id, :uuid
    change_column :participant_id_changes, :to_participant_id, :uuid
  end

  def down; end
end
