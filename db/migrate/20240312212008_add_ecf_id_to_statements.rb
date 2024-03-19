# frozen_string_literal: true

class AddEcfIdToStatements < ActiveRecord::Migration[7.1]
  def change
    add_column :statements, :ecf_id, :uuid, default: "gen_random_uuid()", null: false
    add_index :statements, :ecf_id, unique: true
  end
end
