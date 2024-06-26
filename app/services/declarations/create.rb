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
    validates :participant_id, presence: true
    validates :participant, participant_presence: true, participant_not_withdrawn: true
    validates :course_identifier, inclusion: { in: Course::IDENTIFIERS }, allow_blank: false, course_for_participant: true
    validates :declaration_date, declaration_date: true
    validates :declaration_date, presence: true
    validates :declaration_type, presence: true
    # TODO we don't have NPQ Contract yet
    validates :cohort, contract_for_cohort_and_course: true

    validate :output_fee_statement_available
    validate :validate_has_passed_field, if: :validate_has_passed?
    validate :validate_schedule_exists
    validate :validates_billable_slot_available

    attr_reader :raw_declaration_date, :declaration

    def create_declaration
      return false unless valid?

      ApplicationRecord.transaction do
        find_or_create_declaration!
        set_eligibility!

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

  private

    attr_writer :raw_declaration_date

    delegate :schedule, to: :application, allow_nil: true
    delegate :cohort, to: :schedule

    def declaration_parameters
      {
        declaration_date:,
        declaration_type:,
        lead_provider:,
      }
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

    def find_or_create_declaration!
      @declaration ||= existing_declaration || Declaration.create!(declaration_parameters.merge(application:, cohort:))
    end

    def statement_attacher
      @statement_attacher ||= StatementAttacher.new(declaration:)
    end

    def output_fee_statement_available
      return if errors.any?
      return if application.blank?
      return if existing_declaration&.submitted_state?
      return if existing_declaration.nil? && !application.fundable?
      return unless lead_provider.next_output_fee_statement(cohort).blank?

      errors.add(:cohort, :no_output_fee_statement, cohort: cohort.start_year)
    end

    def set_eligibility!
      if declaration.duplicate_declarations.any?
        declaration.update!(superseded_by: original_declaration)
        declaration.ineligible_state!
      elsif application.fundable?
        declaration.eligible_state!
      end
    end

    def validate_schedule_exists
      return if errors.any?
      return if schedule&.allowed_declaration_types&.include?(declaration_type)

      errors.add(:declaration_type, :mismatch_declaration_type_for_schedule)
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

      return unless has_passed.blank? || !%w[true false].include?(has_passed)

      errors.add(:has_passed, :invalid)
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
