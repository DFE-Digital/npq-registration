class AddTsvectorIndexesToSchools < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(la_name, ''::text))",
              name: "school_la_name_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(address_1, ''::text))",
              name: "school_address_1_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(address_2, ''::text))",
              name: "school_address_2_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(address_3, ''::text))",
              name: "school_address_3_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(town, ''::text))",
              name: "school_town_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(county, ''::text))",
              name: "school_county_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(postcode, ''::text))",
              name: "school_postcode_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(postcode_without_spaces, ''::text))",
              name: "school_postcode_without_spaces_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(region, ''::text))",
              name: "school_region_search_idx",
              using: :gin,
              algorithm: :concurrently

    add_index :schools,
              "to_tsvector('english'::regconfig, COALESCE(urn, ''::text))",
              name: "school_urn_search_idx",
              using: :gin,
              algorithm: :concurrently
  end
end
