class Course < ApplicationRecord
  NPQ_HEADSHIP = "npq-headship".freeze
  NPQ_EARLY_HEADSHIP_COACHING_OFFER = "npq-early-headship-coaching-offer".freeze
  NPQ_EARLY_YEARS_LEADERSHIP = "npq-early-years-leadership".freeze
  NPQ_LEADING_TEACHING_DEVELOPMENT = "npq-leading-teaching-development".freeze
  NPQ_LEADING_PRIMARY_MATHEMATICS = "npq-leading-primary-mathematics".freeze
  NPQ_ADDITIONAL_SUPPORT_OFFER = "npq-additional-support-offer".freeze
  NPQ_SENCO = "npq-senco".freeze

  belongs_to :course_group, optional: true

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  # npq-additional-support-offer is replaced by npq-early-headship-coaching-offer
  IDENTIFIERS = %w[
    npq-senior-leadership
    npq-headship
    npq-executive-leadership
    npq-early-years-leadership
    npq-leading-teaching
    npq-leading-behaviour-culture
    npq-leading-teaching-development
    npq-leading-literacy
    npq-leading-primary-mathematics
    npq-additional-support-offer
    npq-early-headship-coaching-offer
    npq-senco
  ].freeze

  ONLY_PP50 = %w[
    npq-leading-primary-mathematics
    npq-leading-behaviour-culture
    npq-leading-literacy
    npq-leading-teaching
    npq-leading-teaching-development
    npq-senior-leadership
    npq-executive-leadership
    npq-early-years-leadership
  ].freeze

  EYL_DISADVANTAGED = %w[
    npq-early-years-leadership
  ].freeze

  LA_NURSERY_APPROVED = %w[
    npq-senco
    npq-headship
    npq-early-years-leadership
  ].freeze

  # Two courses do not have short codes:
  # - npq-early-headship-coaching-offer
  # - npq-additional-support-offer
  SHORT_CODES = {
    "npq-leading-teaching" => "NPQLT",
    "npq-leading-behaviour-culture" => "NPQLBC",
    "npq-leading-teaching-development" => "NPQLTD",
    "npq-leading-literacy" => "NPQLL",
    "npq-senior-leadership" => "NPQSL",
    "npq-headship" => "NPQH",
    "npq-executive-leadership" => "NPQEL",
    "npq-early-years-leadership" => "NPQEYL",
    "npq-leading-primary-mathematics" => "NPQLPM",
    "npq-senco" => "NPQSENCO",
  }.freeze

  def schedule_for(cohort: Cohort.current, schedule_date: Date.current)
    course_group.schedule_for(cohort:, schedule_date:)
  end

  class << self
    def npqeyl
      find_by(identifier: NPQ_EARLY_YEARS_LEADERSHIP)
    end

    def npqltd
      find_by(identifier: NPQ_LEADING_TEACHING_DEVELOPMENT)
    end

    def ehco
      find_by(identifier: NPQ_EARLY_HEADSHIP_COACHING_OFFER)
    end
  end

  def supports_targeted_delivery_funding?
    !ehco?
  end

  def npqh?
    identifier == NPQ_HEADSHIP
  end

  def ehco?
    identifier == NPQ_EARLY_HEADSHIP_COACHING_OFFER
  end

  def eyl?
    identifier == NPQ_EARLY_YEARS_LEADERSHIP
  end

  def npqltd?
    identifier == NPQ_LEADING_TEACHING_DEVELOPMENT
  end

  def npqlpm?
    identifier == NPQ_LEADING_PRIMARY_MATHEMATICS
  end

  def senco?
    identifier == NPQ_SENCO
  end

  def aso?
    identifier == NPQ_ADDITIONAL_SUPPORT_OFFER
  end

  def only_pp50?
    ONLY_PP50.include?(identifier)
  end

  def la_nursery_approved?
    LA_NURSERY_APPROVED.include?(identifier)
  end

  def rebranded_alternative_courses
    rebranded_identifiers = [NPQ_ADDITIONAL_SUPPORT_OFFER, NPQ_EARLY_HEADSHIP_COACHING_OFFER].freeze

    return Course.where(identifier: rebranded_identifiers) if identifier.in?(rebranded_identifiers)

    [self]
  end

  def npqs?
    identifier == NPQ_SENCO
  end

  def short_code
    SHORT_CODES.fetch(identifier)
  rescue KeyError => e
    Rails.logger.warn("A NPQ Qualification types mapping is missing: #{e.message}")
    Sentry.capture_exception(e)

    nil
  end
end
