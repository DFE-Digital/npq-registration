class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_enum :schedule_declaration_types, %w[started retained-1 retained-2 completed]

    create_table :schedules do |t|
      t.references :course_group, null: false, foreign_key: true
      t.references :cohort, null: false, foreign_key: true

      t.string :name, null: false
      t.string :identifier, null: false

      t.date :applies_from, null: false
      t.date :applies_to, null: false
      t.enum :allowed_declaration_types, array: true, default: %w[started retained-1 retained-2 completed], enum_type: "schedule_declaration_types"

      t.timestamps
    end

    add_index :schedules, %i[identifier cohort_id], unique: true
  end
end
