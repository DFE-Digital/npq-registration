# frozen_string_literal: true

module Participants
  class Withdraw
    include ActiveModel::Model
    include ActiveModel::Attributes

    WITHDRAWL_REASONS = %w[
      insufficient-capacity-to-undertake-programme
      personal-reason-health-or-pregnancy-related
      personal-reason-moving-school
      personal-reason-other
      insufficient-capacity
      change-in-developmental-or-personal-priorities
      change-in-school-circumstances
      change-in-school-leadership
      quality-of-programme-structure-not-suitable.
      quality-of-programme-content-not-suitable
      quality-of-programme-facilitation-not-effective
      quality-of-programme-accessibility
      quality-of-programme-other
      programme-not-appropriate-for-role-and-cpd-needs
      started-in-error
      expected-commitment-unclear
      other
    ].freeze

    attribute :lead_provider
    attribute :participant
    attribute :course_identifier
    attribute :reason

    validates :lead_provider, presence: true
    validates :participant, presence: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS }, allow_blank: false
    validates :reason, inclusion: { in: WITHDRAWL_REASONS }, allow_blank: false
    validate :application_exists
    validate :not_withdrawn
    validate :has_started_declarations

    def withdraw
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!
        application.withdrawn!
        participant.reload
      end

      true
    end

  private

    def create_application_state!
      ApplicationState.create!(application:, lead_provider:, reason:, state: :withdrawn)
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
      errors.add(:participant, :already_withdrawn) if application&.withdrawn?
    end

    def has_started_declarations
      errors.add(:participant, :no_started_declarations) unless application&.declarations&.any?(&:started_declaration_type?)
    end
  end
end
