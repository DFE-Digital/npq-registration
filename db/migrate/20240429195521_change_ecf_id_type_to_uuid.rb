class ChangeEcfIdTypeToUuid < ActiveRecord::Migration[7.1]
  TABLES = %i[applications courses lead_providers users].freeze

  def up
    TABLES.each do |table|
      change_column table, :ecf_id, :uuid, using: "ecf_id::uuid"
    end
  end

  def down
    TABLES.each do |table|
      change_column table, :ecf_id, :text
    end
  end
end
