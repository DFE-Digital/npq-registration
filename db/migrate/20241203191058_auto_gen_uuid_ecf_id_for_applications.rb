class AutoGenUuidEcfIdForApplications < ActiveRecord::Migration[7.1]
  def up
    change_column_default :applications, :ecf_id, from: nil, to: "gen_random_uuid()"
    execute "UPDATE applications SET ecf_id = gen_random_uuid() WHERE ecf_id IS NULL;"
    change_column_null :applications, :ecf_id, false
  end

  def down
    change_column_null :applications, :ecf_id, true
    change_column_default :applications, :ecf_id, from: "gen_random_uuid()", to: nil
  end
end
