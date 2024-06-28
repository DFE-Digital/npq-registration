class ParticipantOutcome < ApplicationRecord
  belongs_to :declaration

  validates :ecf_id, presence: true, uniqueness: true
  validates :state, presence: true
  validates :completion_date, presence: true
  validate :completion_date_not_in_the_future

private

  def completion_date_not_in_the_future
    errors.add(:completion_date, :future_date) if completion_date&.future?
  end
end
