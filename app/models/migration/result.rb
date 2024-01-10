module Migration
  class Result < ApplicationRecord
    self.table_name = "migration_results"

    scope :complete, -> { where.not(completed_at: nil) }
    scope :incomplete, -> { where(completed_at: nil) }
    scope :ordered_by_most_recent, -> { order(created_at: :desc) }

    class << self
      def in_progress
        incomplete.first
      end

      def most_recent_complete
        complete.ordered_by_most_recent.first
      end
    end
  end
end
