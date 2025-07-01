# frozen_string_literal: true

module Participants
  class Action
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider
    attribute :participant_id
    attribute :course_identifier

    validates :lead_provider, presence: true
    validates :participant_id, presence: true, participant_id_change: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS }, allow_blank: false
    validate :participant_exists
    validate :application_exists

    def participant
      @participant ||= Query.new(lead_provider:).participant(ecf_id: participant_id)
    rescue ActiveRecord::RecordNotFound, ArgumentError
      nil
    end

    def self.new_filtering_attributes(attributes = {})
      filtered_attributes = attributes.slice(*attribute_names)
      new(filtered_attributes)
    end

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
      return if errors.any?

      errors.add(:participant_id, :application_not_found) if application.blank?
    end

    def participant_exists
      errors.add(:participant_id, :invalid_participant) if participant.blank?
    end
  end
end
