class CreateOutcomes < ActiveRecord::Migration[7.0]
  def change
    create_table :outcomes do |t|
      t.string :state
      t.date :completion_date
      t.references :declaration, null: false, foreign_key: true

      t.timestamps
    end
  end
end
