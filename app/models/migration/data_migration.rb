module Migration
  class DataMigration < ApplicationRecord
    validates :model, presence: true
    validates :processed_count, presence: true
    validates :failure_count, presence: true
    validates :total_count, presence: true, if: ->(m) { m.started_at.present? }
    validates :total_count, numericality: { greater_than: 0 }, allow_nil: true
    validates :completed_at, comparison: { greater_than: :started_at }, if: ->(m) { m.started_at.present? }, allow_nil: true
  end
end
