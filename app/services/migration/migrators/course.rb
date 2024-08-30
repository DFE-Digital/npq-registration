module Migration::Migrators
  class Course < Base
    COURSE_GROUP_NAMES = %w[
      leadership
      specialist
      support
      ehco
    ].freeze

    class << self
      def record_count
        ecf_npq_courses.count
      end

      def model
        :course
      end

      def ecf_npq_courses
        Migration::Ecf::NpqCourse
      end
    end

    def call
      COURSE_GROUP_NAMES.each { |name| ::CourseGroup.find_or_create_by!(name:) }

      migrate(self.class.ecf_npq_courses) do |ecf_npq_course|
        course = ::Course.find_or_initialize_by(ecf_id: ecf_npq_course.id)
        course_group = find_course_group!(course, ecf_npq_course.identifier)

        course.update!(
          name: ecf_npq_course.name,
          identifier: ecf_npq_course.identifier,
          course_group:,
        )
      end
    end

  private

    def find_course_group!(course, identifier)
      course_definition = ::Courses::DEFINITIONS.find { |d| d[:identifier] == identifier }

      if course_definition.nil?
        course.errors.add(:base, "A course group could not be found for the course #{identifier}")
        raise ActiveRecord::RecordInvalid, course
      end

      ::CourseGroup.find_by(name: course_definition[:course_group_name])
    end
  end
end
