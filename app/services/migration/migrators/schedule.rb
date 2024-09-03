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
        Migration::Ecf::Finance::Schedule.includes(:cohort, :milestones)
      end

      def dependencies
        %i[cohort course]
      end
    end

    def call
      migrate(self.class.ecf_schedules) do |ecf_schedule|
        ensure_milestone_dates_are_all_the_same!(ecf_schedule)

        course_group = course_groups_by_identifier(ecf_schedule.type)

        unless course_group
          ecf_schedule.errors.add(:base, "Course group not found for schedule")
          raise ActiveRecord::RecordInvalid, ecf_schedule
        end

        ::Schedule.find_or_initialize_by(
          cohort_id: cohorts_by_start_year[ecf_schedule.cohort.start_year].id,
          identifier: ecf_schedule.schedule_identifier,
          course_group:,
        ).tap do |schedule|
          ecf_milestone = ecf_schedule.milestones.first
          schedule.update!(
            applies_from: ecf_milestone.start_date,
            applies_to: ecf_milestone.payment_date,
            name: ecf_schedule.name,
            allowed_declaration_types: ecf_schedule.milestones.pluck(:declaration_type),
          )
        end
      end
    end

  private

    def course_groups_by_identifier(ecf_type)
      case ecf_type
      when "Finance::Schedule::NPQLeadership"
        CourseGroup.find_by!(name: :leadership)
      when "Finance::Schedule::NPQSpecialist"
        CourseGroup.find_by!(name: :specialist)
      when "Finance::Schedule::NPQSupport"
        CourseGroup.find_by!(name: :support)
      when "Finance::Schedule::NPQEhco"
        CourseGroup.find_by!(name: :ehco)
      end
    end

    def ensure_milestone_dates_are_all_the_same!(ecf_schedule)
      dates = ecf_schedule.milestones.map { |m| [m.start_date, m.payment_date] }
      return if dates.uniq.size == 1

      ecf_schedule.errors.add(:base, "Milestones contain different dates")
      raise ActiveRecord::RecordInvalid, ecf_schedule
    end

    def cohorts_by_start_year
      @cohorts_by_start_year ||= ::Cohort.all.index_by(&:start_year)
    end
  end
end
