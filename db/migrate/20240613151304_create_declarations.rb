class CreateDeclarations < ActiveRecord::Migration[7.1]
  def change
    create_enum :declaration_states, %w[submitted eligible payable paid voided ineligible awaiting_clawback clawed_back]
    create_enum :declaration_types, %w[started retained-1 retained-2 completed]
    create_enum :declaration_state_reasons, %w[duplicate]

    create_table :declarations do |t|
      t.uuid :ecf_id, default: "gen_random_uuid()", null: false, index: true

      t.references :application, null: false, foreign_key: true
      t.references :superseded_by, null: true, foreign_key: { to_table: :declarations }
      t.references :lead_provider, null: false, foreign_key: true
      t.references :cohort, null: false, foreign_key: true

      t.enum :declaration_type, enum_type: "declaration_types"
      t.date :declaration_date

      t.enum :state, enum_type: "declaration_states", default: "submitted", null: false
      t.enum :state_reason, enum_type: "declaration_state_reasons"

      t.timestamps
    end
  end
end
