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

    validates :lead_provider, presence: true
    validates :participant_id, presence: { message: I18n.t("declaration.missing_participant_id") }
    validates :participant, participant_presence: true, participant_not_withdrawn: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS, message: I18n.t(:invalid_course) }, allow_blank: false, course_for_participant: true
    validates :declaration_date, declaration_date: true, allow_blank: true
    validates :declaration_date, presence: { message: I18n.t("declaration.missing_declaration_date") }
    validates :declaration_type, presence: { message: I18n.t("declaration.missing_declaration_type") }
    validates :cohort, contract_for_cohort_and_course: { message: I18n.t("declaration.missing_npq_contract_for_cohort_and_course") }

    validate :output_fee_statement_available
    validate :validate_has_passed_field, if: :validate_has_passed?
    validate :validate_schedule_exists
    validate :validates_billable_slot_available

    attr_reader :raw_declaration_date

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        set_eligibility

        statement_attacher.attach unless declaration.submitted_state?
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
        &.find_by(lead_provider:, course: { identifier: course_identifier })
    end

    def participant
      @participant ||= begin
        Participants::Query.new(lead_provider:).participant(ecf_id: participant_id)
      rescue StandardError
        nil
      end
    end

    def declaration
      @declaration ||= existing_declaration || Declaration.create!(declaration_parameters.merge(application:, cohort:))
    end

  private

    attr_writer :raw_declaration_date

    delegate :schedule, to: :application, allow_nil: true
    delegate :cohort, to: :schedule

    def statement_attacher
      @statement_attacher ||= StatementAttacher.new(declaration:)
    end

    def output_fee_statement_available
      return if errors.any?
      return if application.blank?
      return if existing_declaration&.submitted_state?
      return if existing_declaration.nil? && !application.fundable?

      errors.add(:cohort, I18n.t("statement.no_output_fee_statement", cohort: cohort.start_year)) if lead_provider.next_output_fee_statement(cohort).blank?
    end

    def set_eligibility
      if declaration.duplicate_declarations.any?
        declaration.update!(superseded_by: original_participant_declaration)
        declaration.ineligible_state!
      elsif application.fundable?
        declaration.eligible_state!
      end
    end

    def validate_schedule_exists
      return if errors.any?

      errors.add(:declaration_type, I18n.t("declaration.mismatch_declaration_type_for_schedule")) unless schedule&.allowed_declaration_types&.include?(declaration_type)
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
        .find_by(declaration_parameters.merge(application: { courses: { identifier: course_identifier } }))
    end

    def declaration_parameters
      {
        declaration_date:,
        declaration_type:,
        lead_provider:,
      }
    end

    def original_declaration
      @original_declaration ||= declaration.duplicate_declarations.order(created_at: :asc).first
    end

    def validates_billable_slot_available
      return if errors.any?
      return unless participant

      return unless Declaration
                      .joins(application: %i[user course])
                      .where(
                        application: { user: participant, courses: { identifier: course_identifier } },
                        declaration_type:,
                        state: %w[submitted eligible payable paid],
                      ).exists?

      errors.add(:base, I18n.t("declaration.declaration_already_exists"))
    end

    def validate_has_passed_field
      self.has_passed = has_passed.to_s

      if has_passed.blank?
        errors.add(:has_passed, I18n.t("declaration.missing_has_passed"))
      elsif !%w[true false].include?(has_passed)
        errors.add(:has_passed, I18n.t("declaration.invalid_has_passed"))
      end
    end

    def validate_has_passed?
      return false unless valid_course_identifier_for_participant_outcome?

      declaration_type == "completed"
    end

    def valid_course_identifier_for_participant_outcome?
      CourseGroup.joins(:courses).where(name: %w[leadership specialist]).map(&:courses).flatten.uniq.map(&:identifier).include?(course_identifier)
    end
  end
end
