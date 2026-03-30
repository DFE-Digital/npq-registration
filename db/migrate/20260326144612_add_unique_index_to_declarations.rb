class AddUniqueIndexToDeclarations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :declarations,
              %i[application_id declaration_type],
              where: "state IN ('submitted','eligible','payable','paid')",
              unique: true,
              name: "idx_unique_declarations",
              algorithm: :concurrently
  end
end
