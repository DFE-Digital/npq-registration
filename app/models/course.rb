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
  validates :identifier,
            presence: { message: "Enter a identifier" },
            uniqueness: { message: "Identifier already exists, enter a unique one" }

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
    npq-leading-literacy
    npq-leading-behaviour-culture
    npq-leading-teaching-development
    npq-leading-teaching

    npq-senior-leadership
    npq-executive-leadership
    npq-early-years-leadership
  ].freeze

  def schedule_for(cohort:)
    course_group.schedule_for(cohort:)
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

  def only_pp50?
    ONLY_PP50.include?(identifier)
  end

  def rebranded_alternative_courses
    case identifier
    when NPQ_ADDITIONAL_SUPPORT_OFFER
      [self, Course.find_by(identifier: NPQ_EARLY_HEADSHIP_COACHING_OFFER)]
    when NPQ_EARLY_HEADSHIP_COACHING_OFFER
      [self, Course.find_by(identifier: NPQ_ADDITIONAL_SUPPORT_OFFER)]
    else
      [self]
    end
  end

  def npqs?
    identifier == NPQ_SENCO
  end
end
