class CreateLegacyPassedParticipantOutcomes < ActiveRecord::Migration[7.1]
  def change
    create_table :legacy_passed_participant_outcomes do |t|
      t.string :trn, null: false
      t.string :course_short_code
      t.date :completion_date
      t.timestamps
    end
    add_index :legacy_passed_participant_outcomes, :trn
  end
end
