class SweepStaleSessionsJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::SessionStore::Session
      .where("updated_at < ?", 15.days.ago)
      .delete_all
  end
end
