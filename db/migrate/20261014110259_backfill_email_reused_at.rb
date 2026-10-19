class BackfillEmailReusedAt < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL
        UPDATE users
        SET email_reused_at = archived_at
        WHERE email IS NULL
        AND archived_at IS NOT NULL
      SQL
    end
  end
end
