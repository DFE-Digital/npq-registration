class AutoGenUuidEcfIdForUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :ecf_id, from: nil, to: "gen_random_uuid()"
    change_column_null :users, :ecf_id, false
  end
end
