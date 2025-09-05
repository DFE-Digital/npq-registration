class ParticipantOutcome < ApplicationRecord
  self.ignored_columns = %i[
    qualified_teachers_api_request_successful
    sent_to_qualified_teachers_api_at
  ]

  belongs_to :declaration

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :state, presence: true
  validates :completion_date, presence: true
  validate :completion_date_not_in_the_future

  delegate :user, :lead_provider, :course, :application_id, to: :declaration
  delegate :trn, to: :user
  delegate :short_code, to: :course, prefix: true

  enum :state, {
    passed: "passed",
    failed: "failed",
    voided: "voided",
  }, suffix: true

  class << self
    def latest
      order(created_at: :desc, id: :desc).first
    end

    def latest_per_declaration
      select("DISTINCT ON(declaration_id) *")
        .order(:declaration_id, created_at: :desc)
    end
  end

  def has_passed?
    return nil if voided_state?

    passed_state?
  end

  def has_failed?
    return nil if voided_state?

    failed_state?
  end

  def latest_for_declaration?
    self == declaration.participant_outcomes.max_by(&:created_at)
  end

private

  def completion_date_not_in_the_future
    errors.add(:completion_date, :future_date) if completion_date&.future?
  end
end
