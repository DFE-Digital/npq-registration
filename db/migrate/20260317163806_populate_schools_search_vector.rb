class PopulateSchoolsSearchVector < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # This is needed to properly populate the search_vector column

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
        WHERE search_vector IS NULL
      SQL
    end

    # Ensure the trigger exists (recreate if missing)
    safety_assured do
      execute <<-SQL.squish
        DROP TRIGGER IF EXISTS schools_search_vector_update ON schools;

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
    # Trigger and index were created by the add_search_vector_to_schools migration
  end
end
