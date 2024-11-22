class BackfillSignificantlyUpdatedAt < ActiveRecord::Migration[7.1]
  def up
    User.in_batches do |batch|
      batch.update_all("significantly_updated_at = updated_at")
    end
  end
end
