RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.connection.execute(<<-SQL)
      DROP TRIGGER IF EXISTS schools_search_vector_update ON schools;

      CREATE TRIGGER schools_search_vector_update
      BEFORE INSERT OR UPDATE ON schools
      FOR EACH ROW EXECUTE FUNCTION
      tsvector_update_trigger(
        search_vector, 'pg_catalog.english',
        name, la_name, address_1, address_2, address_3,
        town, county, postcode, postcode_without_spaces, region, urn
      );
    SQL
  end
end
