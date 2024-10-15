class ParticipantOutcome < ApplicationRecord
  belongs_to :declaration
  has_many :participant_outcome_api_requests

  validates :ecf_id, uniqueness: true
  validates :state, presence: true
  validates :completion_date, presence: true
  validate :completion_date_not_in_the_future

  delegate :user, :lead_provider, :course, to: :declaration

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

  def latest_for_declaration?
    declaration.participant_outcomes.order(created_at: :desc).first == self
  end

private

  def completion_date_not_in_the_future
    errors.add(:completion_date, :future_date) if completion_date&.future?
  end
end
