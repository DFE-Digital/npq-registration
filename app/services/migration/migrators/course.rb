module Migration::Migrators
  class Course < Base
    class << self
      def model_count
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
      migrate(self.class.ecf_npq_courses) do |ecf_npq_course|
        course = ::Course.find_or_initialize_by(ecf_id: ecf_npq_course.id)
        course.update!(
          name: ecf_npq_course.name,
          identifier: ecf_npq_course.identifier,
        )
      end
    end
  end
end
