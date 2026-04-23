class Cohort < ApplicationRecord
  self.ignored_columns += [:funding_cap]

  has_paper_trail

  has_many :declarations, dependent: :restrict_with_exception
  has_many :schedules, dependent: :destroy
  has_many :statements, dependent: :restrict_with_exception
  has_many :delivery_partnerships, dependent: :destroy
  has_many :delivery_partners, through: :delivery_partnerships

  enum :funding, {
    zero: "zero",
    capped: "capped",
    full: "full",
  }, suffix: true

  validates :start_year,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 2021,
              less_than: 2030,
            }

  validates :suffix,
            presence: true,
            uniqueness: { scope: :start_year },
            length: { within: 1..1 },
            format: { with: /\A[a-z]+\z/ }

  validates :description,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { within: 5..50 }

  validates :registration_start_date, presence: true
  validate :registration_start_date_matches_start_year
  validates :funding, inclusion: { in: fundings.values }
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
  validate :changing_funding_cap_with_dependent_applications

  scope :order_by_latest, -> { order(start_year: :desc, suffix: :desc) }
  scope :order_by_oldest, -> { order(start_year: :asc, suffix: :asc) }

  scope :prior_to, lambda { |cohort|
    where("start_year < :year OR (start_year = :year AND suffix < :suffix)",
          year: cohort.start_year, suffix: cohort.suffix)
  }

  def self.current(timestamp: Time.zone.today, cohort_funding: nil)
    scope = order_by_latest
    scope = scope.where(funding: cohort_funding) if cohort_funding.present?
    scope.find_by!(registration_start_date: ..timestamp)
  end

  def name
    suffix == "a" ? start_year.to_s : identifier
  end

  def funded?
    full_funding? || capped_funding?
  end

private

  def registration_start_date_matches_start_year
    return if registration_start_date.blank?

    errors.add(:registration_start_date, "year must match the start year") if registration_start_date.year != start_year
  end

  def changing_funding_cap_with_dependent_applications
    return unless funding_changed? && Application.where(cohort: self).any?

    errors.add(:funding, "Cannot change funding when there are existing applications for this cohort")
  end
end
