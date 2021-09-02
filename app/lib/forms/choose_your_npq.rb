module Forms
  class ChooseYourNpq < Base
    include Helpers::Institution

    attr_accessor :course_id

    validates :course_id, presence: true
    validate :validate_course_exists

    def self.permitted_params
      %i[
        course_id
      ]
    end

    def next_step
      if changing_answer?
        if no_answers_will_change?
          :check_answers
        elsif studying_for_headship?
          :headteacher_duration
        elsif wizard.form_for_step(:choose_school).eligible_for_funding? &&
            !Services::FundingEligibility.new(course: course, institution: institution, headteacher_status: headteacher_status).call
          :funding_your_npq
        else
          :check_answers
        end
      elsif studying_for_headship?
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
      Course.find_by(id: course_id)
    end

  private

    def headteacher_status
      wizard.store["headteacher_status"]
    end

    def validate_course_exists
      if course.blank?
        errors.add(:course_id, :invalid)
      end
    end
  end
end
