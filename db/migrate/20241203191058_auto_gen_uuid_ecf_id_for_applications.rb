class AutoGenUuidEcfIdForApplications < ActiveRecord::Migration[7.1]
  def change
    change_column_default :applications, :ecf_id, from: nil, to: "gen_random_uuid()"
    change_column_null :applications, :ecf_id, false
  end
end
