class AddSchoolSearchIndexes < ActiveRecord::Migration[6.1]
  def up
    enable_extension "btree_gin"

    add_index :schools, 'to_tsvector(\'english\', coalesce("schools"."name"::text, \'\'))', using: :gin, name: "school_name_search_idx"
  end

  def down
    remove_index :schools, name: "school_name_search_idx"
  end
end
