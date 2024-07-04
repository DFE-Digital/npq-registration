# frozen_string_literal: true

module ParticipantOutcomes
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    STATES = %w[passed failed].freeze
    UNSUPPORTED_COURSES = %w[npq-early-headship-coaching-offer npq-additional-support-offer].freeze
    PERMITTED_COURSES = Course::IDENTIFIERS.excluding(UNSUPPORTED_COURSES).freeze
    COMPLETION_DATE_FORMAT = /\d{4}-\d{2}-\d{2}/

    attr_reader :created_outcome

    attribute :lead_provider
    attribute :participant
    attribute :course_identifier
    attribute :state
    attribute :completion_date

    validates :lead_provider, presence: true
    validates :participant, presence: true
    validates :course_identifier, inclusion: { in: PERMITTED_COURSES }, presence: true
    validates :state, inclusion: { in: STATES }, presence: true
    validates :completion_date, presence: true, format: { with: COMPLETION_DATE_FORMAT }
    validate :participant_has_no_completed_declarations
    validate :completion_date_is_a_valid_date
    validate :completion_date_not_in_the_future

    def create_outcome
      return false unless valid?

      ApplicationRecord.transaction do
        @created_outcome = if outcome_already_exists?
                             latest_existing_outcome
                           else
                             build_outcome.tap(&:save!)
                           end
      end

      true
    end

  private

    def outcome_already_exists?
      return unless latest_existing_outcome

      latest_existing_outcome.slice(:state, :completion_date) == build_outcome.slice(:state, :completion_date)
    end

    def build_outcome
      @build_outcome ||= ParticipantOutcome.new(declaration: latest_completed_declaration, state:, completion_date:)
    end

    def completed_declarations
      return Declaration.none unless participant

      @completed_declarations ||= participant.declarations.eligible_for_outcomes(lead_provider, course_identifier)
    end

    def latest_completed_declaration
      @latest_completed_declaration ||= completed_declarations.first
    end

    def latest_existing_outcome
      @latest_existing_outcome ||= participant&.latest_participant_outcome(lead_provider, course_identifier)
    end

    def participant_has_no_completed_declarations
      errors.add(:base, :no_completed_declarations) unless completed_declarations.exists?
    end

    def completion_date_not_in_the_future
      return if errors.key?(:completion_date)

      errors.add(:completion_date, :future_date) if completion_date&.to_date&.future?
    end

    def completion_date_is_a_valid_date
      return unless completion_date

      Date.parse(completion_date)
    rescue ArgumentError
      errors.add(:completion_date, :format)
    end
  end
end
