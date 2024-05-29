class CreateApplicationStates < ActiveRecord::Migration[7.1]
  def change
    create_table :application_states do |t|
      t.references :application, null: false, foreign_key: true
      t.references :lead_provider, foreign_key: true
      t.enum :state, enum_type: "application_statuses", default: "active", null: false
      t.text :reason

      t.timestamps
    end
  end
end
