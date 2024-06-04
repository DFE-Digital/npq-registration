module Migration::Migrators
  class Course < Base
    def call
      migrate(ecf_npq_courses, :course) do |ecf_npq_course|
        course = ::Course.find_or_initialize_by(ecf_id: ecf_npq_course.id)
        course.update!(
          name: ecf_npq_course.name,
          identifier: ecf_npq_course.identifier,
        )
      end
    end

  private

    def ecf_npq_courses
      @ecf_npq_courses ||= Migration::Ecf::NpqCourse.all
    end
  end
end
