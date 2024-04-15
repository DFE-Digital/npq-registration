class ChangeApplicationsHeadteacherStatusToEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN headteacher_status TYPE headteacher_statuses
      USING headteacher_status::headteacher_statuses
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN headteacher_status TYPE text
    SQL
  end
end
