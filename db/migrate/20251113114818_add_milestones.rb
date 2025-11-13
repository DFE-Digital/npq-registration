class AddMilestones < ActiveRecord::Migration[7.2]
  def change
    create_table :milestones do |t|
      t.enum :declaration_type, enum_type: "declaration_types", null: false
      t.references :schedule, null: false, foreign_key: true
      t.timestamps
    end

    add_index :milestones, %i[schedule_id declaration_type], unique: true

    create_table :milestones_statements do |t|
      t.references :milestone, null: false, foreign_key: true
      t.references :statement, null: false, foreign_key: true
      t.timestamps
    end

    add_index :milestones_statements, %i[milestone_id statement_id], unique: true
  end
end
