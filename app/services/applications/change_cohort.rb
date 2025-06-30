# frozen_string_literal: true

module Applications
  class ChangeCohort
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :application
    attribute :cohort_id, :integer

    validates :application, presence: true
    validates :cohort_id, presence: true
    validate :different_cohort, if: :application
    validate :declarations_present, if: :application
    validate :schedule_exists_in_new_cohort, if: :application

    def change_cohort
      return false if invalid?

      if application.schedule
        application.update!(cohort: cohort, schedule: new_schedule)
      else
        application.update!(cohort: cohort)
      end
    end

    def cohort_options
      if application.schedule
        Cohort.joins(:schedules)
          .where(schedules: { course_group: application.course.course_group })
          .where.not(id: application.cohort.id)
          .distinct
          .order(:start_year)
      else
        Cohort.where.not(id: application.cohort.id).order(:start_year)
      end
    end

  private

    def cohort
      @cohort ||= Cohort.find(cohort_id)
    end

    def different_cohort
      errors.add(:cohort_id, :must_be_different) if cohort_id == application.cohort.id
    end

    def declarations_present
      errors.add(:cohort_id, :declarations_present) if application.declarations.any?
    end

    def new_schedule
      Schedule.find_by(course_group: application.course.course_group, cohort_id:, identifier: application.schedule.identifier)
    end

    def schedule_exists_in_new_cohort
      return unless application.schedule

      errors.add(:cohort_id, :schedule_not_found) unless new_schedule
    end
  end
end
