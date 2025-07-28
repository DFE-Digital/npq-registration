module Participants
  class ChangeSchedule < Action
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :schedule_identifier
    attribute :cohort, :integer

    validates :schedule_identifier, presence: true
    validate :validate_new_schedule_found
    validates :cohort, contract_for_cohort_and_course: true
    validate :validate_not_withdrawn
    validate :validate_new_schedule_valid_with_existing_declarations
    validate :validate_changing_to_different_schedule
    validate :validate_permitted_schedule_for_course
    validate :validate_not_changing_cohort_with_declarations
    validate :validate_application_funded_place

    def change_schedule
      return false if invalid?

      ActiveRecord::Base.transaction do
        update_application!
        participant.reload
      end

      true
    end

    def cohort
      @cohort ||= super ? Cohort.find_by(name: super) : fallback_cohort
    end

  private

    def new_schedule
      @new_schedule ||= Schedule.find_by(identifier: schedule_identifier, cohort:)
    end

    def fallback_cohort
      application&.schedule&.cohort || Cohort.current
    end

    def update_application!
      params = { schedule: new_schedule }

      if application.cohort != cohort
        params[:cohort] = cohort
      end

      if !application.cohort.funding_cap? && cohort.funding_cap?
        params[:funded_place] = application.eligible_for_funding
      end

      application.update!(params)
    end

    def validate_new_schedule_found
      return if schedule_identifier.present? && new_schedule

      errors.add(:schedule_identifier, :blank)
    end

    def validate_not_withdrawn
      if application&.withdrawn_training_status?
        errors.add(:participant_id, :already_withdrawn)
      end
    end

    def validate_new_schedule_valid_with_existing_declarations
      return unless application
      return unless new_schedule

      applicable_declarations.each do |declaration|
        unless new_schedule.allowed_declaration_types.include?(declaration.declaration_type)
          errors.add(:schedule_identifier, :invalidates_declaration)
        end

        if declaration.declaration_date <= new_schedule.applies_from.beginning_of_day
          errors.add(:schedule_identifier, :invalidates_declaration)
        end
      end
    end

    def applicable_declarations
      @applicable_declarations ||= application.declarations.billable_or_changeable
    end

    def validate_permitted_schedule_for_course
      return if errors.any?
      return unless new_schedule

      unless new_schedule.course_group.courses.exists?(identifier: course_identifier)
        errors.add(:schedule_identifier, :invalid_for_course)
      end
    end

    def validate_not_changing_cohort_with_declarations
      return if errors.any?
      return unless application
      return unless new_schedule

      if applicable_declarations.any? && new_schedule.cohort.id != application.schedule.cohort.id
        errors.add(:cohort, :cannot_change_with_declarations)
      end
    end

    def validate_changing_to_different_schedule
      return unless application
      return unless new_schedule

      if new_schedule == application.schedule
        errors.add(:schedule_identifier, :schedule_has_not_changed)
      end
    end

    def validate_application_funded_place
      return unless application
      return unless application.cohort != cohort

      if application.cohort&.funding_cap? && !cohort.funding_cap?
        errors.add(:cohort, :cannot_change_to_cohort_without_funding_cap)
      end
    end
  end
end
