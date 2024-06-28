class ParticipantOutcome < ApplicationRecord
  belongs_to :declaration

  validates :state, presence: true
  validates :completion_date, presence: true
  validate :completion_date_not_in_the_future

private

  def completion_date_not_in_the_future
    errors.add(:completion_date, "must be in the future") if completion_date && completion_date > Time.zone.today
  end
end
