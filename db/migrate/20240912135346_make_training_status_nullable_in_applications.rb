class MakeTrainingStatusNullableInApplications < ActiveRecord::Migration[7.1]
  def change
    change_column_default :applications, :training_status, from: "active", to: nil
    change_column_null :applications, :training_status, true
  end
end
