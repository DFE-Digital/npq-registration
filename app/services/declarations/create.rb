# frozen_string_literal: true

module Declarations
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :lead_provider
    attribute :participant_id
    attribute :declaration_type, :string
    attribute :declaration_date, :datetime
    attribute :course_identifier, :string
    attribute :has_passed
    attribute :delivery_partner_id
    attribute :secondary_delivery_partner_id

    validates :lead_provider, presence: true
    validates :participant_id, presence: true
    validates :participant, participant_presence: true, participant_not_withdrawn: true
    validates :course_identifier, course_for_participant: true
    validates :declaration_date, declaration_date: true
    validates :declaration_date, presence: true
    validates :declaration_type, presence: true
    validates :declaration_type, inclusion: { in: Declaration.declaration_types.values }

    validate :validate_schedule_exists, :validate_declaration_type_for_schedule # this needs to come before the cohort validation

    validates :cohort, contract_for_cohort_and_course: true

    validate :output_fee_statement_available
    validate :validate_has_passed_field, if: :validate_has_passed?
    validate :validates_billable_slot_available
    validate :declaration_valid

    attr_reader :raw_declaration_date, :declaration

    def create_declaration
      return false unless valid?

      ApplicationRecord.transaction do
        find_or_create_declaration!
        set_eligibility!

        statement_attacher.attach unless declaration.submitted_state?
        create_participant_outcome!
      end

      true
    end

    def declaration_date=(raw_declaration_date)
      self.raw_declaration_date = raw_declaration_date
      super
    end

    def application
      @application ||= participant
        &.applications
        &.accepted
        &.includes(:course)
        &.find_by(lead_provider:, course: Course.find_by(identifier: course_identifier)&.rebranded_alternative_courses)
    end

    def participant
      @participant ||= begin
        Participants::Query.new(lead_provider:).participant(ecf_id: participant_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

  private

    attr_writer :raw_declaration_date

    delegate :schedule, to: :application, allow_nil: true
    delegate :cohort, to: :schedule

    def declaration_parameters_for_find
      {
        declaration_date:,
        declaration_type:,
        lead_provider:,
      }
    end

    def declaration_parameters_for_create
      declaration_parameters_for_find.merge(
        application:,
        cohort:,
        delivery_partner: DeliveryPartner.find_by(ecf_id: delivery_partner_id),
        secondary_delivery_partner: DeliveryPartner.find_by(ecf_id: secondary_delivery_partner_id),
      )
    end

    def existing_declaration
      @existing_declaration ||= participant
        .declarations
        .joins(application: :course)
        .submitted_state
        .or(
          participant
            .declarations
            .joins(application: :course)
            .billable,
        )
        .find_by(declaration_parameters_for_find.merge(application: { courses: { identifier: course_identifier } }))
    end

    def find_or_create_declaration!
      @declaration = existing_declaration || Declaration.create!(declaration_parameters_for_create)
    end

    def statement_attacher
      @statement_attacher ||= StatementAttacher.new(declaration:)
    end

    def output_fee_statement_available
      return if errors.any?
      return if application.blank?
      return if existing_declaration&.submitted_state?
      return if existing_declaration.nil? && !application.fundable?
      return if lead_provider.next_output_fee_statement(cohort).present?

      errors.add(:cohort, :no_output_fee_statement, cohort: cohort.start_year)
    end

    def set_eligibility!
      if declaration.duplicate_declarations.any?
        declaration.update!(superseded_by: original_declaration)
        declaration.mark_ineligible!
      elsif application.fundable?
        declaration.mark_eligible!
      end
    end

    def validate_declaration_type_for_schedule
      return if errors.any?
      return if schedule&.allowed_declaration_types&.include?(declaration_type)

      errors.add(:declaration_type, :mismatch_declaration_type_for_schedule)
    end

    def validate_schedule_exists
      return if errors.any?
      return if schedule

      errors.add(:application, :application_schedule_missing)
    end

    def original_declaration
      @original_declaration ||= declaration.duplicate_declarations.order(created_at: :asc, id: :asc).first
    end

    def validates_billable_slot_available
      return if errors.any?
      return unless participant

      return unless Declaration
                      .billable_or_changeable
                      .joins(application: %i[user course])
                      .where(
                        application: { user: participant, courses: { identifier: course_identifier } },
                        declaration_type:,
                      ).exists?

      errors.add(:base, :declaration_already_exists)
    end

    def validate_has_passed_field
      self.has_passed = has_passed.to_s

      return unless has_passed.blank? || !%w[true false].include?(has_passed)

      errors.add(:has_passed, :invalid)
    end

    def validate_has_passed?
      return false unless valid_course_identifier_for_participant_outcome?

      declaration_type == "completed"
    end

    def valid_course_identifier_for_participant_outcome?
      CourseGroup.joins(:courses).leadership_or_specialist.where(courses: { identifier: course_identifier }).exists?
    end

    def create_participant_outcome!
      return unless validate_has_passed?

      service = ParticipantOutcomes::Create.new(
        lead_provider:,
        participant_id: participant.ecf_id,
        course_identifier:,
        state: has_passed.to_s == "true" ? "passed" : "failed",
        completion_date: declaration_date.rfc3339,
      )

      if service.valid?
        service.create_outcome
      else
        raise ArgumentError, I18n.t(:cannot_create_completed_declaration)
      end
    end

    def declaration_valid
      return if errors.any?

      declaration = Declaration.new(declaration_parameters_for_create)
      errors.merge!(declaration.errors) unless declaration.valid?
    end
  end
end
