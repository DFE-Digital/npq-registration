# frozen_string_literal: true

module Participants
  class Action
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider
    attribute :participant
    attribute :course_identifier

    validates :lead_provider, presence: true
    validates :participant, presence: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS }, allow_blank: false
    validate :application_exists

  private

    def application
      @application ||= participant
        &.applications
        &.accepted
        &.includes(:course)
        &.find_by(lead_provider:, course: { identifier: course_identifier })
    end

    def create_application_state!(kwargs = {})
      ApplicationState.create!({ application:, lead_provider: }.merge(kwargs))
    end

    def application_exists
      errors.add(:participant, :blank) if application.blank?
    end
  end
end
