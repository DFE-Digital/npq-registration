class Schedule < ApplicationRecord
  DECLARATION_TYPES = %w[started retained-1 retained-2 completed].freeze
  IDENTIFIERS = %w[npq-aso-march
                   npq-aso-june
                   npq-aso-november
                   npq-aso-december
                   npq-ehco-march
                   npq-ehco-june
                   npq-ehco-november
                   npq-ehco-december
                   npq-leadership-autumn
                   npq-leadership-spring
                   npq-specialist-autumn
                   npq-specialist-spring].freeze

  belongs_to :course_group
  belongs_to :cohort
  has_many :courses, through: :course_group
  has_many :applications, dependent: :restrict_with_error
  has_many :milestones
  has_many :statements, through: :milestones

  normalizes :allowed_declaration_types, with: ->(value) { value.reject(&:blank?) }

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: { scope: :cohort_id }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :applies_from, presence: true
  validates :applies_to, presence: true
  validates :acceptance_window_start, presence: true, if: -> { new_record? || acceptance_window_start_was }
  validates :acceptance_window_end, presence: true, if: -> { new_record? || acceptance_window_end_was }
  validates :policy_descriptor, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: -> { new_record? || policy_descriptor_was }

  def self.allowed_declaration_types
    Declaration.declaration_types.keys
  end
end
