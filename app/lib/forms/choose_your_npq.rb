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
        elsif course.aso?
          :about_aso
        elsif previously_eligible_for_funding? && now_no_longer_eligible_for_funding?
          :funding_your_npq
        else
          :check_answers
        end
      elsif course.aso?
        :about_aso
      elsif !wizard.query_store.inside_catchment?
        :funding_your_npq
      elsif Services::FundingEligibility.new(course: course, institution: institution, new_headteacher: new_headteacher?).call
        :possible_funding
      else
        :funding_your_npq
      end
    end

    def previous_step
      if query_store.inside_catchment? && query_store.works_in_school?
        :choose_school
      else
        :qualified_teacher_check
      end
    end

    def options
      courses.each_with_index.map do |course, index|
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

    def courses
      if wizard.query_store.inside_catchment? && wizard.query_store.works_in_school?
        Course.all
      else
        Course.all - Course.where(name: "Additional Support Offer for new headteachers")
      end
    end

    def previous_course
      Course.find_by(id: wizard.store["course_id"])
    end

    def previously_eligible_for_funding?
      Services::FundingEligibility.new(
        course: previous_course,
        institution: institution,
        new_headteacher: new_headteacher?,
      ).call
    end

    def now_no_longer_eligible_for_funding?
      !Services::FundingEligibility.new(
        course: course,
        institution: institution,
        new_headteacher: new_headteacher?,
      ).call
    end

    def new_headteacher?
      wizard.store["aso_headteacher"] == "yes" && wizard.store["aso_new_headteacher"] == "yes"
    end

    def validate_course_exists
      if course.blank?
        errors.add(:course_id, :invalid)
      end
    end
  end
end
