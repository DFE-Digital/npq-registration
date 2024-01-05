class AddDeclarationTypeToSchedules < ActiveRecord::Migration[7.0]
  def change
    create_enum :schedule_declaration_types, %w[started retained-1 retained-2 retained-3 retained-4 completed]

    change_table :schedules do |t|
      t.enum :declaration_types, enum_type: "schedule_declaration_types", default: %w[started retained-1 retained-2 completed], null: false, array: true
    end
  end
end
