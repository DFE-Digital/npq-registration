class AddSearchVectorToSchools < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Build the tsvector expression for all searchable fields
    search_columns = %w[
      name
      la_name
      address_1
      address_2
      address_3
      town
      county
      postcode
      postcode_without_spaces
      region
      urn
    ].map { |col| "coalesce(#{col}, '')" }.join(" || ' ' || ")

    # Add generated column that automatically maintains search_vector
    add_column :schools, :search_vector, :tsvector,
               as: "to_tsvector('english', #{search_columns})",
               stored: true

    # Add GIN index for fast full-text searching
    add_index :schools, :search_vector, using: :gin, algorithm: :concurrently
  end

  def down
    remove_index :schools, :search_vector, algorithm: :concurrently
    remove_column :schools, :search_vector
  end
end
