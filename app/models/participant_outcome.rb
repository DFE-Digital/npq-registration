class ParticipantOutcome < ApplicationRecord
  belongs_to :declaration
  has_many :participant_outcome_api_requests

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :state, presence: true
  validates :completion_date, presence: true
  validate :completion_date_not_in_the_future

  delegate :user, :lead_provider, :course, :application_id, to: :declaration
  delegate :trn, to: :user
  delegate :short_code, to: :course, prefix: true

  enum state: {
    passed: "passed",
    failed: "failed",
    voided: "voided",
  }, _suffix: true

  class << self
    def latest
      order(created_at: :desc).first
    end

    def to_send_to_qualified_teachers_api
      eligible_outcomes = not_sent_to_qualified_teachers_api
        .where(id: latest_per_declaration.map(&:id))

      eligible_outcomes.passed_state
        .or(
          eligible_outcomes
            .not_passed_state
            .where(declaration_id: declarations_where_outcome_passed_and_sent),
        )
    end

    def latest_per_declaration
      select("DISTINCT ON(declaration_id) *")
        .order(:declaration_id, created_at: :desc)
    end

    def declarations_where_outcome_passed_and_sent
      latest_per_declaration
        .passed_state
        .sent_to_qualified_teachers_api
        .map(&:declaration_id)
    end

    def sent_to_qualified_teachers_api
      where.not(sent_to_qualified_teachers_api_at: nil)
    end

    def not_sent_to_qualified_teachers_api
      where(sent_to_qualified_teachers_api_at: nil)
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

  def not_sent?
    sent_to_qualified_teachers_api_at.nil?
  end

  def sent_and_recorded?
    sent_to_qualified_teachers_api_at? && qualified_teachers_api_request_successful?
  end

  def sent_but_not_recorded?
    sent_to_qualified_teachers_api_at? && qualified_teachers_api_request_successful == false
  end

  def latest_for_declaration?
    self == declaration.participant_outcomes.max_by(&:created_at)
  end

  def allow_resending_to_qualified_teachers_api?
    sent_but_not_recorded? && latest_for_declaration?
  end

  def resend_to_qualified_teachers_api!
    return false unless allow_resending_to_qualified_teachers_api?

    update!(qualified_teachers_api_request_successful: nil,
            sent_to_qualified_teachers_api_at: nil)
  end

private

  def completion_date_not_in_the_future
    errors.add(:completion_date, :future_date) if completion_date&.future?
  end
end
