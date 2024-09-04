class UpdateWorkSettingOtherAnswers < ActiveRecord::Migration[7.1]
  def up
    Application.where(work_setting: "other").update(work_setting: "another_setting")
  end

  def down
    Application.where(work_setting: "another_setting").update(work_setting: "other")
  end
end
