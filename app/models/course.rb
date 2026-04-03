class Course < ApplicationRecord
  NPQ_ADDITIONAL_SUPPORT_OFFER = "npq-additional-support-offer".freeze # npq-additional-support-offer is replaced by npq-early-headship-coaching-offer
  NPQ_EARLY_HEADSHIP_COACHING_OFFER = "npq-early-headship-coaching-offer".freeze
  NPQ_EARLY_YEARS_LEADERSHIP = "npq-early-years-leadership".freeze
  NPQ_EXECUTIVE_LEADERSHIP = "npq-executive-leadership".freeze
  NPQ_HEADSHIP = "npq-headship".freeze
  NPQ_LEADING_BEHAVIOUR_CULTURE = "npq-leading-behaviour-culture".freeze
  NPQ_LEADING_LITERACY = "npq-leading-literacy".freeze
  NPQ_LEADING_PRIMARY_MATHEMATICS = "npq-leading-primary-mathematics".freeze
  NPQ_LEADING_TEACHING = "npq-leading-teaching".freeze
  NPQ_LEADING_TEACHING_DEVELOPMENT = "npq-leading-teaching-development".freeze
  NPQ_SENCO = "npq-senco".freeze
  NPQ_SENIOR_LEADERSHIP = "npq-senior-leadership".freeze

  belongs_to :course_group, optional: true

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  IDENTIFIERS = [
    # not in alphabetical order on purpose, to keep swagger docs consistent
    NPQ_SENIOR_LEADERSHIP,
    NPQ_HEADSHIP,
    NPQ_EXECUTIVE_LEADERSHIP,
    NPQ_EARLY_YEARS_LEADERSHIP,
    NPQ_LEADING_TEACHING,
    NPQ_LEADING_BEHAVIOUR_CULTURE,
    NPQ_LEADING_TEACHING_DEVELOPMENT,
    NPQ_LEADING_LITERACY,
    NPQ_LEADING_PRIMARY_MATHEMATICS,
    NPQ_ADDITIONAL_SUPPORT_OFFER,
    NPQ_EARLY_HEADSHIP_COACHING_OFFER,
    NPQ_SENCO,
  ].freeze

  ONLY_PP50 = [
    NPQ_EARLY_YEARS_LEADERSHIP,
    NPQ_EXECUTIVE_LEADERSHIP,
    NPQ_LEADING_BEHAVIOUR_CULTURE,
    NPQ_LEADING_LITERACY,
    NPQ_LEADING_PRIMARY_MATHEMATICS,
    NPQ_LEADING_TEACHING,
    NPQ_LEADING_TEACHING_DEVELOPMENT,
    NPQ_SENIOR_LEADERSHIP,
  ].freeze

  LA_NURSERY_APPROVED = [
    NPQ_EARLY_YEARS_LEADERSHIP,
    NPQ_HEADSHIP,
    NPQ_SENCO,
  ].freeze

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

  def senior_leadership?
    identifier == NPQ_SENIOR_LEADERSHIP
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
    super.tap do |sc|
      if sc.nil?
        message = "A NPQ Qualification types mapping is missing: #{identifier}"
        Rails.logger.warn(message)
        Sentry.capture_message(message)
      end
    end
  end
end
