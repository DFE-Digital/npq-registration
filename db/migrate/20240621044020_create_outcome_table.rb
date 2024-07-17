class CreateOutcomeTable < ActiveRecord::Migration[7.1]
  def change
    create_enum :outcome_states, %w[passed failed voided]

    create_table :outcomes do |t|
      t.enum :state, enum_type: "outcome_states", null: false
      t.date :completion_date, null: false
      t.references :declaration, null: false, foreign_key: true
      t.boolean :qualified_teachers_api_request_successful
      t.datetime :sent_to_qualified_teachers_api_at

      t.timestamps
      t.index %i[declaration_id created_at]
    end
  end
end
