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
        elsif course.npqh?
          :headteacher_duration
        elsif course.aso?
          :about_aso
        elsif previously_eligible_for_funding? && now_no_longer_eligible_for_funding?
          :funding_your_npq
        else
          :check_answers
        end
      elsif course.npqh?
        :headteacher_duration
      elsif course.aso?
        :about_aso
      elsif Services::FundingEligibility.new(course: course, institution: institution, headteacher_status: headteacher_status).call
        :possible_funding
      else
        :funding_your_npq
      end
    end

    def previous_step
      :choose_school
    end

    def options
      Course.all.each_with_index.map do |course, index|
        OpenStruct.new(value: course.id,
                       text: course.name,
                       link_errors: index.zero?,
                       hint: course.description)
      end
    end

    def course
      Course.find_by(id: course_id)
    end

  private

    def previously_eligible_for_funding?
      wizard.form_for_step(:choose_school).eligible_for_funding?
    end

    def now_no_longer_eligible_for_funding?
      !Services::FundingEligibility.new(course: course, institution: institution, headteacher_status: headteacher_status).call
    end

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
