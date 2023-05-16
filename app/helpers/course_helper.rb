module CourseHelper
  def localise_course_name(course)
    I18n.t(course.identifier, scope: "course.name")
  end
end
