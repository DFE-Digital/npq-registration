class UpdateWorkSettingOtherAnswers < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE applications SET work_setting='another_setting' WHERE work_setting='other'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE applications SET work_setting='other' WHERE work_setting='another_setting'
    SQL
  end
end
