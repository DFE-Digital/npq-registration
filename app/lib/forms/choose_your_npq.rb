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
        elsif previously_eligible_for_funding? && !eligible_for_funding?
          :funding_your_npq
        else
          :check_answers
        end
      elsif course.ehco?
        :about_ehco
      elsif wizard.query_store.works_in_school? && eligible_for_funding?
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
        Course.where(display: true).order(:position)
      else
        Course.where(display: true).order(:position) - Course.ehco
      end
    end

    def previous_course
      Course.find_by(id: wizard.store["course_id"])
    end

    def previously_eligible_for_funding?
      Services::FundingEligibility.new(
        course: previous_course,
        institution: institution,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
      ).funded?
    end

    def eligible_for_funding?
      Services::FundingEligibility.new(
        course: course,
        institution: institution,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
      ).funded?
    end

    delegate :new_headteacher?, :inside_catchment?, to: :query_store

    def validate_course_exists
      if course.blank?
        errors.add(:course_id, :invalid)
      end
    end
  end
end
