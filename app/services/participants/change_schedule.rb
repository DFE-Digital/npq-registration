module Participants
  class ChangeSchedule < Action
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :schedule_identifier
    attribute :cohort, :integer

    validate :validate_new_schedule
    # validates :cohort, npq_contract_for_cohort_and_course: true # TODO we don't have NPQ Contract yet
    validate :validate_already_withdrawn
    validate :validate_new_schedule_valid_with_existing_declarations
    validate :validate_change_with_a_different_schedule
    validate :validate_permitted_schedule_for_course
    validate :validate_cannot_change_cohort
    validate :validate_application_funded_place

    def change_schedule
      return false if invalid?

      ActiveRecord::Base.transaction do
        update_funded_place!
        update_application!
      end

      true
    end

  private

    def new_cohort
      @new_cohort ||= cohort ? Cohort.find_by(start_year: cohort) : fallback_cohort
    end

    def new_schedule
      @new_schedule ||= Schedule.find_by(identifier: schedule_identifier, cohort: new_cohort)
    end

    def fallback_cohort
      application&.schedule&.cohort || Cohort.current
    end

    def update_application!
      application.update!(schedule: new_schedule, cohort: new_cohort)
    end

    def update_funded_place!
      return if application&.cohort&.funding_cap? && new_cohort.funding_cap?
      return unless new_cohort.funding_cap?

      application.update!(funded_place: application.eligible_for_funding)
    end

    def validate_new_schedule
      return if schedule_identifier.present? && new_schedule

      errors.add(:schedule_identifier, I18n.t(:invalid_schedule))
    end

    def validate_already_withdrawn
      if application&.withdrawn?
        errors.add(:participant, I18n.t(:withdrawn_participant))
      end
    end

    def validate_new_schedule_valid_with_existing_declarations
      return unless application
      return unless new_schedule

      applicable_declarations.each do |declaration|
        unless new_schedule.allowed_declaration_types.include?(declaration.declaration_type)
          errors.add(:schedule_identifier, I18n.t(:schedule_invalidates_declaration))
        end

        if declaration.declaration_date <= new_schedule.applies_from.beginning_of_day
          errors.add(:schedule_identifier, I18n.t(:schedule_invalidates_declaration))
        end
      end
    end

    def applicable_declarations
      @applicable_declarations ||= application.declarations.where(state: %w[submitted eligible payable paid])
    end

    def validate_permitted_schedule_for_course
      return unless new_schedule

      unless new_schedule.course_group.courses.exists?(identifier: course_identifier)
        errors.add(:schedule_identifier, I18n.t(:schedule_invalid_for_course))
      end
    end

    def validate_cannot_change_cohort
      return unless application
      return unless new_schedule

      if applicable_declarations.any? && new_schedule.cohort.start_year != application.schedule.cohort.start_year
        errors.add(:cohort, I18n.t("cannot_change_cohort"))
      end
    end

    def validate_change_with_a_different_schedule
      return unless application
      return unless new_schedule

      if new_schedule == application.schedule
        errors.add(:schedule_identifier, I18n.t(:schedule_already_on_the_profile))
      end
    end

    def validate_application_funded_place
      return unless application
      return unless application.cohort != new_cohort

      if application.cohort&.funding_cap? && !new_cohort.funding_cap?
        errors.add(:cohort, I18n.t(:cannot_change_cohort))
      end
    end
  end
end
