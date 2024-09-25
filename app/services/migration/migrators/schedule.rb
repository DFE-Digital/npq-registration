module Migration::Migrators
  class Schedule < Base
    class << self
      def record_count
        ecf_schedules.count
      end

      def model
        :schedule
      end

      def ecf_schedules
        Migration::Ecf::Finance::Schedule.includes(:milestones)
      end

      def dependencies
        %i[cohort course]
      end
    end

    def call
      migrate(self.class.ecf_schedules) do |ecf_schedule|
        ensure_milestone_dates_are_all_the_same!(ecf_schedule)

        course_group = course_groups_by_schedule_type(ecf_schedule.type)

        unless course_group
          ecf_schedule.errors.add(:base, "Course group not found for schedule")
          raise ActiveRecord::RecordInvalid, ecf_schedule
        end

        ::Schedule.find_or_initialize_by(ecf_id: ecf_schedule.id).tap do |schedule|
          ecf_milestone = ecf_schedule.milestones.first
          schedule.update!(
            cohort_id: self.class.find_cohort_id!(ecf_id: ecf_schedule.cohort_id),
            course_group:,
            identifier: ecf_schedule.schedule_identifier,
            applies_from: ecf_milestone.start_date,
            applies_to: ecf_milestone.payment_date,
            name: ecf_schedule.name,
            allowed_declaration_types: ecf_schedule.milestones.pluck(:declaration_type),
          )
        end
      end
    end

  private

    def ensure_milestone_dates_are_all_the_same!(ecf_schedule)
      dates = ecf_schedule.milestones.map { |m| [m.start_date, m.payment_date] }
      return if dates.uniq.size == 1

      ecf_schedule.errors.add(:base, "Milestones contain different dates")
      raise ActiveRecord::RecordInvalid, ecf_schedule
    end
  end
end
