module Forms
  class ChooseYourNpq < Base
    attr_accessor :course_id

    validates :course_id, presence: true

    def self.permitted_params
      %i[
        course_id
      ]
    end

    def next_step
      if studying_for_headship?
        :headteacher_duration
      else
        :choose_your_provider
      end
    end

    def previous_step
      :qualified_teacher_check
    end

    def studying_for_headship?
      course.studying_for_headship?
    end

    def options
      Course.all.each_with_index.map do |course, index|
        OpenStruct.new(value: course.id,
                       text: course.name,
                       link_errors: index.zero?)
      end
    end

    def course
      Course.find(course_id)
    end
  end
end
