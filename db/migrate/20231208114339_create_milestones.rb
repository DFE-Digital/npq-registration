class CreateMilestones < ActiveRecord::Migration[7.0]
  def change
    create_table :milestones do |t|
      t.references :schedule, null: false, foreign_key: true
      t.string :declaration_type

      t.timestamps
    end
  end
end
