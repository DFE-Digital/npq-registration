class ClearArchivedAtForEmailReusedAtUsers < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL
        UPDATE users
        SET archived_at = NULL
        WHERE email_reused_at IS NOT NULL
        AND archived_at IS NOT NULL
      SQL
    end
  end
end
