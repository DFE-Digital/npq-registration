class AddSearchVectorToSchools < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_column :schools, :search_vector, :tsvector

    safety_assured do
      execute <<-SQL.squish
        UPDATE schools SET search_vector =
          to_tsvector('english', coalesce(name, '')) ||
          to_tsvector('english', coalesce(la_name, '')) ||
          to_tsvector('english', coalesce(address_1, '')) ||
          to_tsvector('english', coalesce(address_2, '')) ||
          to_tsvector('english', coalesce(address_3, '')) ||
          to_tsvector('english', coalesce(town, '')) ||
          to_tsvector('english', coalesce(county, '')) ||
          to_tsvector('english', coalesce(postcode, '')) ||
          to_tsvector('english', coalesce(postcode_without_spaces, '')) ||
          to_tsvector('english', coalesce(region, '')) ||
          to_tsvector('english', coalesce(urn, ''))
      SQL
    end

    add_index :schools, :search_vector, using: :gin, algorithm: :concurrently

    safety_assured do
      execute <<-SQL.squish
        CREATE TRIGGER schools_search_vector_update
        BEFORE INSERT OR UPDATE ON schools
        FOR EACH ROW EXECUTE FUNCTION
        tsvector_update_trigger(
          search_vector, 'pg_catalog.english',
          name, la_name, address_1, address_2, address_3,
          town, county, postcode, postcode_without_spaces, region, urn
        )
      SQL
    end
  end

  def down
    safety_assured do
      execute "DROP TRIGGER IF EXISTS schools_search_vector_update ON schools"
    end

    remove_index :schools, :search_vector

    remove_column :schools, :search_vector
  end
end
