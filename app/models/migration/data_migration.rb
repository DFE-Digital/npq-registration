module Migration
  class DataMigration < ApplicationRecord
    validates :model, presence: true
    validates :processed_count, presence: true
    validates :failure_count, presence: true
    validates :total_count, presence: true, if: ->(m) { m.started_at.present? }
    validates :total_count, numericality: { greater_than: 0 }, allow_nil: true
    validates :completed_at, comparison: { greater_than: :started_at }, if: ->(m) { m.started_at.present? }, allow_nil: true

    default_scope { order(created_at: :asc) }

    def percentage_migrated_successfully
      return unless processed_count&.positive?

      ((processed_count - failure_count) / processed_count.to_f * 100).round
    end

    def percentage_migrated
      return unless total_count

      (processed_count / total_count.to_f * 100).round
    end

    def duration_in_seconds
      return unless started_at? && completed_at?

      (completed_at - started_at).to_i
    end

    def pending?
      !started_at?
    end

    def in_progress?
      !pending? && !complete?
    end

    def complete?
      completed_at.present?
    end
  end
end
