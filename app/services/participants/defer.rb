# frozen_string_literal: true

module Participants
  class Defer
    include ActiveModel::Model
    include ActiveModel::Attributes

    DEFERRAL_REASONS = %w[
      bereavement
      long-term-sickness
      parental-leave
      career-break
      other
    ].freeze

    attribute :lead_provider
    attribute :participant
    attribute :course_identifier
    attribute :reason

    validates :lead_provider, presence: true
    validates :participant, presence: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS }, allow_blank: false
    validates :reason, inclusion: { in: DEFERRAL_REASONS }, allow_blank: false
    validate :application_exists
    validate :not_already_deferred
    validate :not_withdrawn
    validate :has_declarations

    def defer
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!
        application.deferred!
        participant.reload
      end

      true
    end

  private

    def create_application_state!
      ApplicationState.create!(application:, lead_provider:, reason:, state: :deferred)
    end

    def application
      @application ||= participant
        &.applications
        &.accepted
        &.includes(:course)
        &.find_by(lead_provider:, course: { identifier: course_identifier })
    end

    def application_exists
      errors.add(:participant, :blank) if application.blank?
    end

    def not_withdrawn
      errors.add(:participant, :withdrawn) if application&.withdrawn?
    end

    def not_already_deferred
      errors.add(:participant, :already_deferred) if application&.deferred?
    end

    def has_declarations
      errors.add(:participant, :no_declarations) if application&.declarations&.none?
    end
  end
end
