# frozen_string_literal: true

class AddEcfIdToStatements < ActiveRecord::Migration[7.1]
  def change
    add_column :statements, :ecf_id, :text, null: true
    add_index :statements, :ecf_id, unique: true
  end
end
