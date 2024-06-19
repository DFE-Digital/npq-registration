# frozen_string_literal: true

module Participants
  class Resume
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider
    attribute :participant
    attribute :course_identifier

    validates :lead_provider, presence: true
    validates :participant, presence: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS }, allow_blank: false
    validate :application_exists
    validate :not_already_active

    def resume
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!
        application.active!
        participant.reload
      end

      true
    end

  private

    def create_application_state!
      ApplicationState.create!(application:, lead_provider:)
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

    def not_already_active
      errors.add(:participant, :already_active) if application&.active?
    end
  end
end
