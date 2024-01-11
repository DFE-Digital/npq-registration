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

    def cache_orphan_report(report, key)
      Rails.cache.write("orphaned_#{key}_#{id}", report.to_yaml, expires_in: 1.month)
    end

    def cached_orphan_report(key)
      Rails.cache.read("orphaned_#{key}_#{id}")
    end
  end
end
