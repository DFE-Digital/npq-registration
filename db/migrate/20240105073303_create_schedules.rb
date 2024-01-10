class CreateSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :schedules do |t|
      t.string :name, null: false
      t.date :declaration_starts_on, null: false
      t.date :schedule_applies_from, null: false
      t.date :schedule_applies_to, null: false
      t.references :course_group, null: false, foreign_key: true
      t.references :cohort, null: false, foreign_key: true

      t.timestamps
    end
  end
end
