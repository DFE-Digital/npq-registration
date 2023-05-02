module CourseHelper
  def localise_course_name(course)
    I18n.t(course.identifier, scope: "helpers.label.registration_wizard.course_identifier_options")
  end
end
