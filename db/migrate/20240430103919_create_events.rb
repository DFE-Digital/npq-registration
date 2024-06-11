class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.timestamps

      t.string :title, limit: 256, null: false
      t.string :byline, limit: 128
      t.text :event_type, null: false
      t.text :description

      # indexed with high cardinality
      t.integer :admin_id, index: true
      t.integer :application_id, index: true
      t.integer :user_id, index: true
      t.integer :school_id, index: true
      t.integer :private_childcare_provider_id, index: true
      t.integer :statement_id, index: true
      t.integer :statement_item_id, index: true
      t.integer :lead_provider_id, index: true

      # unindexed with low cardinality
      t.integer :cohort_id
      t.integer :course_id
    end

    add_foreign_key :events, :admins, on_delete: :nullify
    add_foreign_key :events, :applications, on_delete: :nullify
    add_foreign_key :events, :users, on_delete: :nullify
    add_foreign_key :events, :schools, on_delete: :nullify
    add_foreign_key :events, :private_childcare_providers, on_delete: :nullify
    add_foreign_key :events, :statements, on_delete: :nullify
    add_foreign_key :events, :statement_items, on_delete: :nullify
    add_foreign_key :events, :cohorts, on_delete: :nullify
    add_foreign_key :events, :courses, on_delete: :nullify
    add_foreign_key :events, :lead_providers, on_delete: :nullify
  end
end
