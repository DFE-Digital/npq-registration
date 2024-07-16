class ParticipantOutcome < ApplicationRecord
  belongs_to :declaration

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

  def self.latest
    order(created_at: :desc).first
  end

  def has_passed?
    return nil if voided_state?

    passed_state?
  end

private

  def completion_date_not_in_the_future
    errors.add(:completion_date, :future_date) if completion_date&.future?
  end
end
