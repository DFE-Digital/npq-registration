class Cohort < ApplicationRecord
  has_many :declarations, dependent: :restrict_with_exception
  has_many :schedules, dependent: :destroy
  has_many :statements, dependent: :restrict_with_exception
  has_many :delivery_partnerships, dependent: :destroy
  has_many :delivery_partners, through: :delivery_partnerships

  validates :start_year,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 2021,
              less_than: 2030,
            },
            uniqueness: true

  validates :registration_start_date, presence: true
  validate :registration_start_date_matches_start_year
  validates :funding_cap, inclusion: { in: [true, false] }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  validate :changing_funding_cap_with_dependent_applications

  def self.current(timestamp = Time.zone.today)
    where(registration_start_date: ..timestamp)
      .order(start_year: :desc)
      .first!
  end

  def name
    start_year
  end

private

  def registration_start_date_matches_start_year
    return if registration_start_date.blank?

    errors.add(:registration_start_date, "year must match the start year") if registration_start_date.year != start_year
  end

  def changing_funding_cap_with_dependent_applications
    return unless funding_cap_changed? && Application.where(cohort: self).any?

    errors.add(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
  end
end
