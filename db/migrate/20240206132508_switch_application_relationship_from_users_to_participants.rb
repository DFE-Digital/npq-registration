class SwitchApplicationRelationshipFromUsersToParticipants < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :applications, :users

    rename_column :applications, :user_id, :participant_id

    add_foreign_key :applications, :participants
  end
end
