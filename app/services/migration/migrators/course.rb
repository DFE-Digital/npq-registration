module Migration::Migrators
  class Course < Base
    COURSE_GROUPS = {
      "npq-ehco-june" => "ehco",
      "npq-specialist-autumn" => "specialist",
      "npq-leadership-autumn" => "leadership",
      "npq-ehco-march" => "ehco",
      "npq-leadership-spring" => "leadership",
      "npq-ehco-december" => "ehco",
      "npq-specialist-spring" => "specialist",
      "npq-ehco-november" => "ehco",
      "npq-aso-november" => "support",
      "npq-aso-december" => "support",
      "npq-aso-march" => "support",
      "npq-aso-june" => "support",
    }.freeze

    def call
      migrate(ecf_npq_courses, :course) do |ecf_npq_course|
        course_group = ::CourseGroup.find_or_initialize_by(name: COURSE_GROUPS[ecf_npq_course.identifier])

        course = ::Course.find_or_initialize_by(ecf_id: ecf_npq_course.id)
        course.update!(
          name: ecf_npq_course.name,
          identifier: ecf_npq_course.identifier,
          course_group:,
        )
      end
    end

  private

    def ecf_npq_courses
      @ecf_npq_courses ||= Migration::Ecf::NpqCourse.all
    end
  end
end
